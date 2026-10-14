import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../api/providers.dart';
import '../../core/formatters.dart';
import '../../models/analytics.dart';
import '../../models/reference.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_page.dart';
import '../../widgets/admin/async_dropdown.dart';
import '../../widgets/feedback.dart';
import '../../widgets/state_views.dart';
import 'report_pdf.dart';

/// Ticket sales, race attendance and user activity, filtered by season and purchase period.
/// The same data can be downloaded as a PDF or printed.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _analytics = AnalyticsProvider();
  Season? _season;
  DateTimeRange? _period;
  late Future<ReportData> _future = _load();
  bool _exporting = false;

  Future<ReportData> _load() async {
    final seasonId = _season?.seasonID;
    final from = _period?.start;
    // The end date is inclusive.
    final to = _period?.end.add(const Duration(days: 1));
    final results = await Future.wait([
      _analytics.ticketSales(seasonId: seasonId, from: from, to: to),
      _analytics.ticketTypeSales(seasonId: seasonId, from: from, to: to),
      _analytics.attendance(seasonId: seasonId, from: from, to: to),
      _analytics.userActivity(seasonId: seasonId, from: from, to: to),
    ]);
    return ReportData(
      sales: results[0] as List<RaceSales>,
      typeSales: results[1] as List<TicketTypeSales>,
      attendance: results[2] as List<RaceAttendance>,
      activity: results[3] as UserActivity,
    );
  }

  void _reload() => setState(() {
    _future = _load();
  });

  String get _filterLabel {
    final season = _season == null ? 'all seasons' : 'season ${_season!.year}';
    final period = _period == null ? 'whole period' : 'purchases ${formatDate(_period!.start)} – ${formatDate(_period!.end)}';
    return '$season, $period';
  }

  Future<void> _pickPeriod() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _period,
      helpText: 'Purchase period',
    );
    if (picked == null) return;
    _period = picked;
    _reload();
  }

  Future<void> _export({required bool print}) async {
    setState(() => _exporting = true);
    try {
      final data = await _future;
      final bytes = await ReportPdf.build(data, filterLabel: _filterLabel);
      if (!mounted) return;
      if (print) {
        final printed = await Printing.layoutPdf(name: 'F1 report', onLayout: (_) async => bytes);
        if (printed && mounted) showSuccess(context, 'The report was sent to the printer.');
        return;
      }
      final now = DateTime.now();
      final stamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final location = await getSaveLocation(
        suggestedName: 'f1-report-$stamp.pdf',
        acceptedTypeGroups: const [
          XTypeGroup(label: 'PDF', extensions: ['pdf']),
        ],
      );
      if (location == null) return;
      final path = location.path.toLowerCase().endsWith('.pdf') ? location.path : '${location.path}.pdf';
      await File(path).writeAsBytes(bytes);
      if (mounted) showSuccess(context, 'The report was saved: $path');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: AdminPage(
        title: 'Reports',
        subtitle: 'Ticket sales, race attendance and user activity',
        actions: [
          OutlinedButton.icon(
            onPressed: _exporting ? null : () => _export(print: false),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download PDF'),
          ),
          ElevatedButton.icon(
            onPressed: _exporting ? null : () => _export(print: true),
            icon: const Icon(Icons.print_outlined),
            label: const Text('Print'),
          ),
        ],
        bottom: const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(icon: Icon(Icons.point_of_sale), text: 'Ticket sales'),
            Tab(icon: Icon(Icons.stadium_outlined), text: 'Race attendance'),
            Tab(icon: Icon(Icons.people_outline), text: 'User activity'),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  child: AsyncDropdown(
                    load: SeasonProvider().getAll,
                    label: 'Season',
                    allLabel: 'All seasons',
                    idOf: (s) => s.seasonID,
                    labelOf: (s) => '${s.year}',
                    onChanged: (s) {
                      _season = s;
                      _reload();
                    },
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickPeriod,
                  icon: const Icon(Icons.date_range),
                  label: Text(_period == null ? 'Purchase period' : '${formatDate(_period!.start)} – ${formatDate(_period!.end)}'),
                ),
                if (_period != null)
                  IconButton(
                    tooltip: 'Clear period filter',
                    icon: const Icon(Icons.filter_alt_off),
                    onPressed: () {
                      _period = null;
                      _reload();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<ReportData>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return ErrorView(error: snapshot.error!, onRetry: _reload);
                  final data = snapshot.data;
                  if (data == null || snapshot.connectionState != ConnectionState.done) return const LoadingView();
                  return TabBarView(children: [_SalesTab(data), _AttendanceTab(data.attendance), _ActivityTab(data.activity)]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _chartColors = [AppColors.red, AppColors.carbonLight, AppColors.warning, AppColors.success, Colors.blueGrey, Colors.purple];

class _SalesTab extends StatelessWidget {
  final ReportData data;

  const _SalesTab(this.data);

  @override
  Widget build(BuildContext context) {
    final sales = data.sales.where((s) => s.ticketsSold > 0).toList();
    final totalSold = data.sales.fold<int>(0, (sum, s) => sum + s.ticketsSold);
    final totalRevenue = data.sales.fold<double>(0, (sum, s) => sum + s.totalRevenue);
    if (totalSold == 0) return const EmptyView(message: 'No tickets sold for the selected filter.', icon: Icons.bar_chart);

    final maxRevenue = sales.map((s) => s.totalRevenue).reduce((a, b) => a > b ? a : b);
    return ListView(
      children: [
        Row(
          children: [
            Expanded(child: _Metric('Sold tickets', formatNumber(totalSold))),
            const SizedBox(width: 16),
            Expanded(child: _Metric('Revenue', formatMoney(totalRevenue))),
            const SizedBox(width: 16),
            Expanded(child: _Metric('Races with sales', formatNumber(sales.length))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _ChartCard(
                title: 'Revenue per race',
                child: BarChart(
                  BarChartData(
                    maxY: maxRevenue * 1.15,
                    gridData: const FlGridData(drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                          '${sales[group.x].raceName}\n${formatMoney(rod.toY)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 64,
                          getTitlesWidget: (value, meta) => Text(formatNumber(value.round()), style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) => Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(_shortName(sales[value.toInt()].raceName), style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < sales.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: sales[i].totalRevenue,
                              color: AppColors.red,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _ChartCard(
                title: 'Sales by ticket type',
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: [
                            for (var i = 0; i < data.typeSales.length; i++)
                              PieChartSectionData(
                                value: data.typeSales[i].ticketsSold.toDouble(),
                                color: _chartColors[i % _chartColors.length],
                                radius: 60,
                                title: '${(data.typeSales[i].ticketsSold * 100 / totalSold).round()}%',
                                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < data.typeSales.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(width: 12, height: 12, color: _chartColors[i % _chartColors.length]),
                                const SizedBox(width: 8),
                                Text('${data.typeSales[i].ticketType} (${formatNumber(data.typeSales[i].ticketsSold)})'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _TableCard(
          columns: const ['Race', 'Date', 'Sold tickets', 'Revenue'],
          numericFrom: 2,
          rows: [
            for (final s in data.sales) [s.raceName, formatDate(s.raceDate), formatNumber(s.ticketsSold), formatMoney(s.totalRevenue)],
          ],
        ),
      ],
    );
  }

  static String _shortName(String raceName) {
    final name = raceName.replaceAll('Grand Prix', '').replaceAll('GP', '').trim();
    return name.length > 8 ? '${name.substring(0, 7)}.' : name;
  }
}

class _AttendanceTab extends StatelessWidget {
  final List<RaceAttendance> attendance;

  const _AttendanceTab(this.attendance);

  @override
  Widget build(BuildContext context) {
    if (attendance.isEmpty) {
      return const EmptyView(message: 'No races with ticket offers for the selected filter.', icon: Icons.stadium_outlined);
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Race')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Capacity'), numeric: true),
              DataColumn(label: Text('Sold'), numeric: true),
              DataColumn(label: Text('Occupancy')),
            ],
            rows: [
              for (final a in attendance)
                DataRow(
                  cells: [
                    DataCell(Text(a.raceName, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(formatDate(a.raceDate))),
                    DataCell(Text(formatNumber(a.capacity))),
                    DataCell(Text(formatNumber(a.ticketsSold))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 140,
                            child: LinearProgressIndicator(
                              value: (a.occupancyPercent / 100).clamp(0, 1),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                              color: AppColors.red,
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('${a.occupancyPercent.toStringAsFixed(1)} %'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  final UserActivity activity;

  const _ActivityTab(this.activity);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Row(
          children: [
            Expanded(child: _Metric('Registered users', formatNumber(activity.totalUsersRegistered))),
            const SizedBox(width: 16),
            Expanded(child: _Metric('Active buyers', formatNumber(activity.activeBuyers))),
            const SizedBox(width: 16),
            Expanded(child: _Metric('Tickets purchased', formatNumber(activity.totalTicketsPurchased))),
            const SizedBox(width: 16),
            Expanded(child: _Metric('Revenue', formatMoney(activity.totalRevenue))),
            const SizedBox(width: 16),
            Expanded(child: _Metric('Race views', formatNumber(activity.raceViews))),
          ],
        ),
        const SizedBox(height: 16),
        Text('Top customers', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        activity.topCustomers.isEmpty
            ? const EmptyView(message: 'No purchases for the selected filter.')
            : _TableCard(
                columns: const ['Customer', 'Username', 'Tickets', 'Spent', 'Last purchase', 'Race views'],
                numericFrom: 2,
                rows: [
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
              ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            SizedBox(height: 260, child: child),
          ],
        ),
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;
  final int numericFrom;

  const _TableCard({required this.columns, required this.rows, required this.numericFrom});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          columns: [for (var i = 0; i < columns.length; i++) DataColumn(label: Text(columns[i]), numeric: i >= numericFrom)],
          rows: [
            for (final row in rows) DataRow(cells: [for (final cell in row) DataCell(Text(cell))]),
          ],
        ),
      ),
    );
  }
}
