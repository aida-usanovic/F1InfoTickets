import '../core/json.dart';

class Driver {
  final int driverID;
  final String firstName;
  final String lastName;
  final int number;
  final int countryID;
  final String? nationality;
  final DateTime birthDate;
  final bool isReserveDriver;
  final String? photoUrl;

  /// Only set in the per-season list (team in that season).
  final String? teamName;

  Driver({
    required this.driverID,
    required this.firstName,
    required this.lastName,
    required this.number,
    required this.countryID,
    this.nationality,
    required this.birthDate,
    required this.isReserveDriver,
    this.photoUrl,
    this.teamName,
  });

  String get fullName => '$firstName $lastName';

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
    driverID: json['driverID'],
    firstName: json['firstName'],
    lastName: json['lastName'],
    number: json['number'],
    countryID: json['countryID'],
    nationality: json['nationality'],
    birthDate: parseDate(json['birthDate']),
    isReserveDriver: json['isReserveDriver'],
    photoUrl: json['photoUrl'],
    teamName: json['teamName'],
  );
}

class DriverSeasonStats {
  final int year;
  final String? team;
  final int races;
  final int wins;
  final int podiums;
  final double points;

  DriverSeasonStats({required this.year, this.team, required this.races, required this.wins, required this.podiums, required this.points});

  factory DriverSeasonStats.fromJson(Map<String, dynamic> json) => DriverSeasonStats(
    year: json['year'],
    team: json['team'],
    races: json['races'],
    wins: json['wins'],
    podiums: json['podiums'],
    points: toDouble(json['points']),
  );
}

class DriverStats {
  final Driver driver;
  final String? currentTeam;
  final int age;
  final int races;
  final int wins;
  final int podiums;
  final int fastestLaps;
  final double totalPoints;
  final int? bestFinish;
  final List<DriverSeasonStats> seasons;

  DriverStats({
    required this.driver,
    this.currentTeam,
    required this.age,
    required this.races,
    required this.wins,
    required this.podiums,
    required this.fastestLaps,
    required this.totalPoints,
    this.bestFinish,
    required this.seasons,
  });

  factory DriverStats.fromJson(Map<String, dynamic> json) => DriverStats(
    driver: Driver.fromJson(json['driver']),
    currentTeam: json['currentTeam'],
    age: json['age'],
    races: json['races'],
    wins: json['wins'],
    podiums: json['podiums'],
    fastestLaps: json['fastestLaps'],
    totalPoints: toDouble(json['totalPoints']),
    bestFinish: json['bestFinish'],
    seasons: (json['seasons'] as List).map((e) => DriverSeasonStats.fromJson(e)).toList(),
  );
}
