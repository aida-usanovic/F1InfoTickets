import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/feedback.dart';
import 'admin_section.dart';
import 'dashboard_screen.dart';
import 'drivers_screen.dart';
import 'races_screen.dart';
import 'reference_screen.dart';
import 'reports_screen.dart';
import 'results_screen.dart';
import 'teams_screen.dart';
import 'tickets_screen.dart';
import 'users_screen.dart';

extension on AdminSection {
  String get title => switch (this) {
    AdminSection.dashboard => 'Dashboard',
    AdminSection.drivers => 'Drivers',
    AdminSection.teams => 'Teams',
    AdminSection.races => 'Races',
    AdminSection.results => 'Results',
    AdminSection.tickets => 'Tickets',
    AdminSection.reports => 'Reports',
    AdminSection.users => 'Users',
    AdminSection.reference => 'Reference data',
  };

  IconData get icon => switch (this) {
    AdminSection.dashboard => Icons.dashboard_outlined,
    AdminSection.drivers => Icons.sports_motorsports_outlined,
    AdminSection.teams => Icons.groups_outlined,
    AdminSection.races => Icons.flag_outlined,
    AdminSection.results => Icons.emoji_events_outlined,
    AdminSection.tickets => Icons.confirmation_number_outlined,
    AdminSection.reports => Icons.bar_chart_outlined,
    AdminSection.users => Icons.manage_accounts_outlined,
    AdminSection.reference => Icons.list_alt_outlined,
  };
}

/// Desktop admin layout: sidebar navigation + content area.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  AdminSection _section = AdminSection.dashboard;

  void _open(AdminSection section) => setState(() => _section = section);

  Widget _buildSection() => switch (_section) {
    AdminSection.dashboard => DashboardScreen(onNavigate: _open),
    AdminSection.drivers => const DriversScreen(),
    AdminSection.teams => const TeamsScreen(),
    AdminSection.races => const RacesScreen(),
    AdminSection.results => const ResultsScreen(),
    AdminSection.tickets => const TicketsScreen(),
    AdminSection.reports => const ReportsScreen(),
    AdminSection.users => const UsersScreen(),
    AdminSection.reference => const ReferenceScreen(),
  };

  Future<void> _logout() async {
    final confirmed = await confirmAction(context, title: 'Sign out', message: 'Do you want to sign out?', confirmLabel: 'Sign out');
    if (confirmed && mounted) await context.read<AuthState>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 230,
            color: AppColors.ink,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: BrandLogo(size: 20, color: Colors.white),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final section in AdminSection.values)
                          _NavItem(section: section, selected: section == _section, onTap: () => _open(section)),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.outline, height: 1),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.red,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(auth.username ?? '', style: const TextStyle(color: Colors.white)),
                    subtitle: const Text('Administrator', style: TextStyle(color: AppColors.muted)),
                    trailing: IconButton(
                      tooltip: 'Sign out',
                      icon: const Icon(Icons.logout, color: AppColors.muted),
                      onPressed: _logout,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // A new key per section resets its state (filters, paging) when it is reopened.
          Expanded(
            child: KeyedSubtree(key: ValueKey(_section), child: _buildSection()),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final AdminSection section;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.section, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? AppColors.red : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: Icon(section.icon, color: selected ? Colors.white : AppColors.muted),
          title: Text(
            section.title,
            style: TextStyle(color: selected ? Colors.white : const Color(0xFFD5D5DC), fontWeight: FontWeight.w500),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
