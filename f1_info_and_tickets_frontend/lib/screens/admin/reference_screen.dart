import 'package:flutter/material.dart';

import '../../api/base_provider.dart';
import '../../api/providers.dart';
import '../../core/formatters.dart';
import '../../core/validators.dart';
import '../../models/circuit.dart';
import '../../models/reference.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_page.dart';
import '../../widgets/admin/async_dropdown.dart';
import '../../widgets/admin/crud.dart';
import '../../widgets/admin/paged_table.dart';

/// Code tables (šifarnici): seasons, circuits, geography, track and ticket types, roles.
class ReferenceScreen extends StatelessWidget {
  const ReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 8,
      child: AdminPage(
        title: 'Reference data',
        subtitle: 'Lookup data used by the other forms',
        bottom: const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'Seasons'),
            Tab(text: 'Circuits'),
            Tab(text: 'Continents'),
            Tab(text: 'Countries'),
            Tab(text: 'Cities'),
            Tab(text: 'Track types'),
            Tab(text: 'Ticket types'),
            Tab(text: 'Roles'),
          ],
        ),
        child: TabBarView(
          children: [
            _ReferenceTab<Season>(
              provider: SeasonProvider(),
              entity: 'Season',
              searchHint: 'Search by year or description',
              idOf: (s) => s.seasonID,
              nameOf: (s) => '${s.year}',
              columns: [
                TableColumnDef('Year', (s) => Text('${s.year}', style: const TextStyle(fontWeight: FontWeight.w600))),
                TableColumnDef('Description', (s) => Text(s.description)),
              ],
              form: (s) => _SeasonForm(season: s),
            ),
            _ReferenceTab<Circuit>(
              provider: CircuitProvider(),
              entity: 'Circuit',
              searchHint: 'Search by name, city or country',
              idOf: (c) => c.circuitID,
              nameOf: (c) => c.name,
              filters: (setFilter) => [
                _filterDropdown<TrackType>(
                  label: 'Track type',
                  allLabel: 'All types',
                  load: TrackTypeProvider().getAll,
                  idOf: (t) => t.trackTypeID,
                  labelOf: (t) => t.name,
                  onChanged: (id) => setFilter('TrackTypeID', id),
                ),
              ],
              columns: [
                TableColumnDef('Name', (c) => Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                TableColumnDef('Location', (c) => Text(c.location)),
                TableColumnDef('Continent', (c) => Text(c.continentName ?? '-')),
                TableColumnDef('Track type', (c) => Text(c.trackTypeName ?? '-')),
                TableColumnDef('Laps', (c) => Text('${c.laps}'), numeric: true),
                TableColumnDef('Lap length', (c) => Text(formatKm(c.lengthKm)), numeric: true),
              ],
              form: (c) => _CircuitForm(circuit: c),
            ),
            _ReferenceTab<Continent>(
              provider: ContinentProvider(),
              entity: 'Continent',
              searchHint: 'Search by name',
              idOf: (c) => c.continentID,
              nameOf: (c) => c.name,
              columns: [TableColumnDef('Name', (c) => Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)))],
              form: (c) => _NameForm(entity: 'Continent', provider: ContinentProvider(), id: c?.continentID, name: c?.name, maxLength: 50),
            ),
            _ReferenceTab<Country>(
              provider: CountryProvider(),
              entity: 'Country',
              searchHint: 'Search by name or code',
              idOf: (c) => c.countryID,
              nameOf: (c) => c.name,
              filters: (setFilter) => [
                _filterDropdown<Continent>(
                  label: 'Continent',
                  allLabel: 'All continents',
                  load: ContinentProvider().getAll,
                  idOf: (c) => c.continentID,
                  labelOf: (c) => c.name,
                  onChanged: (id) => setFilter('ContinentID', id),
                ),
              ],
              columns: [
                TableColumnDef('Name', (c) => Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                TableColumnDef('Code', (c) => Text(c.code)),
                TableColumnDef('Continent', (c) => Text(c.continentName ?? '-')),
              ],
              form: (c) => _CountryForm(country: c),
            ),
            _ReferenceTab<City>(
              provider: CityProvider(),
              entity: 'City',
              searchHint: 'Search by city or country',
              idOf: (c) => c.cityID,
              nameOf: (c) => c.name,
              filters: (setFilter) => [
                _filterDropdown<Country>(
                  label: 'Country',
                  allLabel: 'All countries',
                  load: CountryProvider().getAll,
                  idOf: (c) => c.countryID,
                  labelOf: (c) => c.name,
                  onChanged: (id) => setFilter('CountryID', id),
                ),
              ],
              columns: [
                TableColumnDef('Name', (c) => Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                TableColumnDef('Country', (c) => Text(c.countryName ?? '-')),
              ],
              form: (c) => _CityForm(city: c),
            ),
            _ReferenceTab<TrackType>(
              provider: TrackTypeProvider(),
              entity: 'Track type',
              searchHint: 'Search by name',
              idOf: (t) => t.trackTypeID,
              nameOf: (t) => t.name,
              columns: [
                TableColumnDef('Name', (t) => Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                TableColumnDef('Description', (t) => _Description(t.description)),
              ],
              form: (t) => _NameForm(
                entity: 'Track type',
                provider: TrackTypeProvider(),
                id: t?.trackTypeID,
                name: t?.name,
                description: t?.description,
                hasDescription: true,
                maxLength: 50,
              ),
            ),
            _ReferenceTab<TicketType>(
              provider: TicketTypeProvider(),
              entity: 'Ticket type',
              searchHint: 'Search by name',
              idOf: (t) => t.ticketTypeID,
              nameOf: (t) => t.name,
              columns: [
                TableColumnDef('Name', (t) => Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                TableColumnDef('Description', (t) => _Description(t.description)),
              ],
              form: (t) => _NameForm(
                entity: 'Ticket type',
                provider: TicketTypeProvider(),
                id: t?.ticketTypeID,
                name: t?.name,
                description: t?.description,
                hasDescription: true,
                maxLength: 50,
              ),
            ),
            _ReferenceTab<Role>(
              provider: RoleProvider(),
              entity: 'Role',
              searchHint: 'Search by name',
              idOf: (r) => r.roleID,
              nameOf: (r) => r.name,
              // Admin and User are used by the login rules and cannot be changed.
              canModify: (r) => !r.isSystemRole,
              columns: [
                TableColumnDef('Name', (r) => Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                TableColumnDef(
                  'Kind',
                  (r) => r.isSystemRole
                      ? const StatusChip('System', color: AppColors.carbonLight)
                      : const StatusChip('Custom', color: AppColors.success),
                ),
              ],
              form: (r) => _NameForm(entity: 'Role', provider: RoleProvider(), id: r?.roleID, name: r?.name, maxLength: 50),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _filterDropdown<T>({
  required String label,
  required String allLabel,
  required Future<List<T>> Function() load,
  required int Function(T) idOf,
  required String Function(T) labelOf,
  required ValueChanged<int?> onChanged,
}) {
  return SizedBox(
    width: 220,
    child: AsyncDropdown<T>(
      load: load,
      label: label,
      allLabel: allLabel,
      idOf: idOf,
      labelOf: labelOf,
      onChanged: (item) => onChanged(item == null ? null : idOf(item)),
    ),
  );
}

class _Description extends StatelessWidget {
  final String? text;

  const _Description(this.text);

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 520),
    child: Text(text == null || text!.isEmpty ? '-' : text!, maxLines: 2, overflow: TextOverflow.ellipsis),
  );
}

/// List + add/edit/delete for one code table.
class _ReferenceTab<T> extends StatefulWidget {
  final BaseProvider<T> provider;
  final String entity;
  final String searchHint;
  final int Function(T) idOf;
  final String Function(T) nameOf;
  final List<TableColumnDef<T>> columns;
  final Widget Function(T? item) form;
  final List<Widget> Function(void Function(String key, Object? value) setFilter)? filters;
  final bool Function(T)? canModify;

  const _ReferenceTab({
    required this.provider,
    required this.entity,
    required this.searchHint,
    required this.idOf,
    required this.nameOf,
    required this.columns,
    required this.form,
    this.filters,
    this.canModify,
  });

  @override
  State<_ReferenceTab<T>> createState() => _ReferenceTabState<T>();
}

class _ReferenceTabState<T> extends State<_ReferenceTab<T>> with AutomaticKeepAliveClientMixin {
  final _table = PagedTableController();
  final Map<String, Object?> _filter = {};

  @override
  bool get wantKeepAlive => true;

  void _setFilter(String key, Object? value) {
    _filter[key] = value;
    _table.reload(firstPage: true);
  }

  Future<void> _openForm([T? item]) async {
    if (await openFormDialog(context, widget.form(item))) _table.reload();
  }

  Future<void> _delete(T item) async {
    final name = widget.nameOf(item);
    final deleted = await confirmDelete(
      context,
      title: 'Delete ${widget.entity.toLowerCase()}',
      name: name,
      delete: () => widget.provider.delete(widget.idOf(item)),
      successMessage: '${widget.entity} "$name" was deleted.',
    );
    if (deleted) _table.reload();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PagedTable<T>(
      controller: _table,
      load: (query) => widget.provider.get(filter: {...query, ..._filter}),
      searchHint: widget.searchHint,
      emptyMessage: 'No records yet.',
      filters: widget.filters?.call(_setFilter) ?? const [],
      toolbarActions: [
        ElevatedButton.icon(onPressed: _openForm, icon: const Icon(Icons.add), label: Text('Add ${widget.entity.toLowerCase()}')),
      ],
      columns: widget.columns,
      actions: [
        RowAction('Edit', Icons.edit_outlined, _openForm, isEnabled: widget.canModify),
        RowAction('Delete', Icons.delete_outline, _delete, color: AppColors.red, isEnabled: widget.canModify),
      ],
    );
  }
}

String _savedMessage(String entity, String name, bool isEdit) => '$entity "$name" was ${isEdit ? 'updated' : 'added'}.';

/// Form for tables that only have a name (and optionally a description).
class _NameForm<T> extends StatefulWidget {
  final String entity;
  final BaseProvider<T> provider;
  final int? id;
  final String? name;
  final String? description;
  final bool hasDescription;
  final int maxLength;

  const _NameForm({
    required this.entity,
    required this.provider,
    this.id,
    this.name,
    this.description,
    this.hasDescription = false,
    required this.maxLength,
  });

  @override
  State<_NameForm<T>> createState() => _NameFormState<T>();
}

class _NameFormState<T> extends State<_NameForm<T>> with CrudFormMixin {
  late final _name = TextEditingController(text: widget.name);
  late final _description = TextEditingController(text: widget.description);

  bool get _isEdit => widget.id != null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() => submit(() async {
    final request = {
      'name': _name.text.trim(),
      if (widget.hasDescription) 'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
    };
    _isEdit ? await widget.provider.update(widget.id!, request) : await widget.provider.insert(request);
    return _savedMessage(widget.entity, _name.text.trim(), _isEdit);
  });

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: _isEdit ? 'Edit ${widget.entity.toLowerCase()}' : 'New ${widget.entity.toLowerCase()}',
      formKey: formKey,
      saving: saving,
      onSave: _save,
      children: [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name'),
          validator: Validators.required('Name', maxLength: widget.maxLength),
          forceErrorText: serverError('name'),
        ),
        if (widget.hasDescription)
          TextFormField(
            controller: _description,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description (optional)'),
            validator: Validators.optional(maxLength: 300, label: 'Description'),
            forceErrorText: serverError('description'),
          ),
      ],
    );
  }
}

class _SeasonForm extends StatefulWidget {
  final Season? season;

  const _SeasonForm({this.season});

  @override
  State<_SeasonForm> createState() => _SeasonFormState();
}

class _SeasonFormState extends State<_SeasonForm> with CrudFormMixin {
  late final _year = TextEditingController(text: widget.season?.year.toString());
  late final _description = TextEditingController(text: widget.season?.description);

  bool get _isEdit => widget.season != null;

  @override
  void dispose() {
    _year.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() => submit(() async {
    final request = {'year': int.parse(_year.text.trim()), 'description': _description.text.trim()};
    final provider = SeasonProvider();
    final saved = _isEdit ? await provider.update(widget.season!.seasonID, request) : await provider.insert(request);
    return _savedMessage('Season', '${saved.year}', _isEdit);
  });

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: _isEdit ? 'Edit season' : 'New season',
      formKey: formKey,
      saving: saving,
      onSave: _save,
      children: [
        TextFormField(
          controller: _year,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Year', hintText: 'e.g. 2026'),
          validator: Validators.intRange('Year', 1950, 2100),
          forceErrorText: serverError('year'),
        ),
        TextFormField(
          controller: _description,
          decoration: const InputDecoration(labelText: 'Description', hintText: 'e.g. FIA Formula One World Championship 2026'),
          validator: Validators.required('Description', maxLength: 100),
          forceErrorText: serverError('description'),
        ),
      ],
    );
  }
}

class _CountryForm extends StatefulWidget {
  final Country? country;

  const _CountryForm({this.country});

  @override
  State<_CountryForm> createState() => _CountryFormState();
}

class _CountryFormState extends State<_CountryForm> with CrudFormMixin {
  late final _name = TextEditingController(text: widget.country?.name);
  late final _code = TextEditingController(text: widget.country?.code);
  late int? _continentId = widget.country?.continentID;

  bool get _isEdit => widget.country != null;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _save() => submit(() async {
    final request = {'name': _name.text.trim(), 'code': _code.text.trim().toUpperCase(), 'continentID': _continentId};
    final provider = CountryProvider();
    final saved = _isEdit ? await provider.update(widget.country!.countryID, request) : await provider.insert(request);
    return _savedMessage('Country', saved.name, _isEdit);
  });

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: _isEdit ? 'Edit country' : 'New country',
      formKey: formKey,
      saving: saving,
      onSave: _save,
      children: [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name'),
          validator: Validators.required('Name', maxLength: 100),
          forceErrorText: serverError('name'),
        ),
        TextFormField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Country code', hintText: 'e.g. BA or ITA'),
          validator: Validators.countryCode,
          forceErrorText: serverError('code'),
        ),
        AsyncDropdown(
          load: ContinentProvider().getAll,
          label: 'Continent',
          initialId: _continentId,
          idOf: (c) => c.continentID,
          labelOf: (c) => c.name,
          requiredMessage: 'Select a continent.',
          forceErrorText: serverError('continentID'),
          onChanged: (c) => _continentId = c?.continentID,
        ),
      ],
    );
  }
}

