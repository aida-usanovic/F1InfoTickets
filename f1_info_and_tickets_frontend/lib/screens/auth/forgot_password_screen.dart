import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/validators.dart';
import '../../state/auth_state.dart';
import '../../widgets/feedback.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/form_submit.dart';

/// Forgotten password (mobile app): step 1 sends a one-time code to the email address,
/// step 2 sets a new password with that code.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with CrudFormMixin {
  final _emailFormKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _codeSent = false;
  bool _sending = false;

  @override
  void dispose() {
    for (final c in [_email, _code, _password, _confirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await context.read<AuthState>().requestPasswordReset(_email.text.trim());
      if (!mounted) return;
      setState(() => _codeSent = true);
      showSuccess(context, 'If ${_email.text.trim()} is registered, a 6-digit code was sent to it. It is valid for 15 minutes.');
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _reset() => submit(() async {
    await context.read<AuthState>().resetPassword({
      'email': _email.text.trim(),
      'code': _code.text.trim(),
      'newPassword': _password.text,
      'newPasswordConfirmation': _confirmation.text,
    });
    return 'Your password was reset. Sign in with the new password.';
  });

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Enter the email address of your account. We will send you a code for setting a new password.'),
          gap,
          Form(
            key: _emailFormKey,
            child: TextFormField(
              controller: _email,
              enabled: !_codeSent,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', hintText: 'name@domain.com', prefixIcon: Icon(Icons.email_outlined)),
              validator: Validators.email,
              forceErrorText: serverError('email'),
            ),
          ),
          gap,
          if (!_codeSent)
            ElevatedButton(
              onPressed: _sending ? null : _sendCode,
              child: _sending
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Send code'),
            )
          else
            Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Code from the email',
                      hintText: '6 digits',
                      prefixIcon: Icon(Icons.pin_outlined),
                    ),
                    validator: (v) => RegExp(r'^\d{6}$').hasMatch(v?.trim() ?? '') ? null : 'Enter the 6-digit code from the email.',
                    forceErrorText: serverError('code'),
                  ),
                  gap,
                  PasswordField(
                    controller: _password,
                    label: 'New password',
                    validator: Validators.password,
                    forceErrorText: serverError('newPassword'),
                  ),
                  gap,
                  PasswordField(
                    controller: _confirmation,
                    label: 'Confirm new password',
                    validator: Validators.matches(() => _password.text),
                    forceErrorText: serverError('newPasswordConfirmation'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: saving ? null : _reset,
                    child: saving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Set new password'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: saving || _sending ? null : _sendCode, child: const Text("Didn't get the code? Send a new one")),
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => setState(() {
                            _codeSent = false;
                            _code.clear();
                          }),
                    child: const Text('Use a different email'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
