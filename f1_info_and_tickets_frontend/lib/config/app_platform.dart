import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// One codebase, two apps: the desktop build is the admin app, the mobile build is the customer app.
class AppPlatform {
  static bool get isDesktopApp =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  static bool isRoleAllowed(String role) {
    final isAdmin = role.toLowerCase() == 'admin';
    return isDesktopApp ? isAdmin : !isAdmin;
  }

  static String get wrongRoleMessage => isDesktopApp
      ? 'The desktop app is for administrators. Customers sign in through the mobile app.'
      : 'The mobile app is for customers. Administrators sign in through the desktop app.';
}
