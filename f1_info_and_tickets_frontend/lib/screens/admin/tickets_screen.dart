import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../api/providers.dart';
import '../../core/formatters.dart';
import '../../core/validators.dart';
import '../../models/race.dart';
import '../../models/ticket.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_page.dart';
import '../../widgets/admin/async_dropdown.dart';
import '../../widgets/admin/crud.dart';
import '../../widgets/admin/paged_table.dart';

/// Sold tickets (read-only overview) and the ticket offer per race (category, price, capacity).
class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: AdminPage(
        title: 'Tickets',
        subtitle: 'Sold tickets and ticket offers per race',
        bottom: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Sold tickets'),
            Tab(icon: Icon(Icons.sell_outlined), text: 'Ticket offers'),
          ],
        ),
        child: TabBarView(children: [_SoldTicketsTab(), _TicketOffersTab()]),
      ),
    );
  }
}

Color _ticketStatusColor(String status) => switch (status) {
  'Active' => AppColors.success,
  'Refunded' => AppColors.red,
  _ => Colors.grey,
};

class _SoldTicketsTab extends StatefulWidget {
  const _SoldTicketsTab();

  @override
  State<_SoldTicketsTab> createState() => _SoldTicketsTabState();
}

class _SoldTicketsTabState extends State<_SoldTicketsTab> with AutomaticKeepAliveClientMixin {
  final _table = PagedTableController();
  int? _raceId;
  int? _ticketTypeId;
  DateTimeRange? _period;

  @override
  bool get wantKeepAlive => true;

  Future<void> _pickPeriod() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _period,
      helpText: 'Purchase period',
    );
    if (picked == null) return;
    setState(() => _period = picked);
    _table.reload(firstPage: true);
  }

  void _clearPeriod() {
    setState(() => _period = null);
    _table.reload(firstPage: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final period = _period;
    return PagedTable<Ticket>(
      controller: _table,
      load: (query) => TicketProvider().get(
        filter: {
          ...query,
          'RaceID': _raceId,
          'TicketTypeID': _ticketTypeId,
          // Read the field, not the local copy: the table reloads before this widget rebuilds.
          'PurchaseDateFrom': _period?.start,
          // The end date is inclusive.
          'PurchaseDateTo': _period?.end.add(const Duration(days: 1)),
        },
      ),
      searchHint: 'Search by customer or race',
      emptyMessage: 'No tickets sold yet.',
      filters: [
        SizedBox(
          width: 280,
          child: AsyncDropdown<Race>(
            load: RaceProvider().getAll,
            label: 'Race',
            allLabel: 'All races',
            idOf: (r) => r.raceID,
            labelOf: (r) => '${r.raceName} ${r.seasonYear}',
            onChanged: (r) {
              _raceId = r?.raceID;
              _table.reload(firstPage: true);
            },
          ),
        ),
        SizedBox(
          width: 220,
          child: AsyncDropdown(
            load: TicketTypeProvider().getAll,
            label: 'Ticket type',
            allLabel: 'All types',
            idOf: (t) => t.ticketTypeID,
            labelOf: (t) => t.name,
            onChanged: (t) {
              _ticketTypeId = t?.ticketTypeID;
              _table.reload(firstPage: true);
            },
          ),
        ),
        OutlinedButton.icon(
          onPressed: _pickPeriod,
          icon: const Icon(Icons.date_range),
          label: Text(period == null ? 'Purchase period' : '${formatDate(period.start)} – ${formatDate(period.end)}'),
        ),
        if (period != null) IconButton(tooltip: 'Clear period filter', icon: const Icon(Icons.filter_alt_off), onPressed: _clearPeriod),
      ],
      columns: [
        TableColumnDef('Race', (t) => TwoLineCell(t.raceName ?? '-', formatDate(t.raceDate))),
        TableColumnDef('Customer', (t) => TwoLineCell(t.customerName ?? '-', t.username)),
        TableColumnDef('Ticket type', (t) => Text(t.ticketType ?? '-')),
        TableColumnDef('Price', (t) => Text(formatMoney(t.price)), numeric: true),
        TableColumnDef('Purchased', (t) => Text(formatDateTime(t.purchaseDate))),
        TableColumnDef('Payment', (t) => Text(t.paymentMethod ?? '-')),
        TableColumnDef('Status', (t) => StatusChip(t.statusLabel, color: _ticketStatusColor(t.status))),
      ],
      actions: [
        RowAction(
          'Ticket details',
          Icons.qr_code_2,
          (t) => showDialog(
            context: context,
            builder: (_) => _TicketDetailsDialog(ticket: t),
          ),
        ),
      ],
    );
  }
}

