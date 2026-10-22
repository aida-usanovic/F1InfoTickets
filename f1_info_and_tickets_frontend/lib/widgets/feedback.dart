import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../theme/app_theme.dart';

void showSuccess(BuildContext context, String message) => _showSnack(context, Icons.check_circle, message, AppColors.success);

/// Neutral message, e.g. when the user cancels something and nothing changed.
void showInfo(BuildContext context, String message) => _showSnack(context, Icons.info_outline, message, AppColors.carbonLight);

void showError(BuildContext context, Object error) =>
    _showSnack(context, Icons.error_outline, errorMessage(error), AppColors.redDark, duration: const Duration(seconds: 5));

void _showSnack(BuildContext context, IconData icon, String message, Color background, {Duration duration = const Duration(seconds: 4)}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            // The default snackbar text colour is meant for the theme's own background, so it is set explicitly.
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: background,
        duration: duration,
      ),
    );
}

/// Asks before irreversible actions (delete, order, logout...). Returns true when the user confirms.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(destructive ? Icons.warning_amber_rounded : Icons.help_outline, color: destructive ? AppColors.red : null, size: 36),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          style: destructive ? ElevatedButton.styleFrom(backgroundColor: AppColors.red) : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
