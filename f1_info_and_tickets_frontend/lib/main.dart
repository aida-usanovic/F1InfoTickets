import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_platform.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/mobile/mobile_shell.dart';
import 'state/auth_state.dart';
import 'state/cart_state.dart';
import 'state/notification_state.dart';
import 'theme/app_theme.dart';
import 'widgets/state_views.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()..restoreSession()),
        ChangeNotifierProvider(create: (_) => CartState()),
        ChangeNotifierProvider(create: (_) => NotificationState()),
      ],
      child: const F1App(),
    ),
  );
}

class F1App extends StatelessWidget {
  const F1App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F1 Info & Tickets',
      debugShowCheckedModeBanner: false,
      theme: AppPlatform.isDesktopApp ? AppTheme.admin() : AppTheme.mobile(),
      home: const AuthGate(),
    );
  }
}

/// Shows the login screen or, after sign-in, the admin (desktop) or customer (mobile) app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (!auth.isInitialized) return const Scaffold(body: LoadingView());
    if (!auth.isAuthenticated) return const LoginScreen();
    return AppPlatform.isDesktopApp ? const AdminShell() : const MobileShell();
  }
}
