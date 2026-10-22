import '../core/json.dart';

class Race {
  final int raceID;
  final String raceName;
  final DateTime date;
  final int seasonID;
  final int seasonYear;
  final int circuitID;
  final String? circuitName;
  final String? location;
  final int countryID;
  final String? countryName;
  final int continentID;
  final String? continentName;
  final String? trackType;
  final int laps;
  final double circuitLength;
  final String? imageUrl;
  final double? minTicketPrice;
  final bool hasResults;
  final String? recommendationReason;

  /// Recommendations only: the ticket type the user buys most often, offered for this race.
  final int? recommendedTicketTypeID;
  final String? recommendedTicketType;
  final double? recommendedTicketPrice;

  Race({
    required this.raceID,
    required this.raceName,
    required this.date,
    required this.seasonID,
    required this.seasonYear,
    required this.circuitID,
    this.circuitName,
    this.location,
    required this.countryID,
    this.countryName,
    required this.continentID,
    this.continentName,
    this.trackType,
    required this.laps,
    required this.circuitLength,
    this.imageUrl,
    this.minTicketPrice,
    this.hasResults = false,
    this.recommendationReason,
    this.recommendedTicketTypeID,
    this.recommendedTicketType,
    this.recommendedTicketPrice,
  });

  bool get isUpcoming => date.isAfter(DateTime.now());

  factory Race.fromJson(Map<String, dynamic> json) => Race(
    raceID: json['raceID'],
    raceName: json['raceName'],
    date: parseDateTime(json['date']),
    seasonID: json['seasonID'],
    seasonYear: json['seasonYear'],
    circuitID: json['circuitID'],
    circuitName: json['circuitName'],
    location: json['location'],
    countryID: json['countryID'],
    countryName: json['countryName'],
    continentID: json['continentID'],
    continentName: json['continentName'],
    trackType: json['trackType'],
    laps: json['laps'],
    circuitLength: toDouble(json['circuitLength']),
    imageUrl: json['imageUrl'],
    minTicketPrice: json['minTicketPrice'] == null ? null : toDouble(json['minTicketPrice']),
    hasResults: json['hasResults'] ?? false,
    recommendationReason: json['recommendationReason'],
    recommendedTicketTypeID: json['recommendedTicketTypeID'],
    recommendedTicketType: json['recommendedTicketType'],
    recommendedTicketPrice: json['recommendedTicketPrice'] == null ? null : toDouble(json['recommendedTicketPrice']),
  );
}

/// A ticket offer for one race (ticket type, price and remaining seats).
class RaceTicketCategory {
  final int raceTicketCategoryID;
  final int raceID;
  final String? raceName;
  final DateTime raceDate;
  final int ticketTypeID;
  final String? ticketTypeName;
  final String? ticketTypeDescription;
  final double price;
  final int capacity;
  final int sold;
  final int available;

  RaceTicketCategory({
    required this.raceTicketCategoryID,
    required this.raceID,
    this.raceName,
    required this.raceDate,
    required this.ticketTypeID,
    this.ticketTypeName,
    this.ticketTypeDescription,
    required this.price,
    required this.capacity,
    required this.sold,
    required this.available,
  });

  factory RaceTicketCategory.fromJson(Map<String, dynamic> json) => RaceTicketCategory(
    raceTicketCategoryID: json['raceTicketCategoryID'],
    raceID: json['raceID'],
    raceName: json['raceName'],
    raceDate: parseDateTime(json['raceDate']),
    ticketTypeID: json['ticketTypeID'],
    ticketTypeName: json['ticketTypeName'],
    ticketTypeDescription: json['ticketTypeDescription'],
    price: toDouble(json['price']),
    capacity: json['capacity'],
    sold: json['sold'],
    available: json['available'],
  );
}