class _TicketDetailsDialog extends StatelessWidget {
  final Ticket ticket;

  const _TicketDetailsDialog({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, String)>[
      (Icons.flag_outlined, 'Race', ticket.raceName ?? '-'),
      (Icons.event_outlined, 'Race date', formatDateTime(ticket.raceDate)),
      (Icons.location_on_outlined, 'Circuit', ticket.circuitName ?? '-'),
      (Icons.event_seat_outlined, 'Ticket type', ticket.ticketType ?? '-'),
      (Icons.person_outline, 'Customer', '${ticket.customerName ?? '-'} (${ticket.username ?? '-'})'),
      (Icons.euro, 'Price', formatMoney(ticket.price)),
      (Icons.shopping_cart_outlined, 'Purchased', formatDateTime(ticket.purchaseDate)),
      (Icons.payment, 'Payment', '${ticket.paymentMethod ?? '-'} · ${ticket.paymentStatus ?? '-'}'),
      (Icons.verified_outlined, 'Status', ticket.statusLabel),
      if (ticket.refundedAt != null) (Icons.undo, 'Refunded', formatDateTime(ticket.refundedAt!)),
    ];
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DialogHeader(title: 'Ticket details', onClose: () => Navigator.pop(context)),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        for (final (icon, label, value) in rows)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(icon, size: 20, color: Colors.grey.shade600),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 110,
                                  child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
                                ),
                                Expanded(
                                  child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      QrImageView(data: ticket.qrCode, size: 160),
                      Text('Entry QR code', style: TextStyle(color: Colors.grey.shade600)),
                    ],
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

class _TicketOffersTab extends StatefulWidget {
  const _TicketOffersTab();

  @override
  State<_TicketOffersTab> createState() => _TicketOffersTabState();
}

class _TicketOffersTabState extends State<_TicketOffersTab> with AutomaticKeepAliveClientMixin {
  final _table = PagedTableController();
  final _provider = RaceTicketCategoryProvider();
  int? _ticketTypeId;
  bool _upcomingOnly = true;

  @override
  bool get wantKeepAlive => true;

  Future<void> _openForm([RaceTicketCategory? category]) async {
    if (await openFormDialog(context, TicketOfferFormDialog(category: category))) _table.reload();
  }

  Future<void> _delete(RaceTicketCategory c) async {
    final deleted = await confirmDelete(
      context,
      title: 'Delete ticket offer',
      name: '${c.ticketTypeName} - ${c.raceName}',
      delete: () => _provider.delete(c.raceTicketCategoryID),
      successMessage: '${c.ticketTypeName} tickets for ${c.raceName} were deleted.',
    );
    if (deleted) _table.reload();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PagedTable<RaceTicketCategory>(
      controller: _table,
      load: (query) => _provider.get(filter: {...query, 'TicketTypeID': _ticketTypeId, 'Upcoming': _upcomingOnly ? true : null}),
      searchHint: 'Search by race or ticket type',
      emptyMessage: 'No ticket offers.',
      filters: [
        SizedBox(
          width: 220,
          child: AsyncDropdown(
            load: TicketTypeProvider().getAll,
            label: 'Ticket type',
            allLabel: 'All types',
            idOf: (t) => t.ticketTypeID,
            labelOf: (t) => t.name,
            onChanged: (t) {
              _ticketTypeId = t?.ticketTypeID;
              _table.reload(firstPage: true);
            },
          ),
        ),
        FilterChip(
          label: const Text('Upcoming races only'),
          selected: _upcomingOnly,
          onSelected: (v) {
            setState(() => _upcomingOnly = v);
            _table.reload(firstPage: true);
          },
        ),
      ],
      toolbarActions: [ElevatedButton.icon(onPressed: _openForm, icon: const Icon(Icons.add), label: const Text('Add offer'))],
      columns: [
        TableColumnDef('Race', (c) => TwoLineCell(c.raceName ?? '-', formatDateTime(c.raceDate))),
        TableColumnDef('Ticket type', (c) => Text(c.ticketTypeName ?? '-')),
        TableColumnDef('Price', (c) => Text(formatMoney(c.price)), numeric: true),
        TableColumnDef('Capacity', (c) => Text(formatNumber(c.capacity)), numeric: true),
        TableColumnDef('Sold', (c) => Text(formatNumber(c.sold)), numeric: true),
        TableColumnDef(
          'Available',
          (c) => Text(
            formatNumber(c.available),
            style: TextStyle(color: c.available == 0 ? AppColors.red : null, fontWeight: FontWeight.w600),
          ),
          numeric: true,
        ),
      ],
      actions: [
        RowAction('Edit', Icons.edit_outlined, _openForm),
        RowAction('Delete', Icons.delete_outline, _delete, color: AppColors.red),
      ],
    );
  }
}

class TicketOfferFormDialog extends StatefulWidget {
  final RaceTicketCategory? category;

