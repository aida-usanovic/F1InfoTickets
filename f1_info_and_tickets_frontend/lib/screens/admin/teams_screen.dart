import 'package:flutter/material.dart';

import '../../api/providers.dart';
import '../../core/paged_result.dart';
import '../../core/validators.dart';
import '../../models/driver.dart';
import '../../models/reference.dart';
import '../../models/team.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_page.dart';
import '../../widgets/admin/async_dropdown.dart';
import '../../widgets/admin/crud.dart';
import '../../widgets/admin/image_pick_field.dart';
import '../../widgets/admin/paged_table.dart';
import '../../widgets/app_image.dart';
import '../../widgets/feedback.dart';
import '../../widgets/state_views.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final _table = PagedTableController();
  final _provider = TeamProvider();
  int? _countryId;

  Future<void> _openForm([Team? team]) async {
    if (await openFormDialog(context, TeamFormDialog(team: team))) _table.reload();
  }

  Future<void> _openLineup(Team team) => showDialog(
    context: context,
    builder: (_) => TeamLineupDialog(team: team),
  );

  Future<void> _delete(Team team) async {
    final deleted = await confirmDelete(
      context,
      title: 'Delete team',
      name: team.teamName,
      delete: () => _provider.delete(team.teamID),
      successMessage: 'Team ${team.teamName} was deleted.',
    );
    if (deleted) _table.reload();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Teams',
      subtitle: 'Teams, headquarters and driver line-ups per season',
      child: PagedTable<Team>(
        controller: _table,
        load: (query) => _provider.get(filter: {...query, 'CountryID': _countryId}),
        searchHint: 'Search by team name or team principal',
        emptyMessage: 'No teams yet.',
        filters: [
          SizedBox(
            width: 240,
            child: AsyncDropdown(
              load: CountryProvider().getAll,
              label: 'Headquarters country',
              allLabel: 'All countries',
              idOf: (c) => c.countryID,
              labelOf: (c) => c.name,
              onChanged: (c) {
                _countryId = c?.countryID;
                _table.reload(firstPage: true);
              },
            ),
          ),
        ],
        toolbarActions: [ElevatedButton.icon(onPressed: _openForm, icon: const Icon(Icons.add), label: const Text('Add team'))],
        columns: [
          TableColumnDef('', (t) => AppImage(path: t.logoUrl, size: 40, fit: BoxFit.contain, fallback: Icons.shield_outlined)),
          TableColumnDef('Name', (t) => Text(t.teamName, style: const TextStyle(fontWeight: FontWeight.w600))),
          TableColumnDef('Headquarters', (t) => Text(t.base)),
          TableColumnDef('Team principal', (t) => Text(t.teamPrincipal)),
        ],
        actions: [
          RowAction('Driver line-up', Icons.groups_outlined, _openLineup),
          RowAction('Edit', Icons.edit_outlined, _openForm),
          RowAction('Delete', Icons.delete_outline, _delete, color: AppColors.red),
        ],
      ),
    );
  }
}

class TeamFormDialog extends StatefulWidget {
  final Team? team;

  const TeamFormDialog({super.key, this.team});

  @override
  State<TeamFormDialog> createState() => _TeamFormDialogState();
}

class _TeamFormDialogState extends State<TeamFormDialog> with CrudFormMixin {
  late final _name = TextEditingController(text: widget.team?.teamName);
  late final _principal = TextEditingController(text: widget.team?.teamPrincipal);
  late int? _cityId = widget.team?.baseCityID;
  String? _imagePath;

  bool get _isEdit => widget.team != null;

  @override
  void dispose() {
    _name.dispose();
    _principal.dispose();
    super.dispose();
  }

  Future<void> _save() => submit(() async {
    final saved = await TeamProvider().save(
      {'TeamName': _name.text.trim(), 'TeamPrincipal': _principal.text.trim(), 'BaseCityID': _cityId},
      id: widget.team?.teamID,
      imagePath: _imagePath,
    );
    return _isEdit ? 'Team ${saved.teamName} was updated.' : 'Team ${saved.teamName} was added.';
  });

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: _isEdit ? 'Edit team' : 'New team',
      formKey: formKey,
      saving: saving,
      onSave: _save,
      children: [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Team name'),
          validator: Validators.required('Team name', maxLength: 100),
          forceErrorText: serverError('teamName'),
        ),
        TextFormField(
          controller: _principal,
          decoration: const InputDecoration(labelText: 'Team principal', hintText: 'Full name'),
          validator: Validators.required('Team principal', maxLength: 100),
          forceErrorText: serverError('teamPrincipal'),
        ),
        AsyncDropdown(
          load: CityProvider().getAll,
          label: 'Headquarters (city)',
          initialId: _cityId,
          idOf: (c) => c.cityID,
          labelOf: (c) => c.label,
          requiredMessage: "Select the city of the team's headquarters.",
          forceErrorText: serverError('baseCityID'),
          onChanged: (c) => _cityId = c?.cityID,
        ),
        ImagePickField(
          label: 'Team logo',
          currentPath: widget.team?.logoUrl,
          fallback: Icons.shield_outlined,
          errorText: serverError('image'),
          onChanged: (path) => _imagePath = path,
        ),
      ],
    );
  }
}

