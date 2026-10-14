/// Helpers for reading API JSON.
DateTime parseDateTime(dynamic value) => DateTime.parse(value as String).toLocal();

DateTime? parseDateTimeOrNull(dynamic value) => value == null ? null : parseDateTime(value);

/// Calendar dates (e.g. birth date) are kept as-is, without converting to local time.
DateTime parseDate(dynamic value) {
  final d = DateTime.parse(value as String);
  return DateTime(d.year, d.month, d.day);
}

double toDouble(dynamic value) => value == null ? 0 : (value as num).toDouble();

/// Date-only value for the API (yyyy-MM-dd).
String dateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
