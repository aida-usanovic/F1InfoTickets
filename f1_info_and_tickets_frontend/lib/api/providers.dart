import '../core/paged_result.dart';
import '../models/analytics.dart';
import '../models/circuit.dart';
import '../models/driver.dart';
import '../models/notification.dart';
import '../models/race.dart';
import '../models/reference.dart';
import '../models/result.dart';
import '../models/team.dart';
import '../models/ticket.dart';
import '../models/user.dart';
import 'base_api.dart';
import 'base_provider.dart';

class ContinentProvider extends BaseProvider<Continent> {
  ContinentProvider() : super('Continent');
  @override
  Continent fromJson(Map<String, dynamic> json) => Continent.fromJson(json);
}

class CountryProvider extends BaseProvider<Country> {
  CountryProvider() : super('Country');
  @override
  Country fromJson(Map<String, dynamic> json) => Country.fromJson(json);
}

class CityProvider extends BaseProvider<City> {
  CityProvider() : super('City');
  @override
  City fromJson(Map<String, dynamic> json) => City.fromJson(json);
}

class TrackTypeProvider extends BaseProvider<TrackType> {
  TrackTypeProvider() : super('TrackType');
  @override
  TrackType fromJson(Map<String, dynamic> json) => TrackType.fromJson(json);
}

class TicketTypeProvider extends BaseProvider<TicketType> {
  TicketTypeProvider() : super('TicketType');
  @override
  TicketType fromJson(Map<String, dynamic> json) => TicketType.fromJson(json);
}

class RoleProvider extends BaseProvider<Role> {
  RoleProvider() : super('Role');
  @override
  Role fromJson(Map<String, dynamic> json) => Role.fromJson(json);
}

class SeasonProvider extends BaseProvider<Season> {
  SeasonProvider() : super('Season');
  @override
  Season fromJson(Map<String, dynamic> json) => Season.fromJson(json);

  /// Latest season that already has results (default for standings).
  Future<Season?> getCurrent() async {
    final json = await api.get('$endpoint/current');
    return json == null ? null : Season.fromJson(json);
  }
}

class CircuitProvider extends BaseProvider<Circuit> {
  CircuitProvider() : super('Circuit');
  @override
  Circuit fromJson(Map<String, dynamic> json) => Circuit.fromJson(json);
}

class UserProvider extends BaseProvider<User> {
  UserProvider() : super('User');
  @override
  User fromJson(Map<String, dynamic> json) => User.fromJson(json);
}

class DriverProvider extends BaseProvider<Driver> {
  DriverProvider() : super('Driver');
  @override
  Driver fromJson(Map<String, dynamic> json) => Driver.fromJson(json);

  /// Drivers are saved as multipart because of the photo.
  Future<Driver> save(Map<String, dynamic> fields, {int? id, String? imagePath}) async =>
      fromJson(await api.multipart(id == null ? 'POST' : 'PUT', id == null ? endpoint : '$endpoint/$id', fields, filePath: imagePath));

  Future<DriverStats> getStats(int id) async => DriverStats.fromJson(await api.get('$endpoint/$id/stats'));

  Future<List<Driver>> getBySeason(int seasonId) async =>
      (await api.get('$endpoint/season/$seasonId') as List).map((e) => fromJson(e)).toList();

  Future<List<Driver>> getByTeamAndSeason(int teamId, int seasonId) async =>
      (await api.get('$endpoint/team/$teamId/season/$seasonId') as List).map((e) => fromJson(e)).toList();
}

class TeamProvider extends BaseProvider<Team> {
  TeamProvider() : super('Team');
  @override
  Team fromJson(Map<String, dynamic> json) => Team.fromJson(json);

  Future<Team> save(Map<String, dynamic> fields, {int? id, String? imagePath}) async =>
      fromJson(await api.multipart(id == null ? 'POST' : 'PUT', id == null ? endpoint : '$endpoint/$id', fields, filePath: imagePath));

  Future<TeamDetails> getDetails(int teamId, {int? seasonId}) async =>
      TeamDetails.fromJson(await api.get('$endpoint/$teamId/details', query: {'seasonId': seasonId}));

  Future<void> addDriver(int teamId, int driverId, int seasonId) => api.post('$endpoint/$teamId/add-driver/$driverId/$seasonId');

  Future<void> removeDriver(int teamId, int driverId, int seasonId) => api.delete('$endpoint/$teamId/remove-driver/$driverId/$seasonId');
}

class RaceProvider extends BaseProvider<Race> {
  RaceProvider() : super('Race');
  @override
  Race fromJson(Map<String, dynamic> json) => Race.fromJson(json);

  Future<List<Race>> getUpcoming() async => (await api.get('$endpoint/upcoming') as List).map((e) => fromJson(e)).toList();

  /// Logged when a customer opens race details; used by the recommender.
  Future<void> recordView(int raceId) => api.post('$endpoint/$raceId/view');

  Future<List<Race>> getRecommendations() async => (await api.get('Recommender') as List).map((e) => fromJson(e)).toList();
}

class RaceTicketCategoryProvider extends BaseProvider<RaceTicketCategory> {
  RaceTicketCategoryProvider() : super('RaceTicketCategory');
  @override
  RaceTicketCategory fromJson(Map<String, dynamic> json) => RaceTicketCategory.fromJson(json);
}

class TicketProvider extends BaseProvider<Ticket> {
  TicketProvider() : super('Ticket');
  @override
  Ticket fromJson(Map<String, dynamic> json) => Ticket.fromJson(json);

