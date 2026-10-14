import 'package:flutter/material.dart';

/// Dropdown filled from the API. Items are matched by id, so [initialId] works with freshly loaded objects.
class AsyncDropdown<T> extends StatefulWidget {
  final Future<List<T>> Function() load;
  final String label;
  final int? initialId;
  final int Function(T item) idOf;
  final String Function(T item) labelOf;
  final ValueChanged<T?> onChanged;

  /// Adds a first option with no value (used by list filters, e.g. "All seasons").
  final String? allLabel;

  /// Validation message shown under the field when nothing is selected.
  final String? requiredMessage;
  final String? forceErrorText;
  final IconData? icon;
  final bool enabled;

  const AsyncDropdown({
    super.key,
    required this.load,
    required this.label,
    this.initialId,
    required this.idOf,
    required this.labelOf,
    required this.onChanged,
    this.allLabel,
    this.requiredMessage,
    this.forceErrorText,
    this.icon,
    this.enabled = true,
  });

  @override
  State<AsyncDropdown<T>> createState() => _AsyncDropdownState<T>();
}

class _AsyncDropdownState<T> extends State<AsyncDropdown<T>> {
  List<T>? _items;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _failed = false);
    try {
      final items = await widget.load();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final prefix = widget.icon == null ? null : Icon(widget.icon);
    if (items == null) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: prefix,
          errorText: _failed ? 'Data could not be loaded.' : null,
          suffixIcon: _failed
              ? IconButton(tooltip: 'Try again', icon: const Icon(Icons.refresh), onPressed: _fetch)
              : const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
        ),
        child: const Text(''),
      );
    }

    final hasInitial = widget.initialId != null && items.any((e) => widget.idOf(e) == widget.initialId);
    return DropdownButtonFormField<int?>(
      initialValue: hasInitial ? widget.initialId : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: widget.label, prefixIcon: prefix),
      items: [
        if (widget.allLabel != null) DropdownMenuItem<int?>(value: null, child: Text(widget.allLabel!)),
        for (final item in items)
          DropdownMenuItem<int?>(
            value: widget.idOf(item),
            child: Text(widget.labelOf(item), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: widget.enabled ? (id) => widget.onChanged(id == null ? null : items.firstWhere((e) => widget.idOf(e) == id)) : null,
      validator: widget.requiredMessage == null ? null : (id) => id == null ? widget.requiredMessage : null,
      forceErrorText: widget.forceErrorText,
    );
  }
}
