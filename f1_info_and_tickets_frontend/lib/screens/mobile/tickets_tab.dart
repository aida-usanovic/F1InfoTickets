import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/providers.dart';
import '../../models/race.dart';
import '../../models/reference.dart';
import '../../widgets/mobile/infinite_list.dart';
import '../../widgets/mobile/mobile_widgets.dart';
import 'race_tickets_screen.dart';

/// Upcoming races with ticket prices, filtered by continent.
class TicketsTab extends StatefulWidget {
  const TicketsTab({super.key});

  @override
  State<TicketsTab> createState() => _TicketsTabState();
}

class _TicketsTabState extends State<TicketsTab> {
  final _list = InfiniteListController();
  Timer? _debounce;
  List<Continent> _continents = [];
  int? _continentId;
  String _search = '';

  @override
  void initState() {
    super.initState();
    ContinentProvider()
        .getAll()
        .then((c) {
          if (mounted) setState(() => _continents = c);
        })
        .catchError((_) {});
  }

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

  void _selectContinent(int? id) {
    setState(() => _continentId = id);
    _list.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SearchField(hint: 'Search by race, circuit or country', onChanged: _onSearch),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(label: const Text('All'), selected: _continentId == null, onSelected: (_) => _selectContinent(null)),
              ),
              for (final c in _continents)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(c.name),
                    selected: _continentId == c.continentID,
                    onSelected: (_) => _selectContinent(c.continentID),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: InfiniteList<Race>(
            controller: _list,
            load: (page) => RaceProvider().get(
              filter: {'Upcoming': true, 'ContinentID': _continentId, 'SearchTerm': _search, 'Page': page, 'PageSize': 10},
            ),
            emptyMessage: 'No upcoming races match your filters.',
            itemBuilder: (context, race) => RaceCard(
              race: race,
              showPrice: true,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RaceTicketsScreen(race: race))),
            ),
          ),
        ),
      ],
    );
  }
}
