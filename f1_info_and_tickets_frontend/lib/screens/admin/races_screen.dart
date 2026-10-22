import 'package:flutter/material.dart';

import '../../api/providers.dart';
import '../../core/formatters.dart';
import '../../core/validators.dart';
import '../../models/circuit.dart';
import '../../models/race.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_page.dart';
import '../../widgets/admin/async_dropdown.dart';
import '../../widgets/admin/crud.dart';
import '../../widgets/admin/paged_table.dart';
import '../../widgets/form_fields.dart';

class RacesScreen extends StatefulWidget {
  const RacesScreen({super.key});

  @override
  State<RacesScreen> createState() => _RacesScreenState();
}

class _RacesScreenState extends State<RacesScreen> {
  final _table = PagedTableController();
  final _provider = RaceProvider();
  int? _seasonId;
  bool? _upcoming;

  Future<void> _openForm([Race? race]) async {
    if (await openFormDialog(context, RaceFormDialog(race: race))) _table.reload();
  }

  Future<void> _delete(Race race) async {
    final deleted = await confirmDelete(
      context,
      title: 'Delete race',
      name: race.raceName,
      delete: () => _provider.delete(race.raceID),
      successMessage: 'Race ${race.raceName} was deleted.',
    );
    if (deleted) _table.reload();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Races',
      subtitle: 'Race calendar by season and circuit',
      child: PagedTable<Race>(
        controller: _table,
        load: (query) => _provider.get(filter: {...query, 'SeasonID': _seasonId, 'Upcoming': _upcoming}),
        searchHint: 'Search by name, circuit, city or country',
        emptyMessage: 'No races yet.',
        filters: [
          SizedBox(
            width: 180,
            child: AsyncDropdown(
              load: SeasonProvider().getAll,
              label: 'Season',
              allLabel: 'All seasons',
              idOf: (s) => s.seasonID,
              labelOf: (s) => '${s.year}',
              onChanged: (s) {
                _seasonId = s?.seasonID;
                _table.reload(firstPage: true);
              },
            ),
          ),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<bool?>(
              initialValue: null,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All races')),
                DropdownMenuItem(value: true, child: Text('Upcoming')),
                DropdownMenuItem(value: false, child: Text('Finished')),
              ],
              onChanged: (v) {
                _upcoming = v;
                _table.reload(firstPage: true);
              },
            ),
          ),
        ],
        toolbarActions: [ElevatedButton.icon(onPressed: _openForm, icon: const Icon(Icons.add), label: const Text('Add race'))],
        columns: [
          TableColumnDef('Race', (r) => TwoLineCell(r.raceName, r.circuitName)),
          TableColumnDef('Date and time', (r) => Text(formatDateTime(r.date))),
          TableColumnDef('Location', (r) => Text(r.location ?? '-')),
          TableColumnDef('Track type', (r) => Text(r.trackType ?? '-')),
          TableColumnDef('Laps', (r) => Text('${r.laps}'), numeric: true),
          TableColumnDef('Lap length', (r) => Text(formatKm(r.circuitLength)), numeric: true),
          TableColumnDef(
            'Status',
            (r) => r.isUpcoming ? const StatusChip('Upcoming', color: AppColors.success) : const StatusChip('Finished', color: Colors.grey),
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

class RaceFormDialog extends StatefulWidget {
  final Race? race;

  const RaceFormDialog({super.key, this.race});

  @override
  State<RaceFormDialog> createState() => _RaceFormDialogState();
}

class _RaceFormDialogState extends State<RaceFormDialog> with CrudFormMixin {
  late final _name = TextEditingController(text: widget.race?.raceName);
  late int? _circuitId = widget.race?.circuitID;
  late DateTime? _date = widget.race?.date;
  Circuit? _circuit;

  bool get _isEdit => widget.race != null;

  /// With results entered, the race must stay a finished race of its season (the server checks the same).
  bool get _dateLocked => widget.race?.hasResults ?? false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() => submit(() async {
    final request = {'raceName': _name.text.trim(), 'circuitID': _circuitId, 'date': _date!.toUtc().toIso8601String()};
    final provider = RaceProvider();
    final saved = _isEdit ? await provider.update(widget.race!.raceID, request) : await provider.insert(request);
    return _isEdit ? 'Race ${saved.raceName} was updated.' : 'Race ${saved.raceName} (${formatDate(saved.date)}) was added.';
  });

  static DateTime _lastAllowedDate(Race race) {
    final now = DateTime.now();
    final seasonEnd = DateTime(race.date.year, 12, 31);
    return now.isBefore(seasonEnd) ? now : seasonEnd;
  }

  @override
  Widget build(BuildContext context) {
    final race = widget.race;
    final info = _circuit != null
        ? '${_circuit!.location} · ${_circuit!.trackTypeName ?? '-'} · ${_circuit!.laps} laps · ${formatKm(_circuit!.lengthKm)}'
        : race != null
        ? '${race.location ?? '-'} · ${race.trackType ?? '-'} · ${race.laps} laps · ${formatKm(race.circuitLength)}'
        : null;
    return FormDialog(
      title: _isEdit ? 'Edit race' : 'New race',
      formKey: formKey,
      saving: saving,
      onSave: _save,
      children: [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Race name', hintText: 'e.g. Italian Grand Prix'),
          validator: Validators.required('Race name', maxLength: 150),
          forceErrorText: serverError('raceName'),
        ),
        AsyncDropdown(
          load: CircuitProvider().getAll,
          label: 'Circuit',
          initialId: _circuitId,
          idOf: (c) => c.circuitID,
          labelOf: (c) => '${c.name} (${c.countryName ?? '-'})',
          requiredMessage: 'Select the circuit of the race.',
          forceErrorText: serverError('circuitID'),
          onChanged: (c) => setState(() {
            _circuitId = c?.circuitID;
            _circuit = c;
          }),
        ),
        if (info != null) Text('Circuit: $info. Laps and lap length come from the circuit.', style: TextStyle(color: Colors.grey.shade700)),
        DateTimeFormField(
          label: 'Start date and time (local time)',
          initialValue: _date,
          firstDate: _dateLocked ? DateTime(race!.date.year) : DateTime(2000),
          lastDate: _dateLocked ? _lastAllowedDate(race!) : DateTime(DateTime.now().year + 3, 12, 31),
          validator: (v) {
            if (v == null) return 'Select the race start date and time.';
            if (_dateLocked && v.year != race!.date.year) return 'The race must stay in the ${race.date.year} season.';
            if (_dateLocked && v.isAfter(DateTime.now())) return 'A race with results cannot be moved into the future.';
            return null;
          },
          forceErrorText: serverError('date'),
          onChanged: (v) => _date = v,
        ),
        if (_dateLocked)
          Text(
            'Results are entered for this race, so its date can only be corrected within the ${race!.date.year} season and not into the future.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
      ],
    );
  }
}
