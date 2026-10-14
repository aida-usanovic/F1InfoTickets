import 'package:flutter/material.dart';

import '../../api/providers.dart';
import '../../core/formatters.dart';
import '../../models/race.dart';
import '../../models/result.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mobile/mobile_widgets.dart';
import '../../widgets/state_views.dart';
import 'race_tickets_screen.dart';

/// Race information and, for finished races, the classification. Opening it is recorded for recommendations.
class RaceDetailsScreen extends StatefulWidget {
  final int raceId;

  const RaceDetailsScreen({super.key, required this.raceId});

  @override
  State<RaceDetailsScreen> createState() => _RaceDetailsScreenState();
}

class _RaceDetailsScreenState extends State<RaceDetailsScreen> {
  late Future<(Race, RaceResults?)> _future = _load();

  @override
  void initState() {
    super.initState();
    // Views feed the recommender; a failure here must not block the screen.
    RaceProvider().recordView(widget.raceId).catchError((_) {});
  }

  Future<(Race, RaceResults?)> _load() async {
    final race = await RaceProvider().getById(widget.raceId);
    final results = race.isUpcoming ? null : await ResultProvider().getRaceResults(widget.raceId);
    return (race, results);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(Race, RaceResults?)>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: Text(data?.$1.raceName ?? 'Race')),
          body: snapshot.hasError
              ? ErrorView(
                  error: snapshot.error!,
                  onRetry: () => setState(() {
                    _future = _load();
                  }),
                )
              : data == null
              ? const LoadingView()
              : _buildBody(data.$1, data.$2),
          bottomNavigationBar: data != null && data.$1.isUpcoming && data.$1.minTicketPrice != null
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RaceTicketsScreen(race: data.$1))),
                      icon: const Icon(Icons.confirmation_number_outlined),
                      label: Text('Buy tickets · from ${formatMoney(data.$1.minTicketPrice)}'),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(Race race, RaceResults? results) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(race.raceName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(
          race.isUpcoming ? 'Upcoming · ${formatDateTime(race.date)}' : 'Finished · ${formatDateTime(race.date)}',
          style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        InfoCard(
          title: 'Race information',
          children: [
            InfoRow(Icons.event_outlined, 'Date and time', formatDateTime(race.date)),
            InfoRow(Icons.route_outlined, 'Circuit', race.circuitName ?? '-'),
            InfoRow(Icons.location_on_outlined, 'Location', race.location ?? '-'),
            InfoRow(Icons.public, 'Continent', race.continentName ?? '-'),
            InfoRow(Icons.alt_route, 'Track type', race.trackType ?? '-'),
            InfoRow(Icons.loop, 'Laps', '${race.laps}'),
            InfoRow(Icons.straighten, 'Lap length', formatKm(race.circuitLength)),
            InfoRow(Icons.calendar_today_outlined, 'Season', '${race.seasonYear}'),
          ],
        ),
        if (results != null) ...[const SizedBox(height: 12), _ResultsCard(results)],
      ],
    );
  }
}

class _ResultsCard extends StatelessWidget {
  final RaceResults results;

  const _ResultsCard(this.results);

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Results',
      children: [
        if (results.results.isEmpty) const Text('Results have not been published yet.', style: TextStyle(color: AppColors.muted)),
        for (final r in results.results)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: PositionBadge(r.position),
            title: Text(r.driverName ?? '-', style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${r.teamName ?? '-'} · ${r.timeTaken}', style: const TextStyle(color: AppColors.muted)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (r.isFastestLap)
                  const Tooltip(
                    message: 'Fastest lap',
                    child: Icon(Icons.timer, color: Colors.purpleAccent, size: 18),
                  ),
                const SizedBox(width: 6),
                Text('${formatNumber(r.points)} pts', style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
      ],
    );
  }
}
