import '../core/api_client.dart';
import '../core/paged_result.dart';

/// CRUD access to one API resource (GET with search/paging, GET by id, POST, PUT, DELETE).
abstract class BaseProvider<T> {
  final String endpoint;
  final ApiClient api = ApiClient.instance;

  BaseProvider(this.endpoint);

  T fromJson(Map<String, dynamic> json);

  /// [filter] holds the search object fields, e.g. {'SearchTerm': 'ham', 'Page': 1, 'PageSize': 10}.
  Future<PagedResult<T>> get({Map<String, dynamic>? filter}) async {
    final json = await api.get(endpoint, query: filter);
    return PagedResult.fromJson(json, fromJson);
  }

  /// All records for dropdowns; reads every page because the API returns at most 100 items per page.
  Future<List<T>> getAll({Map<String, dynamic>? filter}) async {
    const pageSize = 100;
    final items = <T>[];
    for (var page = 1; ; page++) {
      final result = await get(filter: {...?filter, 'Page': page, 'PageSize': pageSize});
      items.addAll(result.items);
      if (result.items.length < pageSize || items.length >= result.totalCount) return items;
    }
  }

  Future<T> getById(int id) async => fromJson(await api.get('$endpoint/$id'));

  Future<T> insert(Map<String, dynamic> request) async => fromJson(await api.post(endpoint, body: request));

  Future<T> update(int id, Map<String, dynamic> request) async => fromJson(await api.put('$endpoint/$id', body: request));

  Future<void> delete(int id) => api.delete('$endpoint/$id');
}
