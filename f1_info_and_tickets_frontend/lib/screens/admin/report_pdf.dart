import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/formatters.dart';
import '../../models/analytics.dart';

/// Data shown on the reports screen and printed in the PDF.
class ReportData {
  final List<RaceSales> sales;
  final List<TicketTypeSales> typeSales;
  final List<RaceAttendance> attendance;
  final UserActivity activity;

  ReportData({required this.sales, required this.typeSales, required this.attendance, required this.activity});
}

/// Builds the printable report (ticket sales, attendance, user activity) for the selected filters.
class ReportPdf {
  static const _red = PdfColor.fromInt(0xFFE10600);
  static const _dark = PdfColor.fromInt(0xFF2B2B38);

  static Future<Uint8List> build(ReportData data, {required String filterLabel}) async {
    // Roboto supports the Bosnian letters (č, ć, đ, š, ž) and the euro sign.
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    final doc = pw.Document(
      title: 'F1 Info & Tickets report',
      author: 'F1 Info & Tickets',
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );

    final totalSold = data.sales.fold<int>(0, (sum, s) => sum + s.ticketsSold);
    final totalRevenue = data.sales.fold<double>(0, (sum, s) => sum + s.totalRevenue);
    final activity = data.activity;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _red, width: 2)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.RichText(
                text: pw.TextSpan(
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                  children: [
                    const pw.TextSpan(text: 'F1 Info & '),
                    const pw.TextSpan(
                      text: 'Tickets',
                      style: pw.TextStyle(color: _red),
                    ),
                  ],
                ),
              ),
              pw.Text('Sales and attendance report', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generated: ${formatDateTime(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.Text('Page ${context.pageNumber} / ${context.pagesCount}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ],
        ),
        build: (context) => [
          pw.SizedBox(height: 12),
          pw.Text('Filter: $filterLabel', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800)),
          pw.SizedBox(height: 12),
          _summary([
            ('Sold tickets', formatNumber(totalSold)),
            ('Revenue', formatMoney(totalRevenue)),
            ('Active buyers', formatNumber(activity.activeBuyers)),
            ('Race views', formatNumber(activity.raceViews)),
          ]),
          _heading('Ticket sales per race'),
          _table(
            ['Race', 'Date', 'Sold tickets', 'Revenue'],
            [
              for (final s in data.sales) [s.raceName, formatDate(s.raceDate), formatNumber(s.ticketsSold), formatMoney(s.totalRevenue)],
            ],
            numericFrom: 2,
          ),
          _heading('Sales by ticket type'),
          _table(
            ['Ticket type', 'Sold tickets', 'Revenue'],
            [
              for (final t in data.typeSales) [t.ticketType, formatNumber(t.ticketsSold), formatMoney(t.totalRevenue)],
            ],
            numericFrom: 1,
          ),
          _heading('Race attendance'),
          _table(
            ['Race', 'Date', 'Capacity', 'Sold', 'Occupancy'],
            [
              for (final a in data.attendance)
                [
                  a.raceName,
                  formatDate(a.raceDate),
                  formatNumber(a.capacity),
                  formatNumber(a.ticketsSold),
                  '${a.occupancyPercent.toStringAsFixed(1)} %',
                ],
            ],
            numericFrom: 2,
          ),
          _heading('User activity'),
          _summary([
            ('Registered users', formatNumber(activity.totalUsersRegistered)),
            ('Active buyers', formatNumber(activity.activeBuyers)),
            ('Tickets purchased', formatNumber(activity.totalTicketsPurchased)),
            ('Revenue', formatMoney(activity.totalRevenue)),
          ]),
          pw.SizedBox(height: 10),
          _table(
            ['Customer', 'Username', 'Tickets', 'Spent', 'Last purchase', 'Views'],
            [
              for (final c in activity.topCustomers)
                [
                  c.fullName,
                  c.username,
                  formatNumber(c.ticketsPurchased),
                  formatMoney(c.totalSpent),
                  formatDate(c.lastPurchase),
                  formatNumber(c.raceViews),
                ],
            ],
            numericFrom: 2,
          ),
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _dark),
    ),
  );

  static pw.Widget _summary(List<(String, String)> items) => pw.Row(
    children: [
      for (final (label, value) in items)
        pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.only(right: 8),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ],
            ),
          ),
        ),
    ],
  );

  static pw.Widget _table(List<String> headers, List<List<String>> rows, {required int numericFrom}) {
    if (rows.isEmpty) return pw.Text('No data for the selected filter.', style: const pw.TextStyle(color: PdfColors.grey700));
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: _dark),
      cellStyle: const pw.TextStyle(fontSize: 9),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellAlignments: {for (var i = numericFrom; i < headers.length; i++) i: pw.Alignment.centerRight},
    );
  }
}
