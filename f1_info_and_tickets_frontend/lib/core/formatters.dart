import 'package:intl/intl.dart';

// Default locale (en_US): its date symbols are built into intl, other locales would need initializeDateFormatting().
final _date = DateFormat('d MMM yyyy');
final _dateTime = DateFormat('d MMM yyyy, HH:mm');
final _shortDate = DateFormat('d MMM');
final _money = NumberFormat.currency(locale: 'en_US', symbol: '€', decimalDigits: 2);
final _number = NumberFormat.decimalPattern('en_US');

String formatDate(DateTime? date) => date == null ? '-' : _date.format(date);
String formatDateTime(DateTime? date) => date == null ? '-' : _dateTime.format(date);
String formatShortDate(DateTime? date) => date == null ? '-' : _shortDate.format(date);
String formatMoney(num? amount) => amount == null ? '-' : _money.format(amount);
String formatNumber(num? value) => value == null ? '-' : _number.format(value);
String formatKm(double km) => '${km.toStringAsFixed(3)} km';
