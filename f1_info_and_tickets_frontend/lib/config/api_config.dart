import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// API address. Override with: flutter run --dart-define=API_BASE_URL=http://host:port
/// Defaults follow the submission rules: 10.0.2.2 on the Android emulator, localhost on Windows.
class ApiConfig {
  static const String _configured = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configured.isNotEmpty) {
      return _configured.endsWith('/') ? _configured.substring(0, _configured.length - 1) : _configured;
    }
    return defaultTargetPlatform == TargetPlatform.android ? 'http://10.0.2.2:5174' : 'http://localhost:5174';
  }

  static String get apiUrl => '$baseUrl/api';

  /// Turns a server-relative image path (e.g. /Images/Drivers/x.png) into a full URL.
  static String? imageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '$baseUrl${path.startsWith('/') ? '' : '/'}$path';
  }
}
