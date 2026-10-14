import 'package:flutter/material.dart';

import '../../api/providers.dart';
import '../../core/formatters.dart';
import '../../models/team.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_image.dart';
import '../../widgets/feedback.dart';
import '../../widgets/mobile/mobile_widgets.dart';
import '../../widgets/state_views.dart';
import 'driver_details_screen.dart';

/// Team details for a season: headquarters, principal, results and drivers; can be added to favourites.
class TeamDetailsScreen extends StatefulWidget {
  final int teamId;
  final int? seasonId;

  const TeamDetailsScreen({super.key, required this.teamId, this.seasonId});

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  final _favorites = FavoriteProvider();
  late Future<TeamDetails> _future = _load();
  bool? _isFavorite;
  bool _busy = false;

  Future<TeamDetails> _load() => TeamProvider().getDetails(widget.teamId, seasonId: widget.seasonId);

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    try {
      final favorites = await _favorites.getTeams();
      if (mounted) setState(() => _isFavorite = favorites.any((t) => t.teamID == widget.teamId));
    } catch (_) {
      // Without the favourites list the heart button is simply hidden.
    }
  }

  Future<void> _toggleFavorite(Team team) async {
    setState(() => _busy = true);
    try {
      if (_isFavorite!) {
        await _favorites.removeTeam(team.teamID);
        if (mounted) showSuccess(context, '${team.teamName} was removed from your favourite teams.');
      } else {
        await _favorites.addTeam(team.teamID);
        if (mounted) showSuccess(context, '${team.teamName} was added to your favourite teams.');
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
    return FutureBuilder<TeamDetails>(
      future: _future,
      builder: (context, snapshot) {
        final details = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(details?.team.teamName ?? 'Team'),
            actions: [
              if (details != null && _isFavorite != null)
                IconButton(
                  tooltip: _isFavorite! ? 'Remove from favourites' : 'Add to favourites',
                  onPressed: _busy ? null : () => _toggleFavorite(details.team),
                  icon: Icon(_isFavorite! ? Icons.favorite : Icons.favorite_border, color: AppColors.red),
                ),
            ],
          ),
          body: snapshot.hasError
              ? ErrorView(
                  error: snapshot.error!,
                  onRetry: () => setState(() {
                    _future = _load();
                  }),
                )
              : details == null
              ? const LoadingView()
              : _buildBody(details),
        );
      },
    );
  }

  Widget _buildBody(TeamDetails details) {
    final team = details.team;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: AppImage(path: team.logoUrl, size: 110, fit: BoxFit.contain, fallback: Icons.shield_outlined),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(team.teamName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 16),
        Text('Season ${details.seasonYear}', style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 8),
        StatGrid([
          StatTile('Points', formatNumber(details.seasonPoints)),
          StatTile('Wins', formatNumber(details.seasonWins)),
          StatTile('Podiums', formatNumber(details.seasonPodiums)),
        ]),
        const SizedBox(height: 12),
        InfoCard(
          title: 'Team',
          children: [
            InfoRow(Icons.location_city_outlined, 'Headquarters', team.baseCityName ?? '-'),
            InfoRow(Icons.flag_outlined, 'Country', team.country ?? '-'),
            InfoRow(Icons.person_outline, 'Team principal', team.teamPrincipal),
          ],
        ),
        const SizedBox(height: 12),
        InfoCard(
          title: 'Drivers ${details.seasonYear}',
          children: [
            if (details.drivers.isEmpty) const Text('No drivers in this season.', style: TextStyle(color: AppColors.muted)),
            for (final driver in details.drivers)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: AppImage(path: driver.photoUrl, size: 44, circle: true, fallback: Icons.person),
                title: Text(driver.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '#${driver.number} · ${driver.nationality ?? '-'}${driver.isReserveDriver ? ' · reserve' : ''}',
                  style: const TextStyle(color: AppColors.muted),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DriverDetailsScreen(driverId: driver.driverID))),
              ),
          ],
        ),
      ],
    );
  }
}
