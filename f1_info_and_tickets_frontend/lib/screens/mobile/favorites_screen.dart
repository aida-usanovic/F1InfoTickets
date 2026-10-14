import 'package:flutter/material.dart';

import '../../api/providers.dart';
import '../../models/driver.dart';
import '../../models/team.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_image.dart';
import '../../widgets/feedback.dart';
import '../../widgets/state_views.dart';
import 'driver_details_screen.dart';
import 'team_details_screen.dart';

/// Favourite drivers and teams (used for recommendations and result notifications).
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _provider = FavoriteProvider();
  late Future<(List<Driver>, List<Team>)> _future = _load();

  Future<(List<Driver>, List<Team>)> _load() async => (await _provider.getDrivers(), await _provider.getTeams());

  void _reload() => setState(() {
    _future = _load();
  });

  Future<void> _remove(String name, Future<void> Function() remove) async {
    final confirmed = await confirmAction(
      context,
      title: 'Remove favourite',
      message: 'Remove $name from your favourites?',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await remove();
      if (!mounted) return;
      showSuccess(context, '$name was removed from your favourites.');
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favourites'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Drivers'),
              Tab(text: 'Teams'),
            ],
          ),
        ),
        body: FutureBuilder<(List<Driver>, List<Team>)>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) return ErrorView(error: snapshot.error!, onRetry: _reload);
            final data = snapshot.data;
            if (data == null) return const LoadingView();
            final (drivers, teams) = data;
            return TabBarView(
              children: [
                drivers.isEmpty
                    ? const EmptyView(message: 'No favourite drivers yet.\nTap the heart on a driver profile.', icon: Icons.favorite_border)
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (final d in drivers)
                            Card(
                              child: ListTile(
                                leading: AppImage(path: d.photoUrl, size: 44, circle: true, fallback: Icons.person),
                                title: Text(d.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text('#${d.number} · ${d.nationality ?? '-'}', style: const TextStyle(color: AppColors.muted)),
                                trailing: IconButton(
                                  tooltip: 'Remove',
                                  icon: const Icon(Icons.favorite, color: AppColors.red),
                                  onPressed: () => _remove(d.fullName, () => _provider.removeDriver(d.driverID)),
                                ),
                                onTap: () => _open(DriverDetailsScreen(driverId: d.driverID)),
                              ),
                            ),
                        ],
                      ),
                teams.isEmpty
                    ? const EmptyView(message: 'No favourite teams yet.\nTap the heart on a team page.', icon: Icons.favorite_border)
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (final t in teams)
                            Card(
                              child: ListTile(
                                leading: AppImage(path: t.logoUrl, size: 44, fit: BoxFit.contain, fallback: Icons.shield_outlined),
                                title: Text(t.teamName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text(t.base, style: const TextStyle(color: AppColors.muted)),
                                trailing: IconButton(
                                  tooltip: 'Remove',
                                  icon: const Icon(Icons.favorite, color: AppColors.red),
                                  onPressed: () => _remove(t.teamName, () => _provider.removeTeam(t.teamID)),
                                ),
                                onTap: () => _open(TeamDetailsScreen(teamId: t.teamID)),
                              ),
                            ),
                        ],
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}
