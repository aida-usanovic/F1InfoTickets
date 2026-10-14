/// Form validators; every message says what is expected, as required by the course rules.
class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phone = RegExp(r'^\+?[0-9]{9,15}$');
  static final _username = RegExp(r'^[a-zA-Z0-9._]{3,50}$');
  static final _raceTime = RegExp(r'^\d{1,2}:[0-5]\d:[0-5]\d(\.\d{1,3})?$');
  static final _countryCode = RegExp(r'^[A-Za-z]{2,3}$');

  static String? Function(String?) required(String label, {int? maxLength}) => (value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$label is required.';
    if (maxLength != null && v.length > maxLength) return '$label can have at most $maxLength characters.';
    return null;
  };

  static String? Function(String?) optional({int? maxLength, String label = 'Field'}) => (value) {
    if (maxLength != null && (value?.trim().length ?? 0) > maxLength) return '$label can have at most $maxLength characters.';
    return null;
  };

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required.';
    if (!_email.hasMatch(v)) return 'Enter a valid email address (e.g. name@domain.com).';
    if (v.length > 100) return 'Email can have at most 100 characters.';
    return null;
  }

  static String? phone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Phone number is required.';
    if (!_phone.hasMatch(v)) return 'Enter 9 to 15 digits, optionally starting with + (e.g. +38761123456).';
    return null;
  }

  static String? username(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Username is required.';
    if (!_username.hasMatch(v)) return 'Use 3 to 50 characters: letters, digits, dot or underscore.';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required.';
    if (v.length < 6) return 'Password must have at least 6 characters.';
    return null;
  }

  /// New password that may stay empty (e.g. admin editing a user without changing the password).
  static String? optionalPassword(String? value) => (value ?? '').isEmpty ? null : password(value);

  static String? Function(String?) matches(String Function() other, {String message = 'Passwords do not match.'}) =>
      (value) => (value ?? '') == other() ? null : message;

  static String? Function(String?) intRange(String label, int min, int max) => (value) {
    final v = int.tryParse(value?.trim() ?? '');
    if (value == null || value.trim().isEmpty) return '$label is required.';
    if (v == null) return '$label must be a whole number.';
    if (v < min || v > max) return '$label must be between $min and $max.';
    return null;
  };

  static String? Function(String?) decimalRange(String label, double min, double max) => (value) {
    final text = value?.trim().replaceAll(',', '.') ?? '';
    if (text.isEmpty) return '$label is required.';
    final v = double.tryParse(text);
    if (v == null) return '$label must be a number (e.g. 5.412).';
    if (v < min || v > max) return '$label must be between $min and $max.';
    return null;
  };

  static String? raceTime(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Time is required.';
    if (!_raceTime.hasMatch(v)) return 'Use the format h:mm:ss.fff (e.g. 1:32:15.123).';
    return null;
  }

  static String? countryCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Country code is required.';
    if (!_countryCode.hasMatch(v)) return 'The code must have 2 or 3 letters (e.g. BA, ITA).';
    return null;
  }

  static String? Function(T?) selected<T>(String label) =>
      (value) => value == null ? 'Select: $label.' : null;

  static double? parseDecimal(String text) => double.tryParse(text.trim().replaceAll(',', '.'));
}
