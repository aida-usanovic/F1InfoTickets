import 'package:flutter/material.dart';

import '../feedback.dart';

export '../form_submit.dart';

/// Add/edit dialog: back arrow and X in the header, Cancel/Save at the bottom.
class FormDialog extends StatelessWidget {
  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final bool saving;
  final VoidCallback onSave;
  final String saveLabel;
  final double width;

  const FormDialog({
    super.key,
    required this.title,
    required this.formKey,
    required this.children,
    required this.saving,
    required this.onSave,
    this.saveLabel = 'Save',
    this.width = 560,
  });

  @override
  Widget build(BuildContext context) {
    void close() => Navigator.pop(context, false);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: 780),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DialogHeader(title: title, onClose: saving ? null : close),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: 16), children[i]],
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: saving ? null : close, child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: saving ? null : onSave,
                    icon: saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_outlined),
                    label: Text(saveLabel),
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

/// Dialog title row with "Nazad" on the left and "Zatvori" (X) on the right.
class DialogHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;

  const DialogHeader({super.key, required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back), onPressed: onClose),
          const SizedBox(width: 4),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
          ),
          IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: onClose),
        ],
      ),
    );
  }
}

/// Two form fields side by side.
class FormRow extends StatelessWidget {
  final List<Widget> children;

  const FormRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: 16), Expanded(child: children[i])],
      ],
    );
  }
}

/// Opens an add/edit dialog; returns true when the record was saved.
Future<bool> openFormDialog(BuildContext context, Widget dialog) async =>
    await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => dialog) ?? false;

/// Asks for confirmation and deletes a record. Returns true when it was deleted.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String name,
  required Future<void> Function() delete,
  required String successMessage,
}) async {
  final confirmed = await confirmAction(
    context,
    title: title,
    message: 'Are you sure you want to delete "$name"? This action cannot be undone.',
    confirmLabel: 'Delete',
    destructive: true,
  );
  if (!confirmed || !context.mounted) return false;
  try {
    await delete();
    if (context.mounted) showSuccess(context, successMessage);
    return true;
  } catch (e) {
    if (context.mounted) showError(context, e);
    return false;
  }
}
