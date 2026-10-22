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
import 'team_details_screen.dart';

/// Constructors' standings for a season, loaded page by page; the search runs on the server.
class TeamsTab extends StatefulWidget {
  const TeamsTab({super.key});

  @override
  State<TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends State<TeamsTab> {
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

  Future<PagedResult<TeamStanding>> _load(int page) async {
    final season = _season;
    if (season == null) return PagedResult(totalCount: 0, page: 1, pageSize: 10, items: []);
    return ResultProvider().getTeamStandings(season.seasonID, page: page, search: _search);
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
                child: SearchField(hint: 'Search teams', onChanged: _onSearch),
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
          child: InfiniteList<TeamStanding>(
            controller: _list,
            load: _load,
            emptyMessage: _search.isNotEmpty ? 'No teams match "$_search".' : 'No results yet for the ${_season?.year} season.',
            itemBuilder: (context, standing) => Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PositionBadge(standing.position),
                    const SizedBox(width: 10),
                    AppImage(path: standing.logoUrl, size: 44, fit: BoxFit.contain, fallback: Icons.shield_outlined),
                  ],
                ),
                title: Text(standing.teamName, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${standing.driversCount} drivers scored', style: const TextStyle(color: AppColors.muted)),
                trailing: Text(
                  '${formatNumber(standing.totalPoints)} pts',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.red),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeamDetailsScreen(teamId: standing.teamID, seasonId: _season?.seasonID),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
