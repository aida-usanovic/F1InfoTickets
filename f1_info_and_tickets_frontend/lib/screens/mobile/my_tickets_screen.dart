import 'package:flutter/material.dart';

import '../../api/providers.dart';
import '../../core/formatters.dart';
import '../../models/ticket.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mobile/mobile_widgets.dart';
import '../../widgets/state_views.dart';
import 'ticket_details_screen.dart';

/// The customer's tickets, upcoming or past, with search by race.
class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  late Future<List<Ticket>> _future = _load();
  bool _upcoming = true;
  String _search = '';

  Future<List<Ticket>> _load() async => (await TicketProvider().getMine(pageSize: 100)).items;

  Future<void> _open(Ticket ticket) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => TicketDetailsScreen(ticket: ticket)));
    if (changed == true) {
      setState(() {
        _future = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My tickets')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Upcoming')),
                      ButtonSegment(value: false, label: Text('Past')),
                    ],
                    selected: {_upcoming},
                    onSelectionChanged: (s) => setState(() => _upcoming = s.first),
                  ),
                ),
                const SizedBox(height: 10),
                SearchField(hint: 'Search by race', onChanged: (v) => setState(() => _search = v.trim().toLowerCase())),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Ticket>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorView(
                    error: snapshot.error!,
                    onRetry: () => setState(() {
                      _future = _load();
                    }),
                  );
                }
                final tickets = snapshot.data;
                if (tickets == null) return const LoadingView();
                final now = DateTime.now();
                final filtered = tickets
                    .where((t) => t.raceDate.isAfter(now) == _upcoming)
                    .where((t) => _search.isEmpty || (t.raceName ?? '').toLowerCase().contains(_search))
                    .toList();
                if (filtered.isEmpty) {
                  return EmptyView(
                    message: _upcoming ? 'You have no tickets for upcoming races.' : 'You have no tickets for past races.',
                    icon: Icons.confirmation_number_outlined,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _future = _load();
                    });
                    await _future;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _TicketCard(ticket: filtered[i], onTap: () => _open(filtered[i])),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = switch (ticket.status) {
      'Active' => AppColors.success,
      'Refunded' => AppColors.red,
      _ => AppColors.muted,
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(ticket.status == 'Refunded' ? Icons.money_off : Icons.qr_code_2, size: 44, color: ticket.status == 'Active' ? null : AppColors.muted),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket.raceName ?? '-', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                      '${ticket.ticketType ?? '-'} · ${formatDateTime(ticket.raceDate)}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.statusLabel,
                      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(formatMoney(ticket.price), style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
