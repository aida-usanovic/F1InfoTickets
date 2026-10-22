import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/providers.dart';
import '../../core/formatters.dart';
import '../../core/paged_result.dart';
import '../../models/reference.dart';
import '../../models/result.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_image.dart';
import '../../widgets/mobile/infinite_list.dart';
import '../../widgets/mobile/mobile_widgets.dart';
import '../../widgets/state_views.dart';
import 'driver_details_screen.dart';

/// Drivers' championship standings for a season, loaded page by page; the search runs on the server.
class DriversTab extends StatefulWidget {
  const DriversTab({super.key});

  @override
  State<DriversTab> createState() => _DriversTabState();
}

class _DriversTabState extends State<DriversTab> {
  final _list = InfiniteListController();
  Timer? _debounce;
  List<Season>? _seasons;
  Season? _season;
  String _search = '';
  Object? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _error = null);
    try {
      final provider = SeasonProvider();
      final seasons = await provider.getAll();
      final current = await provider.getCurrent();
      if (!mounted) return;
      setState(() {
        _seasons = seasons;
        _season = seasons.where((s) => s.seasonID == current?.seasonID).firstOrNull ?? seasons.lastOrNull;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _search = value.trim());
      _list.reload();
    });
  }

  Future<PagedResult<DriverStanding>> _load(int page) async {
    final season = _season;
    if (season == null) return PagedResult(totalCount: 0, page: 1, pageSize: 10, items: []);
    return ResultProvider().getDriverStandings(season.seasonID, page: page, search: _search);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return ErrorView(error: _error!, onRetry: _init);
    final seasons = _seasons;
    if (seasons == null) return const LoadingView();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: SearchField(hint: 'Search drivers or teams', onChanged: _onSearch),
              ),
              const SizedBox(width: 10),
              DropdownButton<Season>(
                value: _season,
                underline: const SizedBox(),
                items: [for (final s in seasons) DropdownMenuItem(value: s, child: Text('${s.year}'))],
                onChanged: (s) {
                  setState(() => _season = s);
                  _list.reload();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: InfiniteList<DriverStanding>(
            controller: _list,
            load: _load,
            emptyMessage: _search.isNotEmpty ? 'No drivers match "$_search".' : 'No results yet for the ${_season?.year} season.',
            itemBuilder: (context, standing) => Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PositionBadge(standing.position),
                    const SizedBox(width: 10),
                    AppImage(path: standing.photoUrl, size: 44, circle: true, fallback: Icons.person),
                  ],
                ),
                title: Text(standing.driverName, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(standing.teamName, style: const TextStyle(color: AppColors.muted)),
                trailing: Text(
                  '${formatNumber(standing.totalPoints)} pts',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.red),
                ),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DriverDetailsScreen(driverId: standing.driverID))),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
