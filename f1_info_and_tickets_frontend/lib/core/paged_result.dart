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
