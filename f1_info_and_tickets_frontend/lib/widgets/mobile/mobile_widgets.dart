import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../models/race.dart';
import '../../theme/app_theme.dart';

/// One detail line: icon, label on the left and value on the right.
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow(this.icon, this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.red),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card that groups [InfoRow]s under a title.
class InfoCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const InfoCard({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(title!, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? action;

  const SectionTitle(this.title, {super.key, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
      child: Row(
        children: [
          Container(width: 4, height: 18, color: AppColors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Small statistic: big value with a label underneath.
class StatTile extends StatelessWidget {
  final String label;
  final String value;

  const StatTile(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid of [StatTile]s, three per row.
class StatGrid extends StatelessWidget {
  final List<StatTile> tiles;

  const StatGrid(this.tiles, {super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: tiles,
    );
  }
}

/// Standings position; the podium places are gold, silver and bronze.
class PositionBadge extends StatelessWidget {
  final int position;

  const PositionBadge(this.position, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = switch (position) {
      1 => AppColors.gold,
      2 => AppColors.silver,
      3 => AppColors.bronze,
      _ => AppColors.carbonLight,
    };
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(
        '$position',
        style: TextStyle(fontWeight: FontWeight.w800, color: position <= 3 ? AppColors.ink : Colors.white),
      ),
    );
  }
}

/// Race summary used in the race, ticket and recommendation lists.
class RaceCard extends StatelessWidget {
  final Race race;
  final VoidCallback onTap;
  final bool showPrice;

  /// Opens the purchase with the recommended ticket type; the offer is shown only when this is set.
  final VoidCallback? onRecommendedTicketTap;

  const RaceCard({super.key, required this.race, required this.onTap, this.showPrice = false, this.onRecommendedTicketTap});

  @override
  Widget build(BuildContext context) {
    final price = race.minTicketPrice;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: race.isUpcoming ? AppColors.red : AppColors.carbonLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      '${race.date.day}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    Text(
                      formatShortDate(race.date).split(' ').last.toUpperCase(),
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(race.raceName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text('${race.circuitName ?? '-'} · ${race.location ?? '-'}', style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Tag(Icons.loop, '${race.laps} laps'),
                        _Tag(Icons.straighten, formatKm(race.circuitLength)),
                        if (showPrice)
                          _Tag(Icons.confirmation_number_outlined, price == null ? 'Not on sale yet' : 'From ${formatMoney(price)}'),
                      ],
                    ),
                    if (race.recommendationReason != null) ...[
                      const SizedBox(height: 6),
                      Text(race.recommendationReason!, style: const TextStyle(fontSize: 12, color: AppColors.gold)),
                    ],
                    if (race.recommendedTicketType != null && onRecommendedTicketTap != null) ...[
                      const SizedBox(height: 8),
                      _RecommendedTicket(race: race, onTap: onRecommendedTicketTap!),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// The ticket type the user buys most often, offered with a recommended race.
class _RecommendedTicket extends StatelessWidget {
  final Race race;
  final VoidCallback onTap;

  const _RecommendedTicket({required this.race, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.red),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_seat, size: 18, color: AppColors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your usual ticket', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  Text(
                    '${race.recommendedTicketType} · ${formatMoney(race.recommendedTicketPrice)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const Text(
              'Buy',
              style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Tag(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.carbonLight, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.muted),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

/// Search box used above the mobile lists.
class SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const SearchField({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(hintText: hint, prefixIcon: const Icon(Icons.search), isDense: true),
    );
  }
}
