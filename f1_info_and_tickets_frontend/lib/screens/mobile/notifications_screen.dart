import 'package:flutter/material.dart';

import '../../api/providers.dart';
import '../../core/formatters.dart';
import '../../models/notification.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feedback.dart';
import '../../widgets/mobile/infinite_list.dart';

/// Purchase confirmations and published results; tapping a notification marks it as read.
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

  Future<void> _markAllAsRead() async {
    try {
      await _provider.markAllAsRead();
      if (!mounted) return;
      showSuccess(context, 'All notifications were marked as read.');
      _read.clear();
      _list.reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _markAsRead(AppNotification n) async {
    if (n.isRead || _read.contains(n.notificationID)) return;
    try {
      await _provider.markAsRead(n.notificationID);
      if (mounted) setState(() => _read.add(n.notificationID));
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
