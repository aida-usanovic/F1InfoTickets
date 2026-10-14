import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_platform.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/user.dart';

/// Signed-in user. The role and expiry are read from the JWT itself, not from local settings.
class AuthState extends ChangeNotifier {
  static const _tokenKey = 'auth_token';

  final _api = ApiClient.instance;

  String? _token;
  int? _userId;
  String? _username;
  String? _role;
  bool _initialized = false;

  bool get isInitialized => _initialized;
  bool get isAuthenticated => _token != null;
  int? get userId => _userId;
  String? get username => _username;
  String? get role => _role;
  bool get isAdmin => _role == 'Admin';

  AuthState() {
    _api.onUnauthorized = () => _clear(notify: true);
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null && !_applyToken(token)) await prefs.remove(_tokenKey);
    _initialized = true;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final json = await _api.post('Auth/login', body: {'username': username, 'password': password});
    final response = AuthResponse.fromJson(json);

    if (!AppPlatform.isRoleAllowed(response.role)) {
      throw ApiException(AppPlatform.wrongRoleMessage);
    }
    if (!_applyToken(response.token)) {
      throw ApiException('Sign-in failed. Please try again.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, response.token);
    notifyListeners();
  }

  /// Customer self-registration (mobile only).
  Future<void> register(Map<String, dynamic> request) => _api.post('Auth/register', body: request);

  Future<void> logout() async {
    try {
      if (_token != null) await _api.post('Auth/logout');
    } catch (_) {
      // The local session is cleared even if the server cannot be reached.
    }
    await _clear(notify: true);
  }

  Future<void> _clear({required bool notify}) async {
    _token = null;
    _userId = null;
    _username = null;
    _role = null;
    _api.token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    if (notify) notifyListeners();
  }

  /// Validates expiry and platform role; returns false if the token cannot be used.
  bool _applyToken(String token) {
    final claims = _decodeClaims(token);
    if (claims == null) return false;

    final exp = claims['exp'];
    if (exp is! int || DateTime.fromMillisecondsSinceEpoch(exp * 1000).isBefore(DateTime.now())) return false;

    final role = (claims['role'] ?? claims['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'])?.toString();
    if (role == null || !AppPlatform.isRoleAllowed(role)) return false;

    _token = token;
    _api.token = token;
    _role = role;
    _username = (claims['unique_name'] ?? claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'])?.toString();
    _userId = int.tryParse(
      (claims['nameid'] ?? claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'])?.toString() ?? '',
    );
    return true;
  }

  static Map<String, dynamic>? _decodeClaims(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      return jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
