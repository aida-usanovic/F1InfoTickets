import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/providers.dart';
import '../../core/api_exception.dart';
import '../../core/formatters.dart';
import '../../models/ticket.dart';
import '../../state/cart_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feedback.dart';
import '../../widgets/state_views.dart';
import 'my_tickets_screen.dart';
import 'paypal_checkout_screen.dart';

/// Cart kept on the server: change quantities, remove items and pay with PayPal.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<void> _future = context.read<CartState>().load();
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(CartItem item) async {
    final confirmed = await confirmAction(
      context,
      title: 'Remove tickets',
      message: 'Remove ${item.quantity} × ${item.ticketType} for ${item.raceName} from your cart?',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _run(() async {
      await context.read<CartState>().remove(item.cartItemID);
      if (mounted) showSuccess(context, '${item.ticketType} tickets for ${item.raceName} were removed from your cart.');
    });
  }

  Future<void> _checkout(Cart cart) async {
    final confirmed = await confirmAction(
      context,
      title: 'Checkout',
      message: 'Pay ${formatMoney(cart.total)} for ${cart.totalQuantity} ticket(s) with PayPal?',
      confirmLabel: 'Pay with PayPal',
    );
    if (!confirmed || !mounted) return;

    await _run(() async {
      final order = await PaymentProvider().create(returnUrl: PayPalCheckoutScreen.returnUrl, cancelUrl: PayPalCheckoutScreen.cancelUrl);
      if (!mounted) return;
      final paid = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PayPalCheckoutScreen(approvalUrl: order.approvalUrl, orderId: order.providerOrderId),
        ),
      );
      if (!mounted) return;
      await context.read<CartState>().load();
      if (!mounted) return;
      if (paid == true) {
        showSuccess(context, 'Payment completed. Your tickets are in My tickets.');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MyTicketsScreen()));
      } else {
        showError(context, ApiException('The payment was cancelled. Your cart is unchanged.'));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>().cart;
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: FutureBuilder<void>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(
              error: snapshot.error!,
              onRetry: () => setState(() {
                _future = context.read<CartState>().load();
              }),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
          if (cart.items.isEmpty) {
            return const EmptyView(message: 'Your cart is empty.\nPick a race in Tickets to add some.', icon: Icons.shopping_cart_outlined);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cart.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _CartItemCard(
              item: cart.items[i],
              enabled: !_busy,
              onQuantity: (q) => _run(() => context.read<CartState>().updateQuantity(cart.items[i].cartItemID, q)),
              onRemove: () => _remove(cart.items[i]),
            ),
          );
        },
      ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : SafeArea(
              child: Container(
                color: AppColors.carbon,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${cart.totalQuantity} ticket(s)', style: const TextStyle(color: AppColors.muted)),
                          Text(formatMoney(cart.total), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _busy ? null : () => _checkout(cart),
                      icon: _busy
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.payment),
                      label: const Text('Checkout'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final bool enabled;
  final ValueChanged<int> onQuantity;
  final VoidCallback onRemove;

  const _CartItemCard({required this.item, required this.enabled, required this.onQuantity, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final max = item.available < 10 ? item.available : 10;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.raceName ?? '-', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: enabled ? onRemove : null,
                  icon: const Icon(Icons.delete_outline, color: AppColors.red),
                ),
              ],
            ),
            Text('${item.ticketType ?? '-'} · ${formatDateTime(item.raceDate)}', style: const TextStyle(color: AppColors.muted)),
            Text(item.circuitName ?? '', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [
                IconButton(
                  tooltip: 'Fewer tickets',
                  onPressed: enabled && item.quantity > 1 ? () => onQuantity(item.quantity - 1) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('${item.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                IconButton(
                  tooltip: 'More tickets',
                  onPressed: enabled && item.quantity < max ? () => onQuantity(item.quantity + 1) : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                Text('× ${formatMoney(item.unitPrice)}', style: const TextStyle(color: AppColors.muted)),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(formatMoney(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
