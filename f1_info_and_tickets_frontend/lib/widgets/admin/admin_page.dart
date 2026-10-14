import 'package:flutter/material.dart';

/// Content area of an admin section: title bar (with optional tabs) and padded body.
class AdminPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? bottom;
  final Widget child;

  const AdminPage({super.key, required this.title, this.subtitle, this.actions = const [], this.bottom, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(28, 22, 28, bottom == null ? 22 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                        ],
                      ],
                    ),
                  ),
                  for (final action in actions) Padding(padding: const EdgeInsets.only(left: 12), child: action),
                ],
              ),
              if (bottom != null) ...[const SizedBox(height: 12), bottom!],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Padding(padding: const EdgeInsets.all(24), child: child),
        ),
      ],
    );
  }
}

/// Small coloured label (status, role, ticket state...).
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip(this.label, {super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

/// Text with a smaller grey second line, used in table cells.
class TwoLineCell extends StatelessWidget {
  final String title;
  final String? subtitle;

  const TwoLineCell(this.title, this.subtitle, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        if (subtitle != null && subtitle!.isNotEmpty) Text(subtitle!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}