  /// The signed-in customer's tickets; [upcoming] and [search] are applied on the server across all tickets.
  Future<PagedResult<Ticket>> getMine({int page = 1, int pageSize = 10, bool? upcoming, String? search}) async => PagedResult.fromJson(
    await api.get('$endpoint/my', query: {'Page': page, 'PageSize': pageSize, 'Upcoming': upcoming, 'SearchTerm': search}),
    fromJson,
  );
}

class ResultProvider {
  final _api = BaseApi.api;

  Future<RaceResults> getRaceResults(int raceId) async => RaceResults.fromJson(await _api.get('Result/race/$raceId'));

  /// [results]: [{'driverID', 'position', 'isFastestLap', 'timeTaken'}, ...]
  Future<RaceResults> saveRaceResults(int raceId, List<Map<String, dynamic>> results) async =>
      RaceResults.fromJson(await _api.put('Result/race/$raceId', body: {'results': results}));

  Future<List<DriverStanding>> getDriverStandings(int seasonId) async =>
      (await _api.get('Result/driver-standings/$seasonId') as List).map((e) => DriverStanding.fromJson(e)).toList();

  Future<List<TeamStanding>> getTeamStandings(int seasonId) async =>
      (await _api.get('Result/team-standings/$seasonId') as List).map((e) => TeamStanding.fromJson(e)).toList();
}

class FavoriteProvider {
  final _api = BaseApi.api;

  Future<List<Driver>> getDrivers() async => (await _api.get('Favorite/drivers') as List).map((e) => Driver.fromJson(e)).toList();
  Future<void> addDriver(int id) => _api.post('Favorite/drivers/$id');
  Future<void> removeDriver(int id) => _api.delete('Favorite/drivers/$id');

  Future<List<Team>> getTeams() async => (await _api.get('Favorite/teams') as List).map((e) => Team.fromJson(e)).toList();
  Future<void> addTeam(int id) => _api.post('Favorite/teams/$id');
  Future<void> removeTeam(int id) => _api.delete('Favorite/teams/$id');
}

class NotificationProvider {
  final _api = BaseApi.api;

  Future<PagedResult<AppNotification>> get({int page = 1, int pageSize = 20, bool unreadOnly = false}) async => PagedResult.fromJson(
    await _api.get('Notification', query: {'Page': page, 'PageSize': pageSize, 'UnreadOnly': unreadOnly ? true : null}),
    AppNotification.fromJson,
  );

  Future<int> unreadCount() async => (await _api.get('Notification/unread-count')) as int;
  Future<void> markAsRead(int id) => _api.put('Notification/$id/read');
  Future<void> markAllAsRead() => _api.put('Notification/read-all');
}

class ProfileProvider {
  final _api = BaseApi.api;

  Future<User> get() async => User.fromJson(await _api.get('Profile'));

  /// Multipart, because the request can contain a new profile photo ([imagePath]).
  Future<User> update(Map<String, dynamic> fields, {String? imagePath}) async =>
      User.fromJson(await _api.multipart('PUT', 'Profile', fields, filePath: imagePath));
  Future<void> changePassword(Map<String, dynamic> request) => _api.put('Profile/password', body: request);
}

class PaymentProvider {
  final _api = BaseApi.api;

  /// Starts a PayPal order for the current cart; the user approves it on [PaymentResponse.approvalUrl].
  Future<PaymentResponse> create({required String returnUrl, required String cancelUrl}) async =>
      PaymentResponse.fromJson(await _api.post('Payment/create', body: {'returnUrl': returnUrl, 'cancelUrl': cancelUrl}));

  Future<PaymentResponse> capture(String orderId) async =>
      PaymentResponse.fromJson(await _api.post('Payment/capture', body: {'orderId': orderId}));

  /// Refunds a whole purchase; all of its tickets are cancelled.
  Future<PaymentResponse> refund(int paymentId) async =>
      PaymentResponse.fromJson(await _api.post('Payment/refund', body: {'paymentId': paymentId}));
}

class AnalyticsProvider {
  final _api = BaseApi.api;

  Map<String, dynamic> _filter(int? seasonId, DateTime? from, DateTime? to) => {'SeasonID': seasonId, 'DateFrom': from, 'DateTo': to};

  Future<Dashboard> dashboard() async => Dashboard.fromJson(await _api.get('Analytics/dashboard'));

  Future<List<RaceSales>> ticketSales({int? seasonId, DateTime? from, DateTime? to}) async =>
      (await _api.get('Analytics/ticket-sales', query: _filter(seasonId, from, to)) as List).map((e) => RaceSales.fromJson(e)).toList();

  Future<List<TicketTypeSales>> ticketTypeSales({int? seasonId, DateTime? from, DateTime? to}) async =>
      (await _api.get('Analytics/ticket-type-sales', query: _filter(seasonId, from, to)) as List)
          .map((e) => TicketTypeSales.fromJson(e))
          .toList();

  Future<List<RaceAttendance>> attendance({int? seasonId, DateTime? from, DateTime? to}) async =>
      (await _api.get('Analytics/attendance', query: _filter(seasonId, from, to)) as List).map((e) => RaceAttendance.fromJson(e)).toList();

  Future<UserActivity> userActivity({int? seasonId, DateTime? from, DateTime? to}) async =>
      UserActivity.fromJson(await _api.get('Analytics/user-activity', query: _filter(seasonId, from, to)));
}
