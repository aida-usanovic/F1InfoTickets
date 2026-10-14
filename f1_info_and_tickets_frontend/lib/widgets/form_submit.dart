import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import 'feedback.dart';

/// Shared save logic for forms shown as a dialog or a page.
mixin CrudFormMixin<W extends StatefulWidget> on State<W> {
  final formKey = GlobalKey<FormState>();
  Map<String, String> serverErrors = {};
  bool saving = false;

  String? serverError(String field) => serverErrors[field];

  /// Validates the form, runs [save] (which returns the success message) and closes the dialog or page with `true`.
  /// API validation errors are shown under the matching fields.
  Future<void> submit(Future<String> Function() save) async {
    if (serverErrors.isNotEmpty) {
      // Fields with a server error keep failing validation until they are rebuilt without it.
      setState(() => serverErrors = {});
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    if (!formKey.currentState!.validate()) return;

    setState(() => saving = true);
    try {
      final message = await save();
      if (!mounted) return;
      showSuccess(context, message);
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.fieldErrors.isNotEmpty) setState(() => serverErrors = e.fieldErrors);
      showError(context, e);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
