import 'package:flutter/material.dart';

import '../../api/providers.dart';
import '../../core/validators.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/form_submit.dart';

/// Changing your own password requires the current one.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> with CrudFormMixin {
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    for (final c in [_oldPassword, _newPassword, _confirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() => submit(() async {
    await ProfileProvider().changePassword({
      'oldPassword': _oldPassword.text,
      'newPassword': _newPassword.text,
      'newPasswordConfirmation': _confirmation.text,
    });
    return 'Your password was changed.';
  });

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PasswordField(
              controller: _oldPassword,
              label: 'Current password',
              validator: (v) => (v ?? '').isEmpty ? 'Enter your current password.' : null,
              forceErrorText: serverError('oldPassword'),
            ),
            gap,
            PasswordField(
              controller: _newPassword,
              label: 'New password',
              validator: Validators.password,
              forceErrorText: serverError('newPassword'),
            ),
            gap,
            PasswordField(
              controller: _confirmation,
              label: 'Confirm new password',
              validator: Validators.matches(() => _newPassword.text),
              forceErrorText: serverError('newPasswordConfirmation'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: saving ? null : _save,
              child: saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Change password'),
            ),
          ],
        ),
      ),
    );
  }
}
