import '../core/api_client.dart';

/// Shared client for the non-CRUD providers.
class BaseApi {
  static ApiClient get api => ApiClient.instance;
}
