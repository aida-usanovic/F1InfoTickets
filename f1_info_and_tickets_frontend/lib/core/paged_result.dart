class PagedResult<T> {
  final int totalCount;
  final int page;
  final int pageSize;
  final List<T> items;

  PagedResult({required this.totalCount, required this.page, required this.pageSize, required this.items});

  factory PagedResult.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    return PagedResult(
      totalCount: json['totalCount'] as int,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      items: (json['items'] as List).map((e) => fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  int get totalPages => totalCount == 0 ? 1 : (totalCount / pageSize).ceil();
}

/// Loads every page of a paged endpoint, for short lists a screen needs complete (e.g. a team's line-up).
Future<List<T>> fetchAllPages<T>(Future<PagedResult<T>> Function(int page) load) async {
  final items = <T>[];
  for (var page = 1; ; page++) {
    final result = await load(page);
    items.addAll(result.items);
    if (result.items.isEmpty || items.length >= result.totalCount) return items;
  }
}
