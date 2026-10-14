import 'package:flutter/material.dart';

import '../../api/providers.dart';
import '../../core/formatters.dart';
import '../../models/reference.dart';
import '../../models/result.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_image.dart';
import '../../widgets/mobile/mobile_widgets.dart';
import '../../widgets/state_views.dart';
import 'driver_details_screen.dart';

/// Drivers' championship standings for a season, with search.
class DriversTab extends StatefulWidget {
  const DriversTab({super.key});

  @override
  State<DriversTab> createState() => _DriversTabState();
}

class _DriversTabState extends State<DriversTab> {
  List<Season>? _seasons;
  Season? _season;
  Future<List<DriverStanding>>? _future;
  String _search = '';
  Object? _error;

  @override
  void initState() {
    super.initState();
    _init();
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
        _future = _load();
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<List<DriverStanding>> _load() => _season == null ? Future.value([]) : ResultProvider().getDriverStandings(_season!.seasonID);

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
                child: SearchField(hint: 'Search drivers or teams', onChanged: (v) => setState(() => _search = v.trim().toLowerCase())),
              ),
              const SizedBox(width: 10),
              DropdownButton<Season>(
                value: _season,
                underline: const SizedBox(),
                items: [for (final s in seasons) DropdownMenuItem(value: s, child: Text('${s.year}'))],
                onChanged: (s) => setState(() {
                  _season = s;
                  _future = _load();
                }),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<DriverStanding>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ErrorView(
                  error: snapshot.error!,
                  onRetry: () => setState(() {
                    _future = _load();
                  }),
                );
              }
              final standings = snapshot.data;
              if (standings == null) return const LoadingView();
              if (standings.isEmpty) return EmptyView(message: 'No results yet for the ${_season?.year} season.');
              final filtered = [
                for (var i = 0; i < standings.length; i++)
                  if (_search.isEmpty ||
                      standings[i].driverName.toLowerCase().contains(_search) ||
                      standings[i].teamName.toLowerCase().contains(_search))
                    (position: i + 1, standing: standings[i]),
              ];
              if (filtered.isEmpty) return const EmptyView(message: 'No drivers match your search.', icon: Icons.search_off);
              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _future = _load();
                  });
                  await _future;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final (:position, :standing) = filtered[i];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PositionBadge(position),
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
                        onTap: () =>
                            Navigator.push(context, MaterialPageRoute(builder: (_) => DriverDetailsScreen(driverId: standing.driverID))),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
