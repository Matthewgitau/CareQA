import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _notificationsFuture;
  late TabController _tabController;
  String? _currentUserId;
  String _selectedType = 'all';

  final List<String> _types = ['all', 'urgent', 'amber', 'routine', 'info'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUser();
    _notificationsFuture = _loadNotifications();
  }

  Future<void> _loadCurrentUser() async {
    final user = _supabase.auth.currentUser;
    setState(() {
      _currentUserId = user?.id;
    });
  }

  Future<List<Map<String, dynamic>>> _loadNotifications() async {
    if (_currentUserId == null) return [];

    var query = _supabase.from('notifications').select('*')
      .eq('user_id', _currentUserId!)
      .order('created_at', ascending: false);

    final response = await query;
    var notifications = List<Map<String, dynamic>>.from(response);

    // Filter by tab
    if (_tabController.index == 1) {
      notifications = notifications.where((n) => n['read'] == true).toList();
    } else {
      notifications = notifications.where((n) => n['read'] == false).toList();
    }

    // Filter by type
    if (_selectedType != 'all') {
      notifications = notifications.where((n) => n['type'] == _selectedType).toList();
    }

    return notifications;
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'urgent':
        return Colors.red;
      case 'amber':
        return Colors.orange;
      case 'routine':
        return Colors.blue;
      case 'info':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'urgent':
        return Icons.error;
      case 'amber':
        return Icons.warning;
      case 'routine':
        return Icons.info;
      case 'info':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _supabase.from('notifications').update({'read': true}).eq('id', notificationId);
      setState(() {
        _notificationsFuture = _loadNotifications();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark as read: $e')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _supabase.from('notifications').update({'read': true})
        .eq('user_id', _currentUserId!)
        .eq('read', false);
      setState(() {
        _notificationsFuture = _loadNotifications();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark all as read: $e')),
      );
    }
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getTypeIcon(notification['type']), color: _getTypeColor(notification['type'])),
            const SizedBox(width: 8),
            Expanded(child: Text(notification['title'] ?? 'Notification')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(notification['created_at'])),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(notification['body'] ?? ''),
          ],
        ),
        actions: [
          if (!notification['read'])
            TextButton(
              onPressed: () {
                _markAsRead(notification['id']);
                Navigator.pop(context);
              },
              child: const Text('Mark as Read'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedType = value;
                _notificationsFuture = _loadNotifications();
              });
            },
            itemBuilder: (context) => _types.map((t) {
              String display = t == 'all' ? 'All Types' : t[0].toUpperCase() + t.substring(1);
              return PopupMenuItem(value: t, child: Text(display));
            }).toList(),
            icon: const Icon(Icons.filter_list),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Unread'),
            Tab(text: 'Read'),
          ],
          onTap: (_) => setState(() {
            _notificationsFuture = _loadNotifications();
          }),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _tabController.index == 0 ? Icons.notifications_none : Icons.notifications_active,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _tabController.index == 0 ? 'No unread notifications' : 'No read notifications',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () => _loadNotifications(),
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isUnread = notification['read'] == false;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: isUnread ? Colors.orange.shade50 : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getTypeColor(notification['type']),
                      child: Icon(_getTypeIcon(notification['type']), color: Colors.white),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'] ?? 'Notification',
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getTypeColor(notification['type']),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notification['body'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        Text(
                          DateFormat('dd/MM HH:mm').format(DateTime.parse(notification['created_at'])),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    onTap: () => _showNotificationDetails(notification),
                    onLongPress: isUnread ? () => _markAsRead(notification['id']) : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}