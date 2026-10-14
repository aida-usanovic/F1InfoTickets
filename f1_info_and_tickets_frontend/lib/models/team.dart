import '../core/json.dart';
import 'driver.dart';

class Team {
  final int teamID;
  final String teamName;
  final int baseCityID;
  final String? baseCityName;
  final int countryID;
  final String? country;
  final String teamPrincipal;
  final String? logoUrl;

  Team({
    required this.teamID,
    required this.teamName,
    required this.baseCityID,
    this.baseCityName,
    required this.countryID,
    this.country,
    required this.teamPrincipal,
    this.logoUrl,
  });

  String get base => [baseCityName, country].whereType<String>().join(', ');

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    teamID: json['teamID'],
    teamName: json['teamName'],
    baseCityID: json['baseCityID'],
    baseCityName: json['baseCityName'],
    countryID: json['countryID'],
    country: json['country'],
    teamPrincipal: json['teamPrincipal'],
    logoUrl: json['logoUrl'],
  );
}

class TeamDetails {
  final Team team;
  final int seasonYear;
  final double seasonPoints;
  final int seasonWins;
  final int seasonPodiums;
  final List<Driver> drivers;

  TeamDetails({
    required this.team,
    required this.seasonYear,
    required this.seasonPoints,
    required this.seasonWins,
    required this.seasonPodiums,
    required this.drivers,
  });

  factory TeamDetails.fromJson(Map<String, dynamic> json) => TeamDetails(
    team: Team.fromJson(json['team']),
    seasonYear: json['seasonYear'],
    seasonPoints: toDouble(json['seasonPoints']),
    seasonWins: json['seasonWins'],
    seasonPodiums: json['seasonPodiums'],
    drivers: (json['drivers'] as List).map((e) => Driver.fromJson(e)).toList(),
  );
}
