import 'package:flutter/material.dart';

import '../../api/providers.dart';
import '../../core/formatters.dart';
import '../../models/driver.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_image.dart';
import '../../widgets/feedback.dart';
import '../../widgets/mobile/mobile_widgets.dart';
import '../../widgets/state_views.dart';

/// Driver profile: photo, team, career statistics and results per season; can be added to favourites.
class DriverDetailsScreen extends StatefulWidget {
  final int driverId;

  const DriverDetailsScreen({super.key, required this.driverId});

  @override
  State<DriverDetailsScreen> createState() => _DriverDetailsScreenState();
}

class _DriverDetailsScreenState extends State<DriverDetailsScreen> {
  final _favorites = FavoriteProvider();
  late Future<DriverStats> _future = DriverProvider().getStats(widget.driverId);
  bool? _isFavorite;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    try {
      final favorites = await _favorites.getDrivers();
      if (mounted) setState(() => _isFavorite = favorites.any((d) => d.driverID == widget.driverId));
    } catch (_) {
      // Without the favourites list the heart button is simply hidden.
    }
  }

  Future<void> _toggleFavorite(Driver driver) async {
    setState(() => _busy = true);
    try {
      if (_isFavorite!) {
        await _favorites.removeDriver(driver.driverID);
        if (mounted) showSuccess(context, '${driver.fullName} was removed from your favourite drivers.');
      } else {
        await _favorites.addDriver(driver.driverID);
        if (mounted) showSuccess(context, '${driver.fullName} was added to your favourite drivers.');
      }
      if (mounted) setState(() => _isFavorite = !_isFavorite!);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DriverStats>(
      future: _future,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(stats?.driver.fullName ?? 'Driver'),
            actions: [
              if (stats != null && _isFavorite != null)
                IconButton(
                  tooltip: _isFavorite! ? 'Remove from favourites' : 'Add to favourites',
                  onPressed: _busy ? null : () => _toggleFavorite(stats.driver),
                  icon: Icon(_isFavorite! ? Icons.favorite : Icons.favorite_border, color: AppColors.red),
                ),
            ],
          ),
          body: snapshot.hasError
              ? ErrorView(
                  error: snapshot.error!,
                  onRetry: () => setState(() {
                    _future = DriverProvider().getStats(widget.driverId);
                  }),
                )
              : stats == null
              ? const LoadingView()
              : _buildBody(stats),
        );
      },
    );
  }

  Widget _buildBody(DriverStats stats) {
    final driver = stats.driver;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: AppImage(path: driver.photoUrl, size: 140, circle: true, fallback: Icons.person),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(driver.fullName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        ),
        Center(
          child: Text(
            '#${driver.number} · ${stats.currentTeam ?? 'No team'}',
            style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 16),
        StatGrid([
          StatTile('Races', formatNumber(stats.races)),
          StatTile('Wins', formatNumber(stats.wins)),
          StatTile('Podiums', formatNumber(stats.podiums)),
          StatTile('Points', formatNumber(stats.totalPoints)),
          StatTile('Best finish', stats.bestFinish == null ? '-' : 'P${stats.bestFinish}'),
          StatTile('Fastest laps', formatNumber(stats.fastestLaps)),
        ]),
        const SizedBox(height: 12),
        InfoCard(
          title: 'Profile',
          children: [
            InfoRow(Icons.flag_outlined, 'Nationality', driver.nationality ?? '-'),
            InfoRow(Icons.cake_outlined, 'Date of birth', formatDate(driver.birthDate)),
            InfoRow(Icons.person_outline, 'Age', '${stats.age}'),
            InfoRow(Icons.groups_outlined, 'Team', stats.currentTeam ?? '-'),
            InfoRow(Icons.badge_outlined, 'Role', driver.isReserveDriver ? 'Reserve driver' : 'Race driver'),
          ],
        ),
        if (stats.seasons.isNotEmpty) ...[
          const SizedBox(height: 12),
          InfoCard(
            title: 'Seasons',
            children: [
              for (final s in stats.seasons)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${s.year} · ${s.team ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${s.races} races · ${s.wins} wins · ${s.podiums} podiums',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  trailing: Text('${formatNumber(s.points)} pts', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
