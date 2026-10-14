import 'package:flutter/material.dart';

import '../../api/providers.dart';
import '../../core/json.dart';
import '../../core/validators.dart';
import '../../models/user.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/form_submit.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with CrudFormMixin {
  late final _firstName = TextEditingController(text: widget.user.firstName);
  late final _lastName = TextEditingController(text: widget.user.lastName);
  late final _email = TextEditingController(text: widget.user.email);
  late final _phone = TextEditingController(text: widget.user.phone);
  late DateTime _birthDate = widget.user.birthDate;

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() => submit(() async {
    await ProfileProvider().update({
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'birthDate': dateOnly(_birthDate),
    });
    return 'Your profile was updated.';
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const gap = SizedBox(height: 14);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _firstName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'First name', prefixIcon: Icon(Icons.badge_outlined)),
              validator: Validators.required('First name', maxLength: 50),
              forceErrorText: serverError('firstName'),
            ),
            gap,
            TextFormField(
              controller: _lastName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Last name', prefixIcon: Icon(Icons.badge_outlined)),
              validator: Validators.required('Last name', maxLength: 50),
              forceErrorText: serverError('lastName'),
            ),
            gap,
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', hintText: 'name@domain.com', prefixIcon: Icon(Icons.email_outlined)),
              validator: Validators.email,
              forceErrorText: serverError('email'),
            ),
            gap,
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone', hintText: '+38761123456', prefixIcon: Icon(Icons.phone_outlined)),
              validator: Validators.phone,
              forceErrorText: serverError('phone'),
            ),
            gap,
            DateFormField(
              label: 'Date of birth',
              initialValue: _birthDate,
              firstDate: DateTime(1920),
              lastDate: DateTime(now.year - 16, now.month, now.day),
              validator: (v) => v == null ? 'Select your date of birth (at least 16 years old).' : null,
              forceErrorText: serverError('birthDate'),
              onChanged: (v) => _birthDate = v,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: saving ? null : _save,
              child: saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
