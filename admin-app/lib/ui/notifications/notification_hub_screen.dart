import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/notification.dart' as app_notification;
import '../../services/notification_service.dart';
import 'notification_item.dart';

class NotificationHubScreen extends StatefulWidget {
  const NotificationHubScreen({super.key});

  @override
  State<NotificationHubScreen> createState() => _NotificationHubScreenState();
}

class _NotificationHubScreenState extends State<NotificationHubScreen> with SingleTickerProviderStateMixin {
  final _service = NotificationService(Supabase.instance.client);
  bool _loading = true;
  List<app_notification.Notification> _notifications = [];
  int _unreadCount = 0;
  String? _filterType;
  String? _filterPriority;
  bool _showUnreadOnly = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final notifications = await _service.getNotifications(
        unreadOnly: _showUnreadOnly,
        type: _filterType,
        priority: _filterPriority,
      );
      final unreadCount = await _service.getUnreadCount();
      setState(() {
        _notifications = notifications;
        _unreadCount = unreadCount;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(app_notification.Notification notification) async {
    try {
      await _service.markAsRead(notification.id);
      await _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All notifications marked as read'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deleteNotification(app_notification.Notification notification) async {
    try {
      await _service.deleteNotification(notification.id);
      await _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications${_unreadCount > 0 ? " ($_unreadCount)" : ""}'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (index) {
            setState(() {
              switch (index) {
                case 0:
                  _showUnreadOnly = false;
                  _filterPriority = null;
                  break;
                case 1:
                  _showUnreadOnly = true;
                  _filterPriority = null;
                  break;
                case 2:
                  _showUnreadOnly = false;
                  _filterPriority = 'urgent';
                  break;
                case 3:
                  _showUnreadOnly = false;
                  _filterPriority = 'high';
                  break;
              }
              _loadNotifications();
            });
          },
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'Urgent'),
            Tab(text: 'High'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('All caught up!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('No notifications to show', style: TextStyle(color: Colors.grey)),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return NotificationItem(
                          notification: notification as app_notification.Notification,
                          onTap: () async {
                            await _markAsRead(notification);
                            if (notification.actionUrl != null) {
                              // Navigate to action URL
                            }
                          },
                          onDismiss: () => _deleteNotification(notification),
                        );
                      },
                    ),
            ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
              value: _filterType,
              items: const [
                DropdownMenuItem(value: 'shift_assigned', child: Text('Shift Assigned')),
                DropdownMenuItem(value: 'shift_cancelled', child: Text('Shift Cancelled')),
                DropdownMenuItem(value: 'training_due', child: Text('Training Due')),
                DropdownMenuItem(value: 'document_expiring', child: Text('Document Expiring')),
                DropdownMenuItem(value: 'safeguarding_alert', child: Text('Safeguarding Alert')),
                DropdownMenuItem(value: 'action_plan_assigned', child: Text('Action Plan Assigned')),
              ],
              onChanged: (v) => setState(() => _filterType = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
              value: _filterPriority,
              items: const [
                DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                DropdownMenuItem(value: 'low', child: Text('Low')),
              ],
              onChanged: (v) => setState(() => _filterPriority = v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterType = null;
                _filterPriority = null;
              });
              Navigator.pop(context);
              _loadNotifications();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadNotifications();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}