class _CityForm extends StatefulWidget {
  final City? city;

  const _CityForm({this.city});

  @override
  State<_CityForm> createState() => _CityFormState();
}

class _CityFormState extends State<_CityForm> with CrudFormMixin {
  late final _name = TextEditingController(text: widget.city?.name);
  late int? _countryId = widget.city?.countryID;

  bool get _isEdit => widget.city != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() => submit(() async {
    final request = {'name': _name.text.trim(), 'countryID': _countryId};
    final provider = CityProvider();
    final saved = _isEdit ? await provider.update(widget.city!.cityID, request) : await provider.insert(request);
    return _savedMessage('City', saved.label, _isEdit);
  });

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: _isEdit ? 'Edit city' : 'New city',
      formKey: formKey,
      saving: saving,
      onSave: _save,
      children: [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name'),
          validator: Validators.required('Name', maxLength: 100),
          forceErrorText: serverError('name'),
        ),
        AsyncDropdown(
          load: CountryProvider().getAll,
          label: 'Country',
          initialId: _countryId,
          idOf: (c) => c.countryID,
          labelOf: (c) => c.name,
          requiredMessage: 'Select a country.',
          forceErrorText: serverError('countryID'),
          onChanged: (c) => _countryId = c?.countryID,
        ),
      ],
    );
  }
}

