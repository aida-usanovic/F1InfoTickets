import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/paged_result.dart';
import '../state_views.dart';

class TableColumnDef<T> {
  final String label;
  final Widget Function(T item) cell;
  final bool numeric;

  const TableColumnDef(this.label, this.cell, {this.numeric = false});
}

class RowAction<T> {
  final String tooltip;
  final IconData icon;
  final void Function(T item) onPressed;
  final Color? color;

  /// When it returns false the button is shown disabled (e.g. system roles cannot be deleted).
  final bool Function(T item)? isEnabled;

  const RowAction(this.tooltip, this.icon, this.onPressed, {this.color, this.isEnabled});
}

class PagedTableController {
  _PagedTableState? _state;

  /// Reloads the current page (after save/delete) or goes back to the first page (after a filter change).
  void reload({bool firstPage = false}) => _state?._load(page: firstPage ? 1 : null);
}

/// Server-side paged table with a search box, extra filters and per-row actions.
class PagedTable<T> extends StatefulWidget {
  /// Receives SearchTerm, Page and PageSize; the screen adds its own filters.
  final Future<PagedResult<T>> Function(Map<String, dynamic> query) load;
  final List<TableColumnDef<T>> columns;
  final List<RowAction<T>> actions;
  final PagedTableController? controller;
  final String searchHint;
  final List<Widget> filters;
  final List<Widget> toolbarActions;
  final String emptyMessage;

  const PagedTable({
    super.key,
    required this.load,
    required this.columns,
    this.actions = const [],
    this.controller,
    required this.searchHint,
    this.filters = const [],
    this.toolbarActions = const [],
    this.emptyMessage = 'No records.',
  });

  @override
  State<PagedTable<T>> createState() => _PagedTableState<T>();
}

class _PagedTableState<T> extends State<PagedTable<T>> {
  static const _pageSizes = [10, 20, 50];

  final _search = TextEditingController();
  Timer? _debounce;
  PagedResult<T>? _result;
  Object? _error;
  bool _loading = false;
  int _page = 1;
  int _pageSize = 10;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _load();
  }

  @override
  void didUpdateWidget(covariant PagedTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) widget.controller?._state = this;
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller?._state = null;
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({int? page}) async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      if (page != null) _page = page;
    });
    try {
      final result = await widget.load({'SearchTerm': _search.text.trim(), 'Page': _page, 'PageSize': _pageSize});
      if (!mounted || requestId != _requestId) return;
      // A delete can empty the last page; step back to the previous one.
      if (result.items.isEmpty && _page > 1) {
        _load(page: _page - 1);
        return;
      }
      setState(() {
        _result = result;
        _error = null;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _error = e);
    } finally {
      if (mounted && requestId == _requestId) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(page: 1));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: _search,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: widget.searchHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _search.clear();
                                  _onSearchChanged('');
                                },
                              ),
                      ),
                    ),
                  ),
                  ...widget.filters,
                ],
              ),
            ),
            for (final action in widget.toolbarActions) Padding(padding: const EdgeInsets.only(left: 12), child: action),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 3, child: _loading ? const LinearProgressIndicator() : null),
                Expanded(child: _buildContent()),
                const Divider(height: 1),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final result = _result;
    if (result == null) {
      return _error != null ? ErrorView(error: _error!, onRetry: _load) : const LoadingView();
    }
    if (result.items.isEmpty) {
      final term = _search.text.trim();
      return EmptyView(message: term.isEmpty ? widget.emptyMessage : 'No results for "$term".', icon: Icons.search_off);
    }
    // Desktop scroll views show their own scrollbars.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columns: [
                for (final column in widget.columns) DataColumn(label: Text(column.label), numeric: column.numeric),
                if (widget.actions.isNotEmpty) const DataColumn(label: Text('Actions')),
              ],
              rows: [for (final item in result.items) _buildRow(item)],
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(T item) {
    return DataRow(
      cells: [
        for (final column in widget.columns) DataCell(column.cell(item)),
        if (widget.actions.isNotEmpty)
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final action in widget.actions)
                  IconButton(
                    tooltip: action.tooltip,
                    icon: Icon(action.icon),
                    color: action.color,
                    onPressed: (action.isEnabled?.call(item) ?? true) ? () => action.onPressed(item) : null,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
    final result = _result;
    final total = result?.totalCount ?? 0;
    final pages = result?.totalPages ?? 1;
    final from = total == 0 ? 0 : (_page - 1) * _pageSize + 1;
    final to = total == 0 ? 0 : (from + (result?.items.length ?? 0) - 1);
    final canBack = _page > 1 && !_loading;
    final canForward = _page < pages && !_loading;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text('Showing $from–$to of $total'),
          const Spacer(),
          const Text('Per page:'),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _pageSize,
            underline: const SizedBox(),
            items: [for (final size in _pageSizes) DropdownMenuItem(value: size, child: Text('$size'))],
            onChanged: (size) {
              if (size == null) return;
              _pageSize = size;
              _load(page: 1);
            },
          ),
          const SizedBox(width: 16),
          IconButton(tooltip: 'First page', icon: const Icon(Icons.first_page), onPressed: canBack ? () => _load(page: 1) : null),
          IconButton(
            tooltip: 'Previous page',
            icon: const Icon(Icons.chevron_left),
            onPressed: canBack ? () => _load(page: _page - 1) : null,
          ),
          Text('Page $_page / $pages'),
          IconButton(
            tooltip: 'Next page',
            icon: const Icon(Icons.chevron_right),
            onPressed: canForward ? () => _load(page: _page + 1) : null,
          ),
          IconButton(
            tooltip: 'Last page',
            icon: const Icon(Icons.last_page),
            onPressed: canForward ? () => _load(page: pages) : null,
          ),
        ],
      ),
    );
  }
}
