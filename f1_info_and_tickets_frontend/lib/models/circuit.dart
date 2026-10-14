import '../core/json.dart';

class Circuit {
  final int circuitID;
  final String name;
  final int cityID;
  final String? cityName;
  final int countryID;
  final String? countryName;
  final String? continentName;
  final int trackTypeID;
  final String? trackTypeName;
  final int laps;
  final double lengthKm;
  final String? imageUrl;

  Circuit({
    required this.circuitID,
    required this.name,
    required this.cityID,
    this.cityName,
    required this.countryID,
    this.countryName,
    this.continentName,
    required this.trackTypeID,
    this.trackTypeName,
    required this.laps,
    required this.lengthKm,
    this.imageUrl,
  });

  String get location => [cityName, countryName].whereType<String>().join(', ');

  factory Circuit.fromJson(Map<String, dynamic> json) => Circuit(
    circuitID: json['circuitID'],
    name: json['name'],
    cityID: json['cityID'],
    cityName: json['cityName'],
    countryID: json['countryID'],
    countryName: json['countryName'],
    continentName: json['continentName'],
    trackTypeID: json['trackTypeID'],
    trackTypeName: json['trackTypeName'],
    laps: json['laps'],
    lengthKm: toDouble(json['lengthKm']),
    imageUrl: json['imageUrl'],
  );
}