class _CircuitForm extends StatefulWidget {
  final Circuit? circuit;

  const _CircuitForm({this.circuit});

  @override
  State<_CircuitForm> createState() => _CircuitFormState();
}

class _CircuitFormState extends State<_CircuitForm> with CrudFormMixin {
  late final _name = TextEditingController(text: widget.circuit?.name);
  late final _laps = TextEditingController(text: widget.circuit?.laps.toString());
  late final _length = TextEditingController(text: widget.circuit?.lengthKm.toString());
  late int? _cityId = widget.circuit?.cityID;
  late int? _trackTypeId = widget.circuit?.trackTypeID;

  bool get _isEdit => widget.circuit != null;

  @override
  void dispose() {
    _name.dispose();
    _laps.dispose();
    _length.dispose();
    super.dispose();
  }

  Future<void> _save() => submit(() async {
    final request = {
      'name': _name.text.trim(),
      'cityID': _cityId,
      'trackTypeID': _trackTypeId,
      'laps': int.parse(_laps.text.trim()),
      'lengthKm': Validators.parseDecimal(_length.text),
    };
    final provider = CircuitProvider();
    final saved = _isEdit ? await provider.update(widget.circuit!.circuitID, request) : await provider.insert(request);
    return _savedMessage('Circuit', saved.name, _isEdit);
  });

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: _isEdit ? 'Edit circuit' : 'New circuit',
      formKey: formKey,
      saving: saving,
      onSave: _save,
      children: [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Circuit name', hintText: 'e.g. Autodromo Nazionale Monza'),
          validator: Validators.required('Circuit name', maxLength: 150),
          forceErrorText: serverError('name'),
        ),
        FormRow(
          children: [
            AsyncDropdown(
              load: CityProvider().getAll,
              label: 'City',
              initialId: _cityId,
              idOf: (c) => c.cityID,
              labelOf: (c) => c.label,
              requiredMessage: 'Select a city.',
              forceErrorText: serverError('cityID'),
              onChanged: (c) => _cityId = c?.cityID,
            ),
            AsyncDropdown(
              load: TrackTypeProvider().getAll,
              label: 'Track type',
              initialId: _trackTypeId,
              idOf: (t) => t.trackTypeID,
              labelOf: (t) => t.name,
              requiredMessage: 'Select a track type.',
              forceErrorText: serverError('trackTypeID'),
              onChanged: (t) => _trackTypeId = t?.trackTypeID,
            ),
          ],
        ),
        FormRow(
          children: [
            TextFormField(
              controller: _laps,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Number of laps', hintText: '1 - 200'),
              validator: Validators.intRange('Number of laps', 1, 200),
              forceErrorText: serverError('laps'),
            ),
            TextFormField(
              controller: _length,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Lap length (km)', hintText: 'e.g. 5.793', suffixText: 'km'),
              validator: Validators.decimalRange('Lap length', 1, 20),
              forceErrorText: serverError('lengthKm'),
            ),
          ],
        ),
      ],
    );
  }
}
