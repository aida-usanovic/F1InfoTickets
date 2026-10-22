import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/providers.dart';

/// Polls the API for notifications while the customer app is open, so the unread badge and an open
/// notification list update without any action from the user.
class NotificationState extends ChangeNotifier {
  static const pollInterval = Duration(seconds: 30);

  final _provider = NotificationProvider();
  Timer? _timer;
  int _unread = 0;
  int? _latestId;
  int _revision = 0;

  int get unread => _unread;

  /// Increases every time a new notification arrives; an open list reloads when it changes.
  int get revision => _revision;

  /// Starts polling (called when the customer app opens after sign-in).
  void start() {
    _timer ??= Timer.periodic(pollInterval, (_) => refresh());
    refresh();
  }

  /// Stops polling and forgets the user's data (called when the customer app closes, e.g. on sign-out).
  void stop() {
    _timer?.cancel();
    _timer = null;
    _unread = 0;
    _latestId = null;
  }

  Future<void> refresh() async {
    try {
      final unread = await _provider.unreadCount();
      final latest = await _provider.get(pageSize: 1);
      final latestId = latest.items.firstOrNull?.notificationID;
      final arrived = latestId != null && latestId != _latestId;
      if (arrived) _revision++;
      if (arrived || unread != _unread) {
        _unread = unread;
        _latestId = latestId;
        notifyListeners();
      }
    } catch (_) {
      // Polling must not interrupt the user; the next tick tries again.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
