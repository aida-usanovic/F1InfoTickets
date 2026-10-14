import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/providers.dart';
import '../../core/formatters.dart';
import '../../models/race.dart';
import '../../state/cart_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feedback.dart';
import '../../widgets/state_views.dart';
import 'cart_screen.dart';

/// Ticket categories for one race: pick a type and quantity and add them to the cart.
class RaceTicketsScreen extends StatefulWidget {
  final Race race;

  const RaceTicketsScreen({super.key, required this.race});

  @override
  State<RaceTicketsScreen> createState() => _RaceTicketsScreenState();
}

class _RaceTicketsScreenState extends State<RaceTicketsScreen> {
  static const _maxPerOrder = 10;

  late Future<List<RaceTicketCategory>> _future = _load();
  RaceTicketCategory? _selected;
  int _quantity = 1;
  bool _adding = false;

  Future<List<RaceTicketCategory>> _load() => RaceTicketCategoryProvider().getAll(filter: {'RaceID': widget.race.raceID});

  int get _maxQuantity => _selected == null ? 1 : (_selected!.available < _maxPerOrder ? _selected!.available : _maxPerOrder);

  Future<void> _addToCart() async {
    final category = _selected!;
    setState(() => _adding = true);
    try {
      await context.read<CartState>().add(category.raceTicketCategoryID, _quantity);
      if (!mounted) return;
      showSuccess(context, '$_quantity × ${category.ticketTypeName} for ${widget.race.raceName} added to your cart.');
      setState(() {
        _quantity = 1;
        _future = _load();
        _selected = null;
      });
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartState>().count;
    final race = widget.race;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        actions: [
          IconButton(
            tooltip: 'Cart',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
            icon: Badge(isLabelVisible: cartCount > 0, label: Text('$cartCount'), child: const Icon(Icons.shopping_cart_outlined)),
          ),
        ],
      ),
      body: FutureBuilder<List<RaceTicketCategory>>(
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
          final categories = snapshot.data;
          if (categories == null) return const LoadingView();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(race.raceName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('${race.circuitName ?? '-'} · ${formatDateTime(race.date)}', style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),
              if (categories.isEmpty) const EmptyView(message: 'Tickets for this race are not on sale yet.'),
              for (final c in categories)
                _CategoryTile(
                  category: c,
                  selected: _selected?.raceTicketCategoryID == c.raceTicketCategoryID,
                  onTap: () {
                    if (c.available == 0) return;
                    setState(() {
                      _selected = c;
                      _quantity = 1;
                    });
                  },
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: _selected == null
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                color: AppColors.carbon,
                child: Row(
                  children: [
                    IconButton.outlined(
                      tooltip: 'Fewer tickets',
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      icon: const Icon(Icons.remove),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton.outlined(
                      tooltip: 'More tickets',
                      onPressed: _quantity < _maxQuantity ? () => setState(() => _quantity++) : null,
                      icon: const Icon(Icons.add),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _adding ? null : _addToCart,
                        child: _adding
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('Add · ${formatMoney(_selected!.price * _quantity)}'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final RaceTicketCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final soldOut = category.available == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? AppColors.red : AppColors.outline, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: soldOut ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: soldOut ? AppColors.muted : AppColors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.ticketTypeName ?? '-', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      if (category.ticketTypeDescription != null)
                        Text(category.ticketTypeDescription!, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        soldOut ? 'Sold out' : '${category.available} seats left',
                        style: TextStyle(color: soldOut ? AppColors.red : AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Text(formatMoney(category.price), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
