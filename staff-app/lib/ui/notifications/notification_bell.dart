import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/notification.dart' as app_notification;
import '../../services/notification_service.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final _service = NotificationService(Supabase.instance.client);
  int _unreadCount = 0;
  List<app_notification.Notification> _recentNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _service.getNotifications(limit: 10);
      final unreadCount = await _service.getUnreadCount();
      setState(() {
        _recentNotifications = notifications;
        _unreadCount = unreadCount;
      });
    } catch (e) {
      // Silent fail for background loading
    }
  }

  void _showNotificationDropdown() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey)),
              ),
              child: Row(
                children: [
                  const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (_unreadCount > 0)
                    TextButton(
                      onPressed: () async {
                        await _service.markAllAsRead();
                        await _loadNotifications();
                        if (mounted) Navigator.pop(context);
                      },
                      child: const Text('Mark all read'),
                    ),
                ],
              ),
            ),
            if (_recentNotifications.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('No notifications', style: TextStyle(color: Colors.grey)),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _recentNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = _recentNotifications[index];
                    return ListTile(
                      leading: Icon(
                        notification.icon,
                        color: notification.priorityColor,
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        notification.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        notification.timeAgo,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      onTap: () async {
                        await _service.markAsRead(notification.id);
                        await _loadNotifications();
                        if (mounted) Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).then((_) => _loadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: _showNotificationDropdown,
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}