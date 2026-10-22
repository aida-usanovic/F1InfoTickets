import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../api/providers.dart';
import '../../core/api_exception.dart';
import '../../core/json.dart';
import '../../core/validators.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feedback.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/form_submit.dart';
import '../../widgets/mobile/profile_avatar.dart';

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

  static const _maxImageBytes = 5 * 1024 * 1024;

  /// Newly picked photo; null keeps the current one.
  String? _imagePath;

  Future<void> _pickPhoto() async {
    const types = XTypeGroup(label: 'Images', extensions: ['jpg', 'jpeg', 'png'], mimeTypes: ['image/jpeg', 'image/png']);
    final file = await openFile(acceptedTypeGroups: [types]);
    if (file == null || !mounted) return;
    if (await File(file.path).length() > _maxImageBytes) {
      if (mounted) showError(context, ApiException('The image is too large. Select an image up to 5 MB.'));
      return;
    }
    setState(() => _imagePath = file.path);
  }

  Future<void> _save() => submit(() async {
    await ProfileProvider().update({
      'FirstName': _firstName.text.trim(),
      'LastName': _lastName.text.trim(),
      'Email': _email.text.trim(),
      'Phone': _phone.text.trim(),
      'BirthDate': dateOnly(_birthDate),
    }, imagePath: _imagePath);
    return _imagePath == null ? 'Your profile was updated.' : 'Your profile and photo were updated.';
  });

  /// Current photo and, after picking, the new one next to it.
  Widget _buildPhoto() {
    Widget labelled(String label, Widget avatar) => Column(
      children: [
        avatar,
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      ],
    );
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            labelled('Current photo', ProfileAvatar(user: widget.user, radius: 44)),
            if (_imagePath != null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.arrow_forward, color: AppColors.muted),
              ),
              labelled('New photo', ProfileAvatar(user: widget.user, radius: 44, filePath: _imagePath)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: saving ? null : _pickPhoto,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(widget.user.photoUrl == null && _imagePath == null ? 'Add photo' : 'Choose another photo'),
            ),
            if (_imagePath != null)
              TextButton(onPressed: saving ? null : () => setState(() => _imagePath = null), child: const Text('Keep current photo')),
          ],
        ),
        const Text('JPG or PNG, up to 5 MB.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
        if (serverError('image') != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(serverError('image')!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
          ),
      ],
    );
  }

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
            _buildPhoto(),
            const SizedBox(height: 20),
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
