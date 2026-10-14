import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/providers.dart';
import '../../core/formatters.dart';
import '../../core/json.dart';
import '../../core/validators.dart';
import '../../models/user.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_page.dart';
import '../../widgets/admin/async_dropdown.dart';
import '../../widgets/admin/crud.dart';
import '../../widgets/admin/paged_table.dart';
import '../../widgets/form_fields.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _table = PagedTableController();
  final _provider = UserProvider();
  int? _roleId;

  Future<void> _openForm([User? user]) async {
    if (await openFormDialog(context, UserFormDialog(user: user))) _table.reload();
  }

  Future<void> _delete(User user) async {
    final deleted = await confirmDelete(
      context,
      title: 'Delete user',
      name: '${user.fullName} (${user.username})',
      delete: () => _provider.delete(user.userID),
      successMessage: 'User ${user.username} was deleted.',
    );
    if (deleted) _table.reload();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthState>().userId;
    return AdminPage(
      title: 'Users',
      subtitle: 'User accounts and roles',
      child: PagedTable<User>(
        controller: _table,
        load: (query) => _provider.get(filter: {...query, 'RoleID': _roleId}),
        searchHint: 'Search by name, username or email',
        emptyMessage: 'No users.',
        filters: [
          SizedBox(
            width: 200,
            child: AsyncDropdown(
              load: RoleProvider().getAll,
              label: 'Role',
              allLabel: 'All roles',
              idOf: (r) => r.roleID,
              labelOf: (r) => r.name,
              onChanged: (r) {
                _roleId = r?.roleID;
                _table.reload(firstPage: true);
              },
            ),
          ),
        ],
        toolbarActions: [ElevatedButton.icon(onPressed: _openForm, icon: const Icon(Icons.person_add_alt), label: const Text('Add user'))],
        columns: [
          TableColumnDef(
            'User',
            (u) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.carbonLight,
                  child: Text(u.initials, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(width: 10),
                TwoLineCell(u.fullName, u.username),
              ],
            ),
          ),
          TableColumnDef('Email', (u) => Text(u.email)),
          TableColumnDef('Phone', (u) => Text(u.phone)),
          TableColumnDef('Date of birth', (u) => Text(formatDate(u.birthDate))),
          TableColumnDef(
            'Role',
            (u) => StatusChip(u.roleName ?? '-', color: u.roleName == 'Admin' ? AppColors.red : AppColors.carbonLight),
          ),
        ],
        actions: [
          RowAction('Edit', Icons.edit_outlined, _openForm),
          RowAction('Delete', Icons.delete_outline, _delete, color: AppColors.red, isEnabled: (u) => u.userID != currentUserId),
        ],
      ),
    );
  }
}

/// Admin add/edit of a user. When editing, the password is optional and the old one is not needed.
class UserFormDialog extends StatefulWidget {
  final User? user;

  const UserFormDialog({super.key, this.user});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> with CrudFormMixin {
  late final _firstName = TextEditingController(text: widget.user?.firstName);
  late final _lastName = TextEditingController(text: widget.user?.lastName);
  late final _email = TextEditingController(text: widget.user?.email);
  late final _phone = TextEditingController(text: widget.user?.phone);
  late final _username = TextEditingController(text: widget.user?.username);
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();
  late DateTime? _birthDate = widget.user?.birthDate;
  late int? _roleId = widget.user?.roleID;

  bool get _isEdit => widget.user != null;

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _phone, _username, _password, _passwordConfirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() => submit(() async {
    final passwordChanged = _password.text.isNotEmpty;
    final request = {
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'username': _username.text.trim(),
      'birthDate': dateOnly(_birthDate!),
      'roleID': _roleId,
      'password': passwordChanged ? _password.text : null,
      'passwordConfirmation': passwordChanged ? _passwordConfirmation.text : null,
    };
    final provider = UserProvider();
    if (!_isEdit) {
      final saved = await provider.insert(request);
      return 'User ${saved.username} was added with the ${saved.roleName ?? ''} role.';
    }
    final saved = await provider.update(widget.user!.userID, request);
    return passwordChanged ? 'User ${saved.username} was updated and the password was changed.' : 'User ${saved.username} was updated.';
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return FormDialog(
      title: _isEdit ? 'Edit user' : 'New user',
      formKey: formKey,
      saving: saving,
      onSave: _save,
      width: 640,
      children: [
        FormRow(
          children: [
            TextFormField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: 'First name'),
              validator: Validators.required('First name', maxLength: 50),
              forceErrorText: serverError('firstName'),
            ),
            TextFormField(
              controller: _lastName,
              decoration: const InputDecoration(labelText: 'Last name'),
              validator: Validators.required('Last name', maxLength: 50),
              forceErrorText: serverError('lastName'),
            ),
          ],
        ),
        FormRow(
          children: [
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email', hintText: 'name@domain.com'),
              validator: Validators.email,
              forceErrorText: serverError('email'),
            ),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone', hintText: '+38761123456'),
              validator: Validators.phone,
              forceErrorText: serverError('phone'),
            ),
          ],
        ),
        FormRow(
          children: [
            TextFormField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'Username'),
              validator: Validators.username,
              forceErrorText: serverError('username'),
            ),
            AsyncDropdown(
              load: RoleProvider().getAll,
              label: 'Role',
              initialId: _roleId,
              idOf: (r) => r.roleID,
              labelOf: (r) => r.name,
              requiredMessage: "Select the user's role.",
              forceErrorText: serverError('roleID'),
              onChanged: (r) => _roleId = r?.roleID,
            ),
          ],
        ),
        DateFormField(
          label: 'Date of birth',
          initialValue: _birthDate,
          firstDate: DateTime(1920),
          lastDate: DateTime(now.year - 16, now.month, now.day),
          initialPickerDate: DateTime(now.year - 25),
          validator: (v) => v == null ? 'Select the date of birth (at least 16 years old).' : null,
          forceErrorText: serverError('birthDate'),
          onChanged: (v) => _birthDate = v,
        ),
        if (_isEdit) Text('Leave the password fields empty to keep the current password.', style: TextStyle(color: Colors.grey.shade700)),
        FormRow(
          children: [
            PasswordField(
              controller: _password,
              label: _isEdit ? 'New password' : 'Password',
              validator: _isEdit ? Validators.optionalPassword : Validators.password,
              forceErrorText: serverError('password'),
            ),
            PasswordField(
              controller: _passwordConfirmation,
              label: 'Confirm password',
              validator: Validators.matches(() => _password.text),
              forceErrorText: serverError('passwordConfirmation'),
            ),
          ],
        ),
      ],
    );
  }
}