/// Drivers of a team per season: add and remove (with confirmation).
class TeamLineupDialog extends StatefulWidget {
  final Team team;

  const TeamLineupDialog({super.key, required this.team});

  @override
  State<TeamLineupDialog> createState() => _TeamLineupDialogState();
}

class _TeamLineupDialogState extends State<TeamLineupDialog> {
  final _drivers = DriverProvider();
  final _teams = TeamProvider();

  List<Season>? _seasons;
  List<Driver> _allDrivers = [];
  int? _seasonId;
  List<Driver>? _lineup;
  int? _driverToAdd;
  Object? _error;
  bool _busy = false;

  Season get _season => _seasons!.firstWhere((s) => s.seasonID == _seasonId);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _error = null);
    try {
      final seasonProvider = SeasonProvider();
      final results = await Future.wait([seasonProvider.getAll(), seasonProvider.getCurrent(), _drivers.getAll()]);
      final seasons = results[0] as List<Season>;
      final current = results[1] as Season?;
      if (!mounted) return;
      setState(() {
        _seasons = seasons;
        _allDrivers = results[2] as List<Driver>;
        _seasonId = current?.seasonID ?? (seasons.isEmpty ? null : seasons.last.seasonID);
      });
      await _loadLineup();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _loadLineup() async {
    if (_seasonId == null) return;
    setState(() {
      _lineup = null;
      _driverToAdd = null;
    });
    try {
      final lineup = await fetchAllPages((page) => _drivers.getByTeamAndSeason(widget.team.teamID, _seasonId!, page: page));
      if (mounted) setState(() => _lineup = lineup);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _add() async {
    final driver = _allDrivers.firstWhere((d) => d.driverID == _driverToAdd);
    setState(() => _busy = true);
    try {
      await _teams.addDriver(widget.team.teamID, driver.driverID, _seasonId!);
      if (!mounted) return;
      showSuccess(context, '${driver.fullName} was added to the ${widget.team.teamName} line-up for ${_season.year}.');
      await _loadLineup();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(Driver driver) async {
    final confirmed = await confirmAction(
      context,
      title: 'Remove from line-up',
      message: 'Remove ${driver.fullName} from the ${widget.team.teamName} line-up for ${_season.year}?',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await _teams.removeDriver(widget.team.teamID, driver.driverID, _seasonId!);
      if (!mounted) return;
      showSuccess(context, '${driver.fullName} was removed from the ${widget.team.teamName} line-up (${_season.year}).');
      await _loadLineup();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DialogHeader(title: 'Line-up: ${widget.team.teamName}', onClose: () => Navigator.pop(context)),
            const Divider(height: 1),
            Flexible(
              child: Padding(padding: const EdgeInsets.all(24), child: _buildBody()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) return ErrorView(error: _error!, onRetry: _init);
    final seasons = _seasons;
    if (seasons == null) return const LoadingView();
    if (seasons.isEmpty) return const EmptyView(message: 'Add a season in Reference data first.');

    final lineup = _lineup;
    final lineupIds = lineup?.map((d) => d.driverID).toSet() ?? {};
    final available = _allDrivers.where((d) => !lineupIds.contains(d.driverID)).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          initialValue: _seasonId,
          decoration: const InputDecoration(labelText: 'Season', prefixIcon: Icon(Icons.calendar_today_outlined)),
          items: [for (final s in seasons) DropdownMenuItem(value: s.seasonID, child: Text('${s.year} - ${s.description}'))],
          onChanged: _busy
              ? null
              : (id) {
                  _seasonId = id;
                  _loadLineup();
                },
        ),
        const SizedBox(height: 16),
        if (lineup == null)
          const LoadingView()
        else if (lineup.isEmpty)
          const EmptyView(message: 'The team has no drivers in this season.', icon: Icons.person_off_outlined)
        else
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final driver in lineup)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: AppImage(path: driver.photoUrl, size: 40, circle: true, fallback: Icons.person),
                    title: Text(driver.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('#${driver.number} · ${driver.nationality ?? '-'}${driver.isReserveDriver ? ' · reserve' : ''}'),
                    trailing: IconButton(
                      tooltip: 'Remove from line-up',
                      icon: const Icon(Icons.person_remove_outlined, color: AppColors.red),
                      onPressed: _busy ? null : () => _remove(driver),
                    ),
                  ),
              ],
            ),
          ),
        const Divider(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('add-$_seasonId-${lineup?.length}'),
                initialValue: _driverToAdd,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Add driver to line-up', prefixIcon: Icon(Icons.person_add_alt)),
                items: [for (final d in available) DropdownMenuItem(value: d.driverID, child: Text('${d.fullName} (#${d.number})'))],
                onChanged: lineup == null || _busy ? null : (id) => setState(() => _driverToAdd = id),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _driverToAdd == null || _busy ? null : _add,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
      ],
    );
  }
}
