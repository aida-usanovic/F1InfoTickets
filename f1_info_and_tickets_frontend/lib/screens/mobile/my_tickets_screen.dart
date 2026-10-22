import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/providers.dart';
import '../../core/formatters.dart';
import '../../core/paged_result.dart';
import '../../models/ticket.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mobile/infinite_list.dart';
import '../../widgets/mobile/mobile_widgets.dart';
import 'ticket_details_screen.dart';

/// The customer's tickets, upcoming or past, loaded page by page; the filter and the search run on the server.
class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final _list = InfiniteListController();
  Timer? _debounce;
  bool _upcoming = true;
  String _search = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _search = value.trim());
      _list.reload();
    });
  }

  Future<PagedResult<Ticket>> _load(int page) => TicketProvider().getMine(page: page, upcoming: _upcoming, search: _search);

  Future<void> _open(Ticket ticket) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => TicketDetailsScreen(ticket: ticket)));
    if (changed == true) _list.reload();
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
                    onSelectionChanged: (s) {
                      setState(() => _upcoming = s.first);
                      _list.reload();
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SearchField(hint: 'Search by race, circuit or country', onChanged: _onSearch),
              ],
            ),
          ),
          Expanded(
            child: InfiniteList<Ticket>(
              controller: _list,
              load: _load,
              emptyMessage: _search.isNotEmpty
                  ? 'No tickets match "$_search".'
                  : _upcoming
                  ? 'You have no tickets for upcoming races.'
                  : 'You have no tickets for past races.',
              itemBuilder: (context, ticket) => _TicketCard(ticket: ticket, onTap: () => _open(ticket)),
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
