import 'package:flutter/material.dart';

import '../../api/providers.dart';
import '../../core/formatters.dart';
import '../../core/json.dart';
import '../../core/validators.dart';
import '../../models/driver.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_page.dart';
import '../../widgets/admin/async_dropdown.dart';
import '../../widgets/admin/crud.dart';
import '../../widgets/admin/image_pick_field.dart';
import '../../widgets/admin/paged_table.dart';
import '../../widgets/app_image.dart';
import '../../widgets/form_fields.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  final _table = PagedTableController();
  final _provider = DriverProvider();
  int? _seasonId;

  Future<void> _openForm([Driver? driver]) async {
    if (await openFormDialog(context, DriverFormDialog(driver: driver))) _table.reload();
  }

  Future<void> _delete(Driver driver) async {
    final deleted = await confirmDelete(
      context,
      title: 'Delete driver',
      name: driver.fullName,
      delete: () => _provider.delete(driver.driverID),
      successMessage: 'Driver ${driver.fullName} was deleted.',
    );
    if (deleted) _table.reload();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Drivers',
      subtitle: 'Drivers, their details and photos',
      child: PagedTable<Driver>(
        controller: _table,
        load: (query) => _provider.get(filter: {...query, 'SeasonId': _seasonId}),
        searchHint: 'Search by first or last name',
        emptyMessage: 'No drivers yet.',
        filters: [
          SizedBox(
            width: 220,
            child: AsyncDropdown(
              load: SeasonProvider().getAll,
              label: 'Raced in season',
              allLabel: 'All seasons',
              idOf: (s) => s.seasonID,
              labelOf: (s) => '${s.year}',
              onChanged: (s) {
                _seasonId = s?.seasonID;
                _table.reload(firstPage: true);
              },
            ),
          ),
        ],
        toolbarActions: [ElevatedButton.icon(onPressed: _openForm, icon: const Icon(Icons.add), label: const Text('Add driver'))],
        columns: [
          TableColumnDef('', (d) => AppImage(path: d.photoUrl, size: 40, circle: true, fallback: Icons.person)),
          TableColumnDef('Full name', (d) => Text(d.fullName, style: const TextStyle(fontWeight: FontWeight.w600))),
          TableColumnDef('No.', (d) => Text('#${d.number}'), numeric: true),
          TableColumnDef('Nationality', (d) => Text(d.nationality ?? '-')),
          TableColumnDef('Date of birth', (d) => Text(formatDate(d.birthDate))),
          TableColumnDef(
            'Status',
            (d) => d.isReserveDriver
                ? const StatusChip('Reserve', color: AppColors.warning)
                : const StatusChip('Regular', color: AppColors.success),
          ),
        ],
        actions: [
          RowAction('Edit', Icons.edit_outlined, _openForm),
          RowAction('Delete', Icons.delete_outline, _delete, color: AppColors.red),
        ],
      ),
    );
  }
}

class DriverFormDialog extends StatefulWidget {
  final Driver? driver;

  const DriverFormDialog({super.key, this.driver});

  @override
  State<DriverFormDialog> createState() => _DriverFormDialogState();
}

class _DriverFormDialogState extends State<DriverFormDialog> with CrudFormMixin {
  late final _firstName = TextEditingController(text: widget.driver?.firstName);
  late final _lastName = TextEditingController(text: widget.driver?.lastName);
  late final _number = TextEditingController(text: widget.driver?.number.toString());
  late int? _countryId = widget.driver?.countryID;
  late DateTime? _birthDate = widget.driver?.birthDate;
  late bool _isReserve = widget.driver?.isReserveDriver ?? false;
  String? _imagePath;

  bool get _isEdit => widget.driver != null;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _number.dispose();
    super.dispose();
  }

  Future<void> _save() => submit(() async {
    final saved = await DriverProvider().save(
      {
        'FirstName': _firstName.text.trim(),
        'LastName': _lastName.text.trim(),
        'Number': int.parse(_number.text.trim()),
        'CountryID': _countryId,
        'BirthDate': dateOnly(_birthDate!),
        'IsReserveDriver': _isReserve,
      },
      id: widget.driver?.driverID,
      imagePath: _imagePath,
    );
    return _isEdit ? 'Driver ${saved.fullName} was updated.' : 'Driver ${saved.fullName} was added.';
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return FormDialog(
      title: _isEdit ? 'Edit driver' : 'New driver',
      formKey: formKey,
      saving: saving,
      onSave: _save,
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
              controller: _number,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Racing number', hintText: '1 - 99'),
              validator: Validators.intRange('Racing number', 1, 99),
              forceErrorText: serverError('number'),
            ),
            AsyncDropdown(
              load: CountryProvider().getAll,
              label: 'Nationality',
              initialId: _countryId,
              idOf: (c) => c.countryID,
              labelOf: (c) => c.name,
              requiredMessage: "Select the driver's nationality.",
              forceErrorText: serverError('countryID'),
              onChanged: (c) => _countryId = c?.countryID,
            ),
          ],
        ),
        DateFormField(
          label: 'Date of birth',
          initialValue: _birthDate,
          firstDate: DateTime(1940),
          lastDate: DateTime(now.year - 16, now.month, now.day),
          initialPickerDate: DateTime(now.year - 25),
          validator: (v) => v == null ? 'Select the date of birth (the driver must be at least 16).' : null,
          forceErrorText: serverError('birthDate'),
          onChanged: (v) => _birthDate = v,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Reserve driver'),
          subtitle: const Text("Turn on if the driver is not part of a team's regular line-up."),
          value: _isReserve,
          onChanged: (v) => setState(() => _isReserve = v),
        ),
        ImagePickField(
          label: 'Photo',
          currentPath: widget.driver?.photoUrl,
          fallback: Icons.person,
          errorText: serverError('image'),
          onChanged: (path) => _imagePath = path,
        ),
      ],
    );
  }
}
