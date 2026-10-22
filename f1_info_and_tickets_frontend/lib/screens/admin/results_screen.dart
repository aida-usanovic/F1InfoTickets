import 'package:flutter/material.dart';

import '../../api/providers.dart';
import '../../core/paged_result.dart';
import '../../core/api_exception.dart';
import '../../core/formatters.dart';
import '../../core/validators.dart';
import '../../models/driver.dart';
import '../../models/race.dart';
import '../../models/result.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_page.dart';
import '../../widgets/feedback.dart';
import '../../widgets/state_views.dart';

/// Points for positions 1-10 (same table as the API; no bonus for the fastest lap).
const _points = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];
const _editWindow = Duration(hours: 48);

int _pointsFor(int position) => position <= _points.length ? _points[position - 1] : 0;

class _ResultRow {
  int? driverId;
  final TextEditingController time;
  bool fastestLap;

  _ResultRow({this.driverId, String time = '', this.fastestLap = false}) : time = TextEditingController(text: time);
}

/// Race classification entry. The race list holds the upcoming races and the races that finished in the last 48 hours;
/// results can be saved from the start of the race until 48 hours after it. The order of the rows is the finishing order,
/// the team and points are filled in automatically.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _results = ResultProvider();
  final _formKey = GlobalKey<FormState>();

  List<Race>? _races;
  int? _raceId;
  RaceResults? _raceResults;
  List<Driver> _drivers = [];
  List<_ResultRow> _rows = [];
  Map<String, String> _serverErrors = {};
  Object? _error;
  bool _loadingRace = false;
  bool _saving = false;

  Race? get _race => _races?.where((r) => r.raceID == _raceId).firstOrNull;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _disposeRows();
    super.dispose();
  }

  void _disposeRows() {
    for (final row in _rows) {
      row.time.dispose();
    }
  }

  Future<void> _init() async {
    setState(() {
      _error = null;
      _races = null;
      _raceId = null;
      _raceResults = null;
    });
    try {
      // Upcoming races and races that finished less than 48 hours ago, the earliest first
      // (so a race whose results entry is open is selected by default).
      final races = await RaceProvider().getAll(filter: {'DateFrom': DateTime.now().subtract(_editWindow)});
      races.sort((a, b) => a.date.compareTo(b.date));
      if (!mounted) return;
      setState(() => _races = races);
      if (races.isNotEmpty) await _selectRace(races.first.raceID);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _selectRace(int raceId) async {
    setState(() {
      _raceId = raceId;
      _loadingRace = true;
      _serverErrors = {};
    });
    try {
      final seasonId = _races!.firstWhere((r) => r.raceID == raceId).seasonID;
      final results = await Future.wait([
        _results.getRaceResults(raceId),
        fetchAllPages((page) => DriverProvider().getBySeason(seasonId, page: page)),
      ]);
      if (!mounted || _raceId != raceId) return;
      _applyResults(results[0] as RaceResults, drivers: results[1] as List<Driver>);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loadingRace = false);
    }
  }

  void _applyResults(RaceResults raceResults, {List<Driver>? drivers}) {
    _disposeRows();
    setState(() {
      if (drivers != null) _drivers = drivers;
      _raceResults = raceResults;
      _rows = [for (final r in raceResults.results) _ResultRow(driverId: r.driverID, time: r.timeTaken, fastestLap: r.isFastestLap)];
    });
  }

  void _addRow() => setState(() => _rows.add(_ResultRow()));

  void _addAllDrivers() {
    final used = _rows.map((r) => r.driverId).toSet();
    setState(() {
      for (final d in _drivers.where((d) => !used.contains(d.driverID))) {
        _rows.add(_ResultRow(driverId: d.driverID));
      }
    });
  }

  void _removeRow(int index) {
    final row = _rows.removeAt(index);
    row.time.dispose();
    setState(() => _serverErrors = {});
  }

  void _move(int index, int delta) {
    setState(() {
      final row = _rows.removeAt(index);
      _rows.insert(index + delta, row);
      _serverErrors = {};
    });
  }

  Future<void> _save() async {
    final race = _race!;
    if (_rows.isEmpty) {
      showError(context, ApiException('Add at least one driver to the classification.'));
      return;
    }
    if (_serverErrors.isNotEmpty) {
      setState(() => _serverErrors = {});
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await confirmAction(
      context,
      title: 'Save results',
      message:
          'Save the classification for ${race.raceName} (${_rows.length} drivers)? Points are calculated automatically, '
          'and users who follow these drivers and teams will be notified.',
      confirmLabel: 'Save results',
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    try {
      final saved = await _results.saveRaceResults(race.raceID, [
        for (var i = 0; i < _rows.length; i++)
          {'driverID': _rows[i].driverId, 'position': i + 1, 'isFastestLap': _rows[i].fastestLap, 'timeTaken': _rows[i].time.text.trim()},
      ]);
      if (!mounted) return;
      _applyResults(saved);
      showSuccess(context, 'Results for ${race.raceName} were saved (${saved.results.length} drivers).');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _serverErrors = e.fieldErrors);
      showError(context, e);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = _raceResults?.canEdit ?? false;
    return AdminPage(
      title: 'Results',
      subtitle: 'Results can be entered from the race start until 48 hours after it',
      actions: [
        if (canEdit && !_loadingRace)
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined),
            label: const Text('Save results'),
          ),
      ],
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) return ErrorView(error: _error!, onRetry: _init);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(width: 560, child: _buildRaceDropdown()),
            const SizedBox(width: 12),
            IconButton(tooltip: 'Refresh races', onPressed: _saving ? null : _init, icon: const Icon(Icons.refresh)),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildRaceContent()),
      ],
    );
  }

  Widget _buildRaceDropdown() {
    final races = _races;
    if (races == null) {
      return const InputDecorator(
        decoration: InputDecoration(labelText: 'Race'),
        child: LinearProgressIndicator(),
      );
    }
    final now = DateTime.now();
    return DropdownButtonFormField<int>(
      key: ValueKey('races-${races.length}-${races.firstOrNull?.raceID}'),
      initialValue: _raceId,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Race (upcoming or finished in the last 48 hours)'),
      items: [
        for (final r in races)
          DropdownMenuItem(
            value: r.raceID,
            child: Text(
              '${r.raceName} · ${formatDateTime(r.date)}  ${r.date.isAfter(now) ? '(upcoming)' : '(entry open)'}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: _saving ? null : (id) => _selectRace(id!),
    );
  }

  Widget _buildRaceContent() {
    if (_races != null && _races!.isEmpty) {
      return const EmptyView(message: 'There are no upcoming races and no race finished in the last 48 hours.', icon: Icons.flag_outlined);
    }
    final raceResults = _raceResults;
    if (raceResults == null || _loadingRace) return const LoadingView();

    // The entry window in local time; the API decides whether saving is allowed (CanEdit).
    final upcoming = raceResults.raceDate.isAfter(DateTime.now());
    final closesAt = formatDateTime(raceResults.raceDate.add(_editWindow));
    final info = upcoming
        ? 'This race has not started yet. Results can be entered from ${formatDateTime(raceResults.raceDate)} until $closesAt.'
        : raceResults.canEdit
        ? 'Results entry is open until $closesAt.'
        : raceResults.editInfo;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EditInfoBanner(canEdit: raceResults.canEdit, upcoming: upcoming, info: info),
          Expanded(
            child: raceResults.canEdit
                ? _buildEditor()
                : upcoming
                ? EmptyView(message: 'Results for ${raceResults.raceName} can be entered once the race has started.', icon: Icons.schedule)
                : _buildReadOnly(raceResults),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnly(RaceResults raceResults) {
    if (raceResults.results.isEmpty) {
      return const EmptyView(message: 'No results were entered for this race.', icon: Icons.emoji_events_outlined);
    }
    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Pos.'), numeric: true),
            DataColumn(label: Text('Driver')),
            DataColumn(label: Text('Team')),
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Points'), numeric: true),
            DataColumn(label: Text('Fastest lap')),
          ],
          rows: [
            for (final r in raceResults.results)
              DataRow(
                cells: [
                  DataCell(Text('${r.position}.')),
                  DataCell(Text(r.driverName ?? '-', style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(r.teamName ?? '-')),
                  DataCell(Text(r.timeTaken)),
                  DataCell(Text(formatNumber(r.points))),
                  DataCell(r.isFastestLap ? const Icon(Icons.timer, color: Colors.purple) : const SizedBox()),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    final usedIds = _rows.map((r) => r.driverId).whereType<int>().toSet();
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.carbonLight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const DefaultTextStyle(
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              child: Row(
                children: [
                  SizedBox(width: 48, child: Text('Pos.')),
                  Expanded(flex: 4, child: Text('Driver')),
                  Expanded(flex: 3, child: Text('Team')),
                  Expanded(flex: 3, child: Text('Time (h:mm:ss.fff)')),
                  SizedBox(width: 70, child: Text('Points')),
                  SizedBox(width: 110, child: Text('Fastest lap')),
                  SizedBox(width: 136, child: Text('Actions')),
                ],
              ),
            ),
          ),
          Expanded(
            child: _rows.isEmpty
                ? const EmptyView(
                    message: 'The classification is empty. Add drivers in their finishing order.',
                    icon: Icons.format_list_numbered,
                  )
                // All rows are built (not lazily) so that the whole form is validated.
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var i = 0; i < _rows.length; i++) ...[if (i > 0) const Divider(height: 1), _buildRow(i, usedIds)],
                      ],
                    ),
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                OutlinedButton.icon(onPressed: _saving ? null : _addRow, icon: const Icon(Icons.add), label: const Text('Add row')),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _saving || usedIds.length >= _drivers.length ? null : _addAllDrivers,
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Add all remaining season drivers'),
                ),
                const Spacer(),
                Text('Row order is the finishing order.', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(int i, Set<int> usedIds) {
    final row = _rows[i];
    final position = i + 1;
    final driver = _drivers.where((d) => d.driverID == row.driverId).firstOrNull;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text('$position.', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<int>(
              // Rows can be reordered; the key ties the field state to its row.
              key: ObjectKey(row),
              initialValue: row.driverId,
              isExpanded: true,
              decoration: const InputDecoration(hintText: 'Select a driver', isDense: true),
              items: [
                for (final d in _drivers)
                  if (d.driverID == row.driverId || !usedIds.contains(d.driverID))
                    DropdownMenuItem(
                      value: d.driverID,
                      child: Text('${d.fullName} (#${d.number})', overflow: TextOverflow.ellipsis),
                    ),
              ],
              validator: (v) => v == null ? 'Select a driver.' : null,
              forceErrorText: _serverErrors['results[$i].driverID'],
              onChanged: _saving ? null : (id) => setState(() => row.driverId = id),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(driver?.teamName ?? '-', overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: row.time,
              enabled: !_saving,
              decoration: InputDecoration(
                hintText: position == 1 ? '1:32:15.123' : '1:32:20.456',
                isDense: true,
                suffixIcon: IconButton(
                  tooltip: 'Pick time',
                  icon: const Icon(Icons.timer_outlined),
                  onPressed: _saving ? null : () => _pickTime(row),
                ),
              ),
              validator: Validators.raceTime,
              forceErrorText: _serverErrors['results[$i].timeTaken'],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 58,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text('${_pointsFor(position)}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          SizedBox(
            width: 110,
            child: Checkbox(
              value: row.fastestLap,
              onChanged: _saving
                  ? null
                  : (v) => setState(() {
                      // Only one driver can have the fastest lap.
                      for (final other in _rows) {
                        other.fastestLap = false;
                      }
                      row.fastestLap = v ?? false;
                    }),
            ),
          ),
          SizedBox(
            width: 136,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Move up',
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: _saving || i == 0 ? null : () => _move(i, -1),
                ),
                IconButton(
                  tooltip: 'Move down',
                  icon: const Icon(Icons.arrow_downward),
                  onPressed: _saving || i == _rows.length - 1 ? null : () => _move(i, 1),
                ),
                IconButton(
                  tooltip: 'Remove row',
                  icon: const Icon(Icons.delete_outline, color: AppColors.red),
                  onPressed: _saving ? null : () => _removeRow(i),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(_ResultRow row) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => _RaceTimePicker(initial: row.time.text),
    );
    if (picked != null) setState(() => row.time.text = picked);
  }
}

class _EditInfoBanner extends StatelessWidget {
  final bool canEdit;
  final bool upcoming;
  final String? info;

  const _EditInfoBanner({required this.canEdit, required this.upcoming, required this.info});

  @override
  Widget build(BuildContext context) {
    final color = canEdit ? AppColors.success : (upcoming ? Colors.blueGrey : AppColors.warning);
    return Container(
      color: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(canEdit ? Icons.edit_note : (upcoming ? Icons.schedule : Icons.lock_clock), color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(info ?? (canEdit ? 'Results entry is open.' : 'Results can no longer be changed.'))),
        ],
      ),
    );
  }
}

/// Picker for a race time (hours, minutes, seconds, milliseconds); returns "h:mm:ss.fff".
class _RaceTimePicker extends StatefulWidget {
  final String initial;

  const _RaceTimePicker({required this.initial});

  @override
  State<_RaceTimePicker> createState() => _RaceTimePickerState();
}

class _RaceTimePickerState extends State<_RaceTimePicker> {
  int _hours = 1;
  int _minutes = 30;
  int _seconds = 0;
  int _millis = 0;

  @override
  void initState() {
    super.initState();
    final match = RegExp(r'^(\d{1,2}):(\d{2}):(\d{2})(?:\.(\d{1,3}))?$').firstMatch(widget.initial.trim());
    if (match != null) {
      _hours = int.parse(match.group(1)!).clamp(0, 4);
      _minutes = int.parse(match.group(2)!).clamp(0, 59);
      _seconds = int.parse(match.group(3)!).clamp(0, 59);
      _millis = int.parse((match.group(4) ?? '0').padRight(3, '0'));
    }
  }

  Widget _spinner(String label, int value, int max, ValueChanged<int> onChanged, {int step = 1, int width = 2}) {
    return Expanded(
      child: DropdownButtonFormField<int>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        menuMaxHeight: 320,
        items: [for (var v = 0; v <= max; v += step) DropdownMenuItem(value: v, child: Text(v.toString().padLeft(width, '0')))],
        onChanged: (v) => setState(() => onChanged(v!)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatted =
        '$_hours:${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}.${_millis.toString().padLeft(3, '0')}';
    return AlertDialog(
      title: const Text('Race time'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _spinner('Hours', _hours, 4, (v) => _hours = v, width: 1),
                const SizedBox(width: 8),
                _spinner('Minutes', _minutes, 59, (v) => _minutes = v),
                const SizedBox(width: 8),
                _spinner('Seconds', _seconds, 59, (v) => _seconds = v),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: _millis.toString().padLeft(3, '0'),
                    decoration: const InputDecoration(labelText: 'Millis.'),
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    onChanged: (v) => setState(() => _millis = (int.tryParse(v) ?? 0).clamp(0, 999)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(formatted, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, formatted), child: const Text('Set')),
      ],
    );
  }
}
