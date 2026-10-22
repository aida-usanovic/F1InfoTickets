import '../core/json.dart';

class RaceResult {
  final int resultID;
  final int raceID;
  final int driverID;
  final String? driverName;
  final int teamID;
  final String? teamName;
  final int position;
  final double points;
  final bool isFastestLap;
  final String timeTaken;

  RaceResult({
    required this.resultID,
    required this.raceID,
    required this.driverID,
    this.driverName,
    required this.teamID,
    this.teamName,
    required this.position,
    required this.points,
    required this.isFastestLap,
    required this.timeTaken,
  });

  factory RaceResult.fromJson(Map<String, dynamic> json) => RaceResult(
    resultID: json['resultID'],
    raceID: json['raceID'],
    driverID: json['driverID'],
    driverName: json['driverName'],
    teamID: json['teamID'],
    teamName: json['teamName'],
    position: json['position'],
    points: toDouble(json['points']),
    isFastestLap: json['isFastestLap'],
    timeTaken: json['timeTaken'],
  );
}

/// Classification of one race plus whether it can still be edited (48h rule).
class RaceResults {
  final int raceID;
  final String raceName;
  final DateTime raceDate;
  final bool canEdit;
  final String? editInfo;
  final List<RaceResult> results;

  RaceResults({
    required this.raceID,
    required this.raceName,
    required this.raceDate,
    required this.canEdit,
    this.editInfo,
    required this.results,
  });

  factory RaceResults.fromJson(Map<String, dynamic> json) => RaceResults(
    raceID: json['raceID'],
    raceName: json['raceName'],
    raceDate: parseDateTime(json['raceDate']),
    canEdit: json['canEdit'],
    editInfo: json['editInfo'],
    results: (json['results'] as List).map((e) => RaceResult.fromJson(e)).toList(),
  );
}

class DriverStanding {
  final int position;
  final int driverID;
  final String driverName;
  final String? photoUrl;
  final String teamName;
  final double totalPoints;
  final int racesCompleted;
  final int bestFinish;

  DriverStanding({
    required this.position,
    required this.driverID,
    required this.driverName,
    this.photoUrl,
    required this.teamName,
    required this.totalPoints,
    required this.racesCompleted,
    required this.bestFinish,
  });

  factory DriverStanding.fromJson(Map<String, dynamic> json) => DriverStanding(
    position: json['position'],
    driverID: json['driverID'],
    driverName: json['driverName'],
    photoUrl: json['photoUrl'],
    teamName: json['teamName'],
    totalPoints: toDouble(json['totalPoints']),
    racesCompleted: json['racesCompleted'],
    bestFinish: json['bestFinish'],
  );
}

class TeamStanding {
  final int position;
  final int teamID;
  final String teamName;
  final String? logoUrl;
  final double totalPoints;
  final int driversCount;

  TeamStanding({
    required this.position,
    required this.teamID,
    required this.teamName,
    this.logoUrl,
    required this.totalPoints,
    required this.driversCount,
  });

  factory TeamStanding.fromJson(Map<String, dynamic> json) => TeamStanding(
    position: json['position'],
    teamID: json['teamID'],
    teamName: json['teamName'],
    logoUrl: json['logoUrl'],
    totalPoints: toDouble(json['totalPoints']),
    driversCount: json['driversCount'],
  );
}
