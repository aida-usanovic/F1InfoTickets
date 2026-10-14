import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/providers.dart';
import '../../core/formatters.dart';
import '../../core/paged_result.dart';
import '../../models/analytics.dart';
import '../../models/race.dart';
import '../../models/ticket.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_page.dart';
import '../../widgets/admin/crud.dart';
import '../../widgets/state_views.dart';
import 'admin_section.dart';
import 'drivers_screen.dart';
import 'races_screen.dart';
import 'teams_screen.dart';

class _DashboardData {
  final Dashboard stats;
  final List<Race> upcoming;
  final List<Ticket> latestTickets;

  _DashboardData(this.stats, this.upcoming, this.latestTickets);
}

class DashboardScreen extends StatefulWidget {
  final ValueChanged<AdminSection> onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _future = _load();

  Future<_DashboardData> _load() async {
    final results = await Future.wait([
      AnalyticsProvider().dashboard(),
      RaceProvider().get(filter: {'Upcoming': true, 'PageSize': 5}),
      TicketProvider().get(filter: {'PageSize': 5}),
    ]);
    return _DashboardData(results[0] as Dashboard, (results[1] as PagedResult<Race>).items, (results[2] as PagedResult<Ticket>).items);
  }

  void _refresh() => setState(() {
    _future = _load();
  });

  /// Opens the add form directly; after saving, shows the matching list.
  Future<void> _quickAdd(Widget dialog, AdminSection section) async {
    if (await openFormDialog(context, dialog)) widget.onNavigate(section);
  }

  @override
  Widget build(BuildContext context) {
    final username = context.watch<AuthState>().username ?? '';
    return AdminPage(
      title: 'Welcome, $username',
      subtitle: 'System overview',
      actions: [OutlinedButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Refresh'))],
      child: FutureBuilder<_DashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorView(error: snapshot.error!, onRetry: _refresh);
          final data = snapshot.data;
          if (data == null) return const LoadingView();
          return ListView(
            children: [
              _buildStats(data.stats),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildUpcoming(data.upcoming)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildLatestTickets(data.latestTickets)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStats(Dashboard stats) {
    final cards = [
      _StatCard(icon: Icons.people_outline, label: 'Registered users', value: formatNumber(stats.totalUsers)),
      _StatCard(icon: Icons.sports_motorsports_outlined, label: 'Drivers', value: formatNumber(stats.totalDrivers)),
      _StatCard(icon: Icons.confirmation_number_outlined, label: 'Sold tickets', value: formatNumber(stats.ticketsSold)),
      _StatCard(icon: Icons.euro, label: 'Total revenue', value: formatMoney(stats.totalRevenue)),
      _StatCard(icon: Icons.flag_outlined, label: 'Upcoming races', value: formatNumber(stats.upcomingRaces)),
    ];
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[if (i > 0) const SizedBox(width: 16), Expanded(child: cards[i])],
      ],
    );
  }

  Widget _buildQuickActions() {
    return _Panel(
      title: 'Quick actions',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ElevatedButton.icon(
            onPressed: () => _quickAdd(const DriverFormDialog(), AdminSection.drivers),
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Add driver'),
          ),
          ElevatedButton.icon(
            onPressed: () => _quickAdd(const TeamFormDialog(), AdminSection.teams),
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('Add team'),
          ),
          ElevatedButton.icon(
            onPressed: () => _quickAdd(const RaceFormDialog(), AdminSection.races),
            icon: const Icon(Icons.add_road),
            label: const Text('Add race'),
          ),
          OutlinedButton.icon(
            onPressed: () => widget.onNavigate(AdminSection.results),
            icon: const Icon(Icons.emoji_events_outlined),
            label: const Text('Enter results'),
          ),
          OutlinedButton.icon(
            onPressed: () => widget.onNavigate(AdminSection.reports),
            icon: const Icon(Icons.bar_chart_outlined),
            label: const Text('Reports'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcoming(List<Race> races) {
    return _Panel(
      title: 'Upcoming races',
      action: TextButton(onPressed: () => widget.onNavigate(AdminSection.races), child: const Text('All races')),
      child: races.isEmpty
          ? const EmptyView(message: 'No upcoming races.')
          : Column(
              children: [
                for (final race in races)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.carbonLight,
                      child: Icon(Icons.flag, color: Colors.white, size: 20),
                    ),
                    title: Text(race.raceName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${race.circuitName ?? '-'} · ${race.location ?? '-'}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatDateTime(race.date)),
                        Text(
                          race.minTicketPrice == null ? 'No tickets on sale' : 'Tickets from ${formatMoney(race.minTicketPrice)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildLatestTickets(List<Ticket> tickets) {
    return _Panel(
      title: 'Latest purchases',
      action: TextButton(onPressed: () => widget.onNavigate(AdminSection.tickets), child: const Text('All tickets')),
      child: tickets.isEmpty
          ? const EmptyView(message: 'No tickets sold yet.')
          : Column(
              children: [
                for (final ticket in tickets)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.red,
                      child: Icon(Icons.confirmation_number, color: Colors.white, size: 20),
                    ),
                    title: Text(ticket.customerName ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${ticket.raceName ?? '-'} · ${ticket.ticketType ?? '-'}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatMoney(ticket.price), style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(formatDateTime(ticket.purchaseDate), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppColors.red),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget? action;
  final Widget child;

  const _Panel({required this.title, this.action, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
