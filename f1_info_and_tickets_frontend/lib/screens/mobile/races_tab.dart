import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/providers.dart';
import '../../core/paged_result.dart';
import '../../models/race.dart';
import '../../widgets/mobile/infinite_list.dart';
import '../../widgets/mobile/mobile_widgets.dart';
import 'race_details_screen.dart';

/// Upcoming or finished races with search and infinite scrolling.
class RacesTab extends StatefulWidget {
  const RacesTab({super.key});

  @override
  State<RacesTab> createState() => _RacesTabState();
}

class _RacesTabState extends State<RacesTab> {
  final _list = InfiniteListController();
  Timer? _debounce;
  bool _upcoming = true;
  String _search = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search = value.trim();
      _list.reload();
    });
  }

  // The server orders finished races newest first.
  Future<PagedResult<Race>> _load(int page) =>
      RaceProvider().get(filter: {'Upcoming': _upcoming, 'SearchTerm': _search, 'Page': page, 'PageSize': 10});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Upcoming'), icon: Icon(Icons.event_available)),
                    ButtonSegment(value: false, label: Text('Finished'), icon: Icon(Icons.sports_score)),
                  ],
                  selected: {_upcoming},
                  onSelectionChanged: (selection) {
                    setState(() => _upcoming = selection.first);
                    _list.reload();
                  },
                ),
              ),
              const SizedBox(height: 10),
              SearchField(hint: 'Search by race, circuit or country', onChanged: _onSearch),
            ],
          ),
        ),
        Expanded(
          child: InfiniteList<Race>(
            controller: _list,
            load: _load,
            emptyMessage: _upcoming ? 'No upcoming races found.' : 'No finished races found.',
            itemBuilder: (context, race) => RaceCard(
              race: race,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RaceDetailsScreen(raceId: race.raceID))),
            ),
          ),
        ),
      ],
    );
  }
}
