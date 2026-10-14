import 'package:flutter/material.dart';

import '../../core/paged_result.dart';
import '../state_views.dart';

class InfiniteListController {
  _InfiniteListState? _state;

  /// Starts again from the first page (after a filter or search change).
  void reload() => _state?._reset();
}

/// List that loads the next page from the API when the user scrolls near the end; pull down to refresh.
class InfiniteList<T> extends StatefulWidget {
  final Future<PagedResult<T>> Function(int page) load;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyMessage;
  final InfiniteListController? controller;

  const InfiniteList({super.key, required this.load, required this.itemBuilder, required this.emptyMessage, this.controller});

  @override
  State<InfiniteList<T>> createState() => _InfiniteListState<T>();
}

class _InfiniteListState<T> extends State<InfiniteList<T>> {
  final _scroll = ScrollController();
  final List<T> _items = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _loadMore();
    });
    _loadMore();
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller?._state = null;
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    _generation++;
    setState(() {
      _items.clear();
      _page = 0;
      _hasMore = true;
      _loading = false;
      _error = null;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    final generation = _generation;
    setState(() => _loading = true);
    try {
      final result = await widget.load(_page + 1);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items.addAll(result.items);
        _page++;
        _hasMore = _items.length < result.totalCount && result.items.isNotEmpty;
        _error = null;
      });
    } catch (e) {
      if (mounted && generation == _generation) setState(() => _error = e);
    } finally {
      if (mounted && generation == _generation) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (_items.isEmpty && _error != null) {
      content = ListView(
        children: [ErrorView(error: _error!, onRetry: _reset)],
      );
    } else if (_items.isEmpty && (_loading || _hasMore)) {
      content = const LoadingView();
    } else if (_items.isEmpty) {
      content = ListView(children: [EmptyView(message: widget.emptyMessage)]);
    } else {
      content = ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i < _items.length) return widget.itemBuilder(context, _items[i]);
          return _error != null
              ? TextButton.icon(onPressed: _loadMore, icon: const Icon(Icons.refresh), label: const Text('Load more'))
              : const LoadingView();
        },
      );
    }
    return RefreshIndicator(onRefresh: _reset, child: content);
  }
}
