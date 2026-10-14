/// Error returned by the API: a message for the user and, for validation errors, messages per field.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  /// Validation message for a request field (camelCase name, e.g. "email").
  String? fieldError(String field) => fieldErrors[field];

  @override
  String toString() => message;
}

/// Readable message for any error caught in the UI.
String errorMessage(Object error) => error is ApiException ? error.message : 'An unexpected error occurred. Please try again.';
