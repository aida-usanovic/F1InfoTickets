import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/providers.dart';
import '../../models/user.dart';
import '../../state/auth_state.dart';
import '../../state/cart_state.dart';
import '../../state/notification_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feedback.dart';
import '../../widgets/mobile/profile_avatar.dart';
import '../../widgets/state_views.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'favorites_screen.dart';
import 'my_tickets_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<User> _future = ProfileProvider().get();

  Future<void> _open(Widget screen, {bool reloadProfile = false}) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    if (reloadProfile && changed == true) {
      setState(() {
        _future = ProfileProvider().get();
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await confirmAction(context, title: 'Sign out', message: 'Do you want to sign out?', confirmLabel: 'Sign out');
    if (!confirmed || !mounted) return;
    final auth = context.read<AuthState>();
    context.read<CartState>().reset();
    Navigator.popUntil(context, (route) => route.isFirst);
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<User>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(
              error: snapshot.error!,
              onRetry: () => setState(() {
                _future = ProfileProvider().get();
              }),
            );
          }
          final user = snapshot.data;
          if (user == null) return const LoadingView();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  ProfileAvatar(user: user),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        Text('@${user.username}', style: const TextStyle(color: AppColors.muted)),
                        Text(user.email, style: const TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                child: Column(
                  children: [
                    _MenuTile(Icons.confirmation_number_outlined, 'My tickets', () => _open(const MyTicketsScreen())),
                    _MenuTile(
                      Icons.notifications_outlined,
                      'Notifications',
                      () => _open(const NotificationsScreen()),
                      badge: context.watch<NotificationState>().unread,
                    ),
                    _MenuTile(Icons.favorite_border, 'Favourite drivers & teams', () => _open(const FavoritesScreen())),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    _MenuTile(Icons.edit_outlined, 'Edit profile', () => _open(EditProfileScreen(user: user), reloadProfile: true)),
                    _MenuTile(Icons.lock_outline, 'Change password', () => _open(const ChangePasswordScreen())),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(child: _MenuTile(Icons.logout, 'Sign out', _logout, color: AppColors.red)),
            ],
          );
        },
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final int badge;
  final Color? color;

  const _MenuTile(this.icon, this.title, this.onTap, {this.badge = 0, this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.red),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge > 0) Badge(label: Text('$badge'), backgroundColor: AppColors.red),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
