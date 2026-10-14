import '../core/json.dart';

class Dashboard {
  final int totalUsers;
  final int totalDrivers;
  final int ticketsSold;
  final double totalRevenue;
  final int upcomingRaces;

  Dashboard({
    required this.totalUsers,
    required this.totalDrivers,
    required this.ticketsSold,
    required this.totalRevenue,
    required this.upcomingRaces,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) => Dashboard(
    totalUsers: json['totalUsers'],
    totalDrivers: json['totalDrivers'],
    ticketsSold: json['ticketsSold'],
    totalRevenue: toDouble(json['totalRevenue']),
    upcomingRaces: json['upcomingRaces'],
  );
}

class RaceSales {
  final int raceId;
  final String raceName;
  final DateTime raceDate;
  final int ticketsSold;
  final double totalRevenue;

  RaceSales({required this.raceId, required this.raceName, required this.raceDate, required this.ticketsSold, required this.totalRevenue});

  factory RaceSales.fromJson(Map<String, dynamic> json) => RaceSales(
    raceId: json['raceId'],
    raceName: json['raceName'],
    raceDate: parseDateTime(json['raceDate']),
    ticketsSold: json['ticketsSold'],
    totalRevenue: toDouble(json['totalRevenue']),
  );
}

class TicketTypeSales {
  final String ticketType;
  final int ticketsSold;
  final double totalRevenue;

  TicketTypeSales({required this.ticketType, required this.ticketsSold, required this.totalRevenue});

  factory TicketTypeSales.fromJson(Map<String, dynamic> json) =>
      TicketTypeSales(ticketType: json['ticketType'], ticketsSold: json['ticketsSold'], totalRevenue: toDouble(json['totalRevenue']));
}

class RaceAttendance {
  final int raceId;
  final String raceName;
  final DateTime raceDate;
  final int capacity;
  final int ticketsSold;
  final double occupancyPercent;

  RaceAttendance({
    required this.raceId,
    required this.raceName,
    required this.raceDate,
    required this.capacity,
    required this.ticketsSold,
    required this.occupancyPercent,
  });

  factory RaceAttendance.fromJson(Map<String, dynamic> json) => RaceAttendance(
    raceId: json['raceId'],
    raceName: json['raceName'],
    raceDate: parseDateTime(json['raceDate']),
    capacity: json['capacity'],
    ticketsSold: json['ticketsSold'],
    occupancyPercent: toDouble(json['occupancyPercent']),
  );
}

class CustomerActivity {
  final String username;
  final String fullName;
  final int ticketsPurchased;
  final double totalSpent;
  final DateTime? lastPurchase;
  final int raceViews;

  CustomerActivity({
    required this.username,
    required this.fullName,
    required this.ticketsPurchased,
    required this.totalSpent,
    this.lastPurchase,
    required this.raceViews,
  });

  factory CustomerActivity.fromJson(Map<String, dynamic> json) => CustomerActivity(
    username: json['username'],
    fullName: json['fullName'],
    ticketsPurchased: json['ticketsPurchased'],
    totalSpent: toDouble(json['totalSpent']),
    lastPurchase: parseDateTimeOrNull(json['lastPurchase']),
    raceViews: json['raceViews'],
  );
}

class UserActivity {
  final int totalUsersRegistered;
  final int activeBuyers;
  final int totalTicketsPurchased;
  final double totalRevenue;
  final int raceViews;
  final List<CustomerActivity> topCustomers;

  UserActivity({
    required this.totalUsersRegistered,
    required this.activeBuyers,
    required this.totalTicketsPurchased,
    required this.totalRevenue,
    required this.raceViews,
    required this.topCustomers,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) => UserActivity(
    totalUsersRegistered: json['totalUsersRegistered'],
    activeBuyers: json['activeBuyers'],
    totalTicketsPurchased: json['totalTicketsPurchased'],
    totalRevenue: toDouble(json['totalRevenue']),
    raceViews: json['raceViews'],
    topCustomers: (json['topCustomers'] as List).map((e) => CustomerActivity.fromJson(e)).toList(),
  );
}
