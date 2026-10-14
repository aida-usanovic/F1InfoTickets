import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "F1 Info & Tickets" wordmark from the mockups.
class BrandLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const BrandLogo({super.key, this.size = 22, this.color});

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.5,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'F1 Info & ', style: base),
          TextSpan(
            text: 'Tickets',
            style: base.copyWith(color: AppColors.red),
          ),
        ],
      ),
      maxLines: 1,
    );
  }
}
