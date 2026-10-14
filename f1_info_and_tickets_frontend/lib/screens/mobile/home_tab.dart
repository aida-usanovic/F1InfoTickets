import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/providers.dart';
import '../../core/formatters.dart';
import '../../models/race.dart';
import '../../models/reference.dart';
import '../../models/result.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_image.dart';
import '../../widgets/mobile/mobile_widgets.dart';
import '../../widgets/state_views.dart';
import 'driver_details_screen.dart';
import 'race_details_screen.dart';
import 'race_tickets_screen.dart';
import 'team_details_screen.dart';

class _HomeData {
  final Race? nextRace;
  final Season? season;
  final List<DriverStanding> drivers;
  final List<TeamStanding> teams;
  final List<Race> recommended;

  _HomeData(this.nextRace, this.season, this.drivers, this.teams, this.recommended);
}

/// Next race, a slideshow of drivers and teams, the top 3 of the season and recommended races.
class HomeTab extends StatefulWidget {
  /// Opens another bottom-bar tab (index as in the shell).
  final ValueChanged<int> onOpenTab;

  const HomeTab({super.key, required this.onOpenTab});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late Future<_HomeData> _future = _load();

  Future<_HomeData> _load() async {
    final races = RaceProvider();
    final upcoming = await races.getUpcoming();
    final season = await SeasonProvider().getCurrent();
    final results = ResultProvider();
    final drivers = season == null ? <DriverStanding>[] : await results.getDriverStandings(season.seasonID);
    final teams = season == null ? <TeamStanding>[] : await results.getTeamStandings(season.seasonID);
    final recommended = await races.getRecommendations();
    return _HomeData(upcoming.firstOrNull, season, drivers, teams, recommended);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future.catchError((_) => _HomeData(null, null, [], [], []));
  }

  void _openRace(Race race) => Navigator.push(context, MaterialPageRoute(builder: (_) => RaceDetailsScreen(raceId: race.raceID)));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorView(error: snapshot.error!, onRetry: _refresh);
        final data = snapshot.data;
        if (data == null) return const LoadingView();
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (data.nextRace != null) _NextRaceCard(race: data.nextRace!, onDetails: () => _openRace(data.nextRace!)),
              if (data.drivers.isNotEmpty || data.teams.isNotEmpty) ...[
                const SectionTitle('Drivers & teams'),
                _Slideshow(drivers: data.drivers.take(10).toList(), teams: data.teams, season: data.season!),
              ],
              if (data.drivers.length >= 3) ...[
                SectionTitle(
                  'Top 3 drivers ${data.season!.year}',
                  action: TextButton(onPressed: () => widget.onOpenTab(1), child: const Text('Standings')),
                ),
                _Podium(drivers: data.drivers.take(3).toList()),
              ],
              SectionTitle(
                'Recommended for you',
                action: TextButton(onPressed: () => widget.onOpenTab(4), child: const Text('All races')),
              ),
              if (data.recommended.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Browse races and buy tickets to get recommendations.', style: TextStyle(color: AppColors.muted)),
                )
              else
                for (final race in data.recommended)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: RaceCard(race: race, showPrice: true, onTap: () => _openRace(race)),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _NextRaceCard extends StatelessWidget {
  final Race race;
  final VoidCallback onDetails;

  const _NextRaceCard({required this.race, required this.onDetails});

  String get _countdown {
    final now = DateTime.now();
    final days = DateTime(race.date.year, race.date.month, race.date.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    return switch (days) {
      <= 0 => 'Today',
      1 => 'Tomorrow',
      _ => 'In $days days',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [AppColors.red, AppColors.redDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'NEXT RACE',
                style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w700, color: Colors.white70),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  _countdown,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            race.raceName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text('${race.circuitName ?? '-'}\n${race.location ?? '-'}', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.event, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                formatDateTime(race.date),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                  onPressed: onDetails,
                  child: const Text('Race details'),
                ),
              ),
              if (race.minTicketPrice != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.red),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RaceTicketsScreen(race: race))),
                    child: const Text('Shop now'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Auto-advancing slideshow of the leading drivers and teams.
class _Slideshow extends StatefulWidget {
  final List<DriverStanding> drivers;
  final List<TeamStanding> teams;
  final Season season;

  const _Slideshow({required this.drivers, required this.teams, required this.season});

  @override
  State<_Slideshow> createState() => _SlideshowState();
}

class _SlideshowState extends State<_Slideshow> {
  final _controller = PageController(viewportFraction: 0.86);
  Timer? _timer;

  int get _count => widget.drivers.length + widget.teams.length;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients || _count == 0) return;
      final next = ((_controller.page ?? 0).round() + 1) % _count;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: _controller,
        itemCount: _count,
        itemBuilder: (context, i) {
          if (i < widget.drivers.length) {
            final d = widget.drivers[i];
            return _Slide(
              image: AppImage(path: d.photoUrl, size: 110, fallback: Icons.person),
              title: d.driverName,
              subtitle: d.teamName,
              trailing: '${formatNumber(d.totalPoints)} pts',
              position: i + 1,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DriverDetailsScreen(driverId: d.driverID))),
            );
          }
          final index = i - widget.drivers.length;
          final t = widget.teams[index];
          return _Slide(
            image: AppImage(path: t.logoUrl, size: 110, fit: BoxFit.contain, fallback: Icons.shield_outlined),
            title: t.teamName,
            subtitle: 'Constructors ${widget.season.year}',
            trailing: '${formatNumber(t.totalPoints)} pts',
            position: index + 1,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeamDetailsScreen(teamId: t.teamID, seasonId: widget.season.seasonID),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final Widget image;
  final String title;
  final String subtitle;
  final String trailing;
  final int position;
  final VoidCallback onTap;

  const _Slide({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.position,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                image,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PositionBadge(position),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                      Text(subtitle, style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 4),
                      Text(
                        trailing,
                        style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<DriverStanding> drivers;

  const _Podium({required this.drivers});

  @override
  Widget build(BuildContext context) {
    // Displayed as 2 - 1 - 3 like a real podium.
    final order = [1, 0, 2];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final i in order)
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DriverDetailsScreen(driverId: drivers[i].driverID))),
                child: Column(
                  children: [
                    AppImage(path: drivers[i].photoUrl, size: i == 0 ? 76 : 62, circle: true, fallback: Icons.person),
                    const SizedBox(height: 6),
                    Text(
                      drivers[i].driverName.split(' ').last,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('${formatNumber(drivers[i].totalPoints)} pts', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 6),
                    Container(
                      height: i == 0 ? 70 : (i == 1 ? 52 : 40),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: [AppColors.gold, AppColors.silver, AppColors.bronze][i],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
