import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/notification.dart' as app_notification;
import '../../services/notification_service.dart';

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
  bool _showArchived = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    setState(() {
      switch (_tabController.index) {
        case 0:
          _showUnreadOnly = false;
          _showArchived = false;
          _filterPriority = null;
          break;
        case 1:
          _showUnreadOnly = true;
          _showArchived = false;
          _filterPriority = null;
          break;
        case 2:
          _showUnreadOnly = false;
          _showArchived = false;
          _filterPriority = 'urgent';
          break;
        case 3:
          _showUnreadOnly = false;
          _showArchived = false;
          _filterPriority = 'high';
          break;
        case 4:
          _showUnreadOnly = false;
          _showArchived = true;
          _filterPriority = null;
          break;
      }
    });
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final notifications = await _service.getNotifications(
        unreadOnly: _showUnreadOnly,
        type: _filterType,
        priority: _filterPriority,
        archivedOnly: _showArchived,
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
    // Optimistic local update - flip the read flag in the in-memory
    // list immediately so the user sees the result without us having
    // to re-fire every poller query.
    setState(() {
      _notifications = _notifications
          .map((n) => n.id == notification.id
              ? n.copyWith(read: true, readAt: DateTime.now())
              : n)
          .toList();
      if (!notification.read && _unreadCount > 0) _unreadCount -= 1;
    });
    try {
      await _service.markAsRead(notification.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _notifications = _notifications
          .map((n) => n.read ? n : n.copyWith(read: true, readAt: DateTime.now()))
          .toList();
      _unreadCount = 0;
    });
    try {
      await _service.markAllAsRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All notifications marked as read'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        await _loadNotifications();
      }
    }
  }

  Future<void> _deleteNotification(app_notification.Notification notification) async {
    // Optimistic: drop the row from the local list immediately.
    setState(() {
      _notifications = _notifications.where((n) => n.id != notification.id).toList();
    });
    try {
      await _service.deleteNotification(notification.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        await _loadNotifications();
      }
    }
  }

  Future<void> _archiveNotification(app_notification.Notification notification) async {
    // Optimistic: drop the row from the local list immediately.
    setState(() {
      _notifications = _notifications.where((n) => n.id != notification.id).toList();
    });
    try {
      await _service.archiveNotification(notification.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification archived'), backgroundColor: Colors.blueGrey),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        // Roll back on failure - re-fetch.
        await _loadNotifications();
      }
    }
  }

  Future<void> _unarchiveNotification(app_notification.Notification notification) async {
    // Optimistic: drop the row from the local (archived) list immediately.
    setState(() {
      _notifications = _notifications.where((n) => n.id != notification.id).toList();
    });
    try {
      await _service.unarchiveNotification(notification.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification restored'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        await _loadNotifications();
      }
    }
  }

  void _showNotificationActions(app_notification.Notification notification) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(notification.isArchived ? Icons.unarchive : Icons.archive),
              title: Text(notification.isArchived ? 'Restore from archive' : 'Archive'),
              subtitle: Text(notification.isArchived
                  ? 'Move this notification back to the active list'
                  : 'Hide this notification without deleting it'),
              onTap: () {
                Navigator.pop(sheetContext);
                if (notification.isArchived) {
                  _unarchiveNotification(notification);
                } else {
                  _archiveNotification(notification);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Permanently remove this notification'),
              onTap: () {
                Navigator.pop(sheetContext);
                _deleteNotification(notification);
              },
            ),
          ],
        ),
      ),
    );
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
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'Urgent'),
            Tab(text: 'High'),
            Tab(text: 'Archived'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 200),
                        Icon(
                          _showArchived
                              ? Icons.archive
                              : Icons.notifications_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showArchived
                              ? 'No archived notifications'
                              : 'All caught up!',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _showArchived
                              ? 'Notifications you archive will appear here'
                              : 'No notifications to show',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _NotificationExpansionTile(
                          notification: notification,
                          onTap: () async {
                            await _markAsRead(notification);
                          },
                          onLongPress: () => _showNotificationActions(notification),
                          onArchive: () => _archiveNotification(notification),
                          onUnarchive: () => _unarchiveNotification(notification),
                          onDelete: () => _deleteNotification(notification),
                          isArchivedView: _showArchived,
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
              initialValue: _filterType,
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
              initialValue: _filterPriority,
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

/// A single notification row wrapped in an [ExpansionTile] so the user
/// can collapse/expand the detail view. Long-press shows the action
/// menu (archive / unarchive / delete).
class _NotificationExpansionTile extends StatelessWidget {
  final app_notification.Notification notification;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onArchive;
  final VoidCallback onUnarchive;
  final VoidCallback onDelete;
  final bool isArchivedView;

  const _NotificationExpansionTile({
    required this.notification,
    required this.onTap,
    required this.onLongPress,
    required this.onArchive,
    required this.onUnarchive,
    required this.onDelete,
    required this.isArchivedView,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: notification.read ? 0 : 1,
      color: notification.read
          ? null
          : notification.priorityColor.withValues(alpha: 0.04),
      child: Theme(
        // Remove the default ExpansionTile divider
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: notification.priorityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              notification.icon,
              color: notification.priorityColor,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notification.title.isEmpty ? notification.typeLabel : notification.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (notification.isArchived)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.archive, size: 16, color: Colors.blueGrey),
                ),
              if (!notification.read)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${notification.timeAgo}  •  ${notification.typeLabel}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          onExpansionChanged: (_) {
            // When the tile is expanded the user has obviously seen the
            // notification - mark it as read automatically.
            if (!notification.read) onTap();
          },
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                notification.body,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
              ),
            ),
            if (notification.actionUrl != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Action: ${notification.actionLabel ?? notification.actionUrl}',
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!notification.read)
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('Mark read'),
                  ),
                if (isArchivedView)
                  TextButton.icon(
                    onPressed: onUnarchive,
                    icon: const Icon(Icons.unarchive, size: 18),
                    label: const Text('Restore'),
                  )
                else
                  TextButton.icon(
                    onPressed: onArchive,
                    icon: const Icon(Icons.archive, size: 18),
                    label: const Text('Archive'),
                  ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }
}