  const TicketOfferFormDialog({super.key, this.category});

  @override
  State<TicketOfferFormDialog> createState() => _TicketOfferFormDialogState();
}

class _TicketOfferFormDialogState extends State<TicketOfferFormDialog> with CrudFormMixin {
  late int? _raceId = widget.category?.raceID;
  late int? _ticketTypeId = widget.category?.ticketTypeID;
  late final _price = TextEditingController(text: widget.category?.price.toStringAsFixed(2));
  late final _capacity = TextEditingController(text: widget.category?.capacity.toString());

  bool get _isEdit => widget.category != null;

  @override
  void dispose() {
    _price.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _save() => submit(() async {
    final request = {
      'raceID': _raceId,
      'ticketTypeID': _ticketTypeId,
      'price': Validators.parseDecimal(_price.text),
      'capacity': int.parse(_capacity.text.trim()),
    };
    final provider = RaceTicketCategoryProvider();
    final saved = _isEdit ? await provider.update(widget.category!.raceTicketCategoryID, request) : await provider.insert(request);
    return _isEdit
        ? '${saved.ticketTypeName} tickets for ${saved.raceName} were updated.'
        : '${saved.ticketTypeName} tickets for ${saved.raceName} were added (${formatMoney(saved.price)}, ${saved.capacity} seats).';
  });

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: _isEdit ? 'Edit ticket offer' : 'New ticket offer',
      formKey: formKey,
      saving: saving,
      onSave: _save,
      children: [
        AsyncDropdown<Race>(
          // Tickets are only offered for races that have not started yet.
          load: () async => (await RaceProvider().get(filter: {'Upcoming': true, 'PageSize': 100})).items,
          label: 'Race (upcoming)',
          initialId: _raceId,
          idOf: (r) => r.raceID,
          labelOf: (r) => '${r.raceName} · ${formatDate(r.date)}',
          requiredMessage: 'Select an upcoming race.',
          forceErrorText: serverError('raceID'),
          onChanged: (r) => _raceId = r?.raceID,
        ),
        AsyncDropdown(
          load: TicketTypeProvider().getAll,
          label: 'Ticket type',
          initialId: _ticketTypeId,
          idOf: (t) => t.ticketTypeID,
          labelOf: (t) => t.name,
          requiredMessage: 'Select a ticket type.',
          forceErrorText: serverError('ticketTypeID'),
          onChanged: (t) => _ticketTypeId = t?.ticketTypeID,
        ),
        FormRow(
          children: [
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price (EUR)', hintText: 'e.g. 249.99', suffixText: '€'),
              validator: Validators.decimalRange('Price', 1, 100000),
              forceErrorText: serverError('price'),
            ),
            TextFormField(
              controller: _capacity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacity (seats)', hintText: 'e.g. 5000'),
              validator: Validators.intRange('Capacity', 1, 500000),
              forceErrorText: serverError('capacity'),
            ),
          ],
        ),
      ],
    );
  }
}
