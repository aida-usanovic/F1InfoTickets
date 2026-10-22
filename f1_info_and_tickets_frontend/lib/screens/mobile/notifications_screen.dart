import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/providers.dart';
import '../../core/formatters.dart';
import '../../models/notification.dart';
import '../../state/notification_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feedback.dart';
import '../../widgets/mobile/infinite_list.dart';

/// Purchase confirmations and published results; tapping a notification marks it as read.
/// The list reloads by itself when polling (NotificationState) finds a new notification.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _provider = NotificationProvider();
  final _list = InfiniteListController();
  final Set<int> _read = {};
  bool _unreadOnly = false;
  late final NotificationState _notifications = context.read<NotificationState>();
  late int _revision;

  @override
  void initState() {
    super.initState();
    // Remember the revision the list was loaded with; a later one means a new notification arrived.
    _revision = _notifications.revision;
    _notifications.addListener(_onNotificationsChanged);
  }

  @override
  void dispose() {
    _notifications.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  void _onNotificationsChanged() {
    if (_notifications.revision == _revision) return;
    _revision = _notifications.revision;
    _read.clear();
    _list.reload();
  }

  Future<void> _markAllAsRead() async {
    try {
      await _provider.markAllAsRead();
      if (!mounted) return;
      showSuccess(context, 'All notifications were marked as read.');
      _read.clear();
      _list.reload();
      _notifications.refresh();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _markAsRead(AppNotification n) async {
    if (n.isRead || _read.contains(n.notificationID)) return;
    try {
      await _provider.markAsRead(n.notificationID);
      if (mounted) setState(() => _read.add(n.notificationID));
      _notifications.refresh();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [IconButton(tooltip: 'Mark all as read', onPressed: _markAllAsRead, icon: const Icon(Icons.done_all))],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Unread only'),
            value: _unreadOnly,
            onChanged: (v) {
              setState(() => _unreadOnly = v);
              _list.reload();
            },
          ),
          Expanded(
            child: InfiniteList<AppNotification>(
              controller: _list,
              load: (page) => _provider.get(page: page, unreadOnly: _unreadOnly),
              emptyMessage: _unreadOnly ? 'You have no unread notifications.' : 'You have no notifications yet.',
              itemBuilder: (context, n) {
                final unread = !n.isRead && !_read.contains(n.notificationID);
                return Card(
                  child: ListTile(
                    onTap: () => _markAsRead(n),
                    leading: Icon(
                      unread ? Icons.notifications_active : Icons.notifications_none,
                      color: unread ? AppColors.red : AppColors.muted,
                    ),
                    title: Text(n.title, style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w500)),
                    subtitle: Text('${n.message}\n${formatDateTime(n.createdAt)}', style: const TextStyle(color: AppColors.muted)),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
