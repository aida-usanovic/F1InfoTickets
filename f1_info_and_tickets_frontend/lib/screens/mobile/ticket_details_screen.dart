import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../api/providers.dart';
import '../../core/formatters.dart';
import '../../models/ticket.dart';
import '../../state/notification_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feedback.dart';
import '../../widgets/mobile/mobile_widgets.dart';

/// Ticket with its entry QR code. Tickets for upcoming races can be refunded (the whole purchase is refunded);
/// refunded and used tickets no longer show the QR code.
class TicketDetailsScreen extends StatefulWidget {
  final Ticket ticket;

  const TicketDetailsScreen({super.key, required this.ticket});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  bool _refunding = false;

  bool get _canRefund => widget.ticket.status == 'Active' && widget.ticket.raceDate.isAfter(DateTime.now());

  Future<void> _refund() async {
    final confirmed = await confirmAction(
      context,
      title: 'Refund purchase',
      message:
          'The whole purchase this ticket belongs to will be refunded through PayPal and all of its tickets will be cancelled. Continue?',
      confirmLabel: 'Refund',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _refunding = true);
    try {
      await PaymentProvider().refund(widget.ticket.paymentID);
      if (!mounted) return;
      // The refund notification is shown right away instead of after the next poll.
      context.read<NotificationState>().refresh();
      showSuccess(context, 'The purchase was refunded and its tickets were cancelled.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _refunding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    return Scaffold(
      appBar: AppBar(title: const Text('Ticket')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (t.status == 'Active') ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(data: t.qrCode, size: 220),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Show this code at the circuit entrance.', style: TextStyle(color: AppColors.muted)),
            ),
          ] else
            _InvalidTicketBanner(ticket: t),
          const SizedBox(height: 16),
          InfoCard(
            title: t.raceName,
            children: [
              InfoRow(Icons.event_outlined, 'Race date', formatDateTime(t.raceDate)),
              InfoRow(Icons.route_outlined, 'Circuit', t.circuitName ?? '-'),
              InfoRow(Icons.event_seat_outlined, 'Ticket type', t.ticketType ?? '-'),
              InfoRow(Icons.euro, 'Price', formatMoney(t.price)),
              InfoRow(Icons.shopping_cart_outlined, 'Purchased', formatDateTime(t.purchaseDate)),
              InfoRow(Icons.payment, 'Payment', t.paymentMethod ?? '-'),
              InfoRow(Icons.verified_outlined, 'Status', t.statusLabel),
              if (t.refundedAt != null) InfoRow(Icons.undo, 'Refunded', formatDateTime(t.refundedAt!)),
            ],
          ),
          if (_canRefund) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.red),
              onPressed: _refunding ? null : _refund,
              icon: _refunding
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.undo),
              label: const Text('Refund purchase'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shown instead of the QR code, so a refunded or used ticket cannot be presented at the entrance.
class _InvalidTicketBanner extends StatelessWidget {
  final Ticket ticket;

  const _InvalidTicketBanner({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final refunded = ticket.status == 'Refunded';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(refunded ? Icons.money_off : Icons.qr_code_2, color: AppColors.red, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  refunded ? 'Ticket refunded' : 'Ticket already used',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  refunded
                      ? 'This ticket was cancelled${ticket.refundedAt != null ? ' on ${formatDateTime(ticket.refundedAt!)}' : ''} and is no longer valid for entry.'
                      : 'This ticket was already scanned at the entrance.',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
