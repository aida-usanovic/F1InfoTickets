import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';

/// Thin HTTP wrapper: adds the JWT, encodes query parameters and turns error responses into [ApiException].
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _timeout = Duration(seconds: 20);

  String? token;

  /// Called when the server rejects the token (expired or revoked), so the app can sign the user out.
  void Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) => _send(() => http.get(_uri(path, query), headers: _headers()));

  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query}) =>
      _send(() => http.post(_uri(path, query), headers: _headers(), body: body == null ? null : jsonEncode(body)));

  Future<dynamic> put(String path, {Object? body}) =>
      _send(() => http.put(_uri(path, null), headers: _headers(), body: body == null ? null : jsonEncode(body)));

  Future<dynamic> delete(String path) => _send(() => http.delete(_uri(path, null), headers: _headers()));

  /// Multipart form (used for records with an image). Null values are not sent.
  Future<dynamic> multipart(String method, String path, Map<String, dynamic> fields, {String? filePath, String fileField = 'Image'}) {
    return _send(() async {
      final request = http.MultipartRequest(method, _uri(path, null));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      fields.forEach((key, value) {
        if (value != null) request.fields[key] = _queryValue(value);
      });
      if (filePath != null) request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
      return http.Response.fromStream(await request.send());
    });
  }

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Uri _uri(String path, Map<String, dynamic>? query) {
    final params = <String, String>{};
    query?.forEach((key, value) {
      if (value == null || (value is String && value.trim().isEmpty)) return;
      params[key] = _queryValue(value);
    });
    return Uri.parse('${ApiConfig.apiUrl}/$path').replace(queryParameters: params.isEmpty ? null : params);
  }

  static String _queryValue(Object value) {
    if (value is DateTime) return value.toUtc().toIso8601String();
    return value.toString();
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on SocketException {
      throw ApiException('The server is not reachable. Check that the API is running and the address is correct (${ApiConfig.baseUrl}).');
    } on http.ClientException {
      throw ApiException('The server is not reachable. Check that the API is running and the address is correct (${ApiConfig.baseUrl}).');
    } on Exception {
      throw ApiException('The server is not responding. Please try again.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw _toException(response);
  }

  ApiException _toException(http.Response response) {
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    final message = body?['message'] as String?;
    switch (response.statusCode) {
      case 400:
        final errors = body?['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final fieldErrors = <String, String>{};
          errors.forEach((key, value) {
            if (value is List && value.isNotEmpty) fieldErrors[_camelCase(key)] = value.first.toString();
          });
          return ApiException(fieldErrors.values.first, statusCode: 400, fieldErrors: fieldErrors);
        }
        return ApiException(message ?? 'Invalid request.', statusCode: 400);
      case 401:
        if (message == null) onUnauthorized?.call();
        return ApiException(message ?? 'Your session has expired. Please sign in again.', statusCode: 401);
      case 403:
        return ApiException('You do not have permission for this action.', statusCode: 403);
      case 404:
        return ApiException(message ?? 'The requested record was not found.', statusCode: 404);
      default:
        return ApiException(message ?? 'Server error. Please try again.', statusCode: response.statusCode);
    }
  }

  // "Results[0].TimeTaken" -> "results[0].timeTaken", "Email" -> "email"
  static String _camelCase(String key) => key.split('.').map((p) => p.isEmpty ? p : p[0].toLowerCase() + p.substring(1)).join('.');
}
