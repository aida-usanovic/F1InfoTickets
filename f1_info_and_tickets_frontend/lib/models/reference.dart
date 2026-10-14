class Continent {
  final int continentID;
  final String name;

  Continent({required this.continentID, required this.name});

  factory Continent.fromJson(Map<String, dynamic> json) => Continent(continentID: json['continentID'], name: json['name']);
}

class Country {
  final int countryID;
  final String name;
  final String code;
  final int continentID;
  final String? continentName;

  Country({required this.countryID, required this.name, required this.code, required this.continentID, this.continentName});

  factory Country.fromJson(Map<String, dynamic> json) => Country(
    countryID: json['countryID'],
    name: json['name'],
    code: json['code'],
    continentID: json['continentID'],
    continentName: json['continentName'],
  );
}

class City {
  final int cityID;
  final String name;
  final int countryID;
  final String? countryName;

  City({required this.cityID, required this.name, required this.countryID, this.countryName});

  String get label => countryName == null ? name : '$name, $countryName';

  factory City.fromJson(Map<String, dynamic> json) =>
      City(cityID: json['cityID'], name: json['name'], countryID: json['countryID'], countryName: json['countryName']);
}

class TrackType {
  final int trackTypeID;
  final String name;
  final String? description;

  TrackType({required this.trackTypeID, required this.name, this.description});

  factory TrackType.fromJson(Map<String, dynamic> json) =>
      TrackType(trackTypeID: json['trackTypeID'], name: json['name'], description: json['description']);
}

class TicketType {
  final int ticketTypeID;
  final String name;
  final String? description;

  TicketType({required this.ticketTypeID, required this.name, this.description});

  factory TicketType.fromJson(Map<String, dynamic> json) =>
      TicketType(ticketTypeID: json['ticketTypeID'], name: json['name'], description: json['description']);
}

class Season {
  final int seasonID;
  final int year;
  final String description;

  Season({required this.seasonID, required this.year, required this.description});

  factory Season.fromJson(Map<String, dynamic> json) =>
      Season(seasonID: json['seasonID'], year: json['year'], description: json['description']);
}
