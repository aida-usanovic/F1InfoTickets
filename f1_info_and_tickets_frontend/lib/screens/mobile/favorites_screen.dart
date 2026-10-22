import 'package:flutter/material.dart';

import '../../api/providers.dart';
import '../../models/driver.dart';
import '../../models/team.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_image.dart';
import '../../widgets/feedback.dart';
import '../../widgets/mobile/infinite_list.dart';
import 'driver_details_screen.dart';
import 'team_details_screen.dart';

/// Favourite drivers and teams (used for recommendations and result notifications), loaded page by page.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _provider = FavoriteProvider();
  final _drivers = InfiniteListController();
  final _teams = InfiniteListController();

  Future<void> _remove(String name, Future<void> Function() remove, InfiniteListController list) async {
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
      list.reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  /// The favourite can be removed on the details page, so the list reloads on return.
  Future<void> _open(Widget screen, InfiniteListController list) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    list.reload();
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
        body: TabBarView(
          children: [
            InfiniteList<Driver>(
              controller: _drivers,
              load: (page) => _provider.getDrivers(page: page),
              emptyMessage: 'No favourite drivers yet.\nTap the heart on a driver profile.',
              itemBuilder: (context, d) => Card(
                child: ListTile(
                  leading: AppImage(path: d.photoUrl, size: 44, circle: true, fallback: Icons.person),
                  title: Text(d.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('#${d.number} · ${d.nationality ?? '-'}', style: const TextStyle(color: AppColors.muted)),
                  trailing: IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.favorite, color: AppColors.red),
                    onPressed: () => _remove(d.fullName, () => _provider.removeDriver(d.driverID), _drivers),
                  ),
                  onTap: () => _open(DriverDetailsScreen(driverId: d.driverID), _drivers),
                ),
              ),
            ),
            InfiniteList<Team>(
              controller: _teams,
              load: (page) => _provider.getTeams(page: page),
              emptyMessage: 'No favourite teams yet.\nTap the heart on a team page.',
              itemBuilder: (context, t) => Card(
                child: ListTile(
                  leading: AppImage(path: t.logoUrl, size: 44, fit: BoxFit.contain, fallback: Icons.shield_outlined),
                  title: Text(t.teamName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(t.base, style: const TextStyle(color: AppColors.muted)),
                  trailing: IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.favorite, color: AppColors.red),
                    onPressed: () => _remove(t.teamName, () => _provider.removeTeam(t.teamID), _teams),
                  ),
                  onTap: () => _open(TeamDetailsScreen(teamId: t.teamID), _teams),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
