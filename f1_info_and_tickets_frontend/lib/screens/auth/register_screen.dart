import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/json.dart';
import '../../core/validators.dart';
import '../../state/auth_state.dart';
import '../../widgets/feedback.dart';
import '../../widgets/form_fields.dart';

/// Customer registration (mobile app).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _minimumAge = 16;

  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();
  DateTime? _birthDate;
  Map<String, String> _serverErrors = {};
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _phone, _username, _password, _passwordConfirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime get _latestBirthDate {
    final now = DateTime.now();
    return DateTime(now.year - _minimumAge, now.month, now.day);
  }

  Future<void> _submit() async {
    if (_serverErrors.isNotEmpty) {
      // Fields with a server error keep failing validation until they are rebuilt without it.
      setState(() => _serverErrors = {});
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await context.read<AuthState>().register({
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'username': _username.text.trim(),
        'birthDate': dateOnly(_birthDate!),
        'password': _password.text,
        'passwordConfirmation': _passwordConfirmation.text,
      });
      if (!mounted) return;
      final username = _username.text.trim();
      _formKey.currentState!.reset();
      showSuccess(context, 'Registration successful. Sign in as "$username".');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.fieldErrors.isNotEmpty) {
        setState(() => _serverErrors = e.fieldErrors);
      } else {
        showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return Scaffold(
      appBar: AppBar(title: const Text('Registration')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _firstName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'First name', prefixIcon: Icon(Icons.badge_outlined)),
                validator: Validators.required('First name', maxLength: 50),
                forceErrorText: _serverErrors['firstName'],
              ),
              gap,
              TextFormField(
                controller: _lastName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Last name', prefixIcon: Icon(Icons.badge_outlined)),
                validator: Validators.required('Last name', maxLength: 50),
                forceErrorText: _serverErrors['lastName'],
              ),
              gap,
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', hintText: 'name@domain.com', prefixIcon: Icon(Icons.email_outlined)),
                validator: Validators.email,
                forceErrorText: _serverErrors['email'],
              ),
              gap,
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone', hintText: '+38761123456', prefixIcon: Icon(Icons.phone_outlined)),
                validator: Validators.phone,
                forceErrorText: _serverErrors['phone'],
              ),
              gap,
              DateFormField(
                label: 'Date of birth',
                firstDate: DateTime(1920),
                lastDate: _latestBirthDate,
                initialPickerDate: DateTime(DateTime.now().year - 25),
                validator: (value) => value == null ? 'Select your date of birth (at least $_minimumAge years old).' : null,
                forceErrorText: _serverErrors['birthDate'],
                onChanged: (value) => _birthDate = value,
              ),
              gap,
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
                validator: Validators.username,
                forceErrorText: _serverErrors['username'],
              ),
              gap,
              PasswordField(
                controller: _password,
                label: 'Password',
                validator: Validators.password,
                forceErrorText: _serverErrors['password'],
              ),
              gap,
              PasswordField(
                controller: _passwordConfirmation,
                label: 'Confirm password',
                validator: Validators.matches(() => _password.text),
                forceErrorText: _serverErrors['passwordConfirmation'],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
