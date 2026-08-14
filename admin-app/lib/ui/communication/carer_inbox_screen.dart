import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/message.dart';
import '../../services/message_service.dart';

class CarerInboxScreen extends StatefulWidget {
  const CarerInboxScreen({super.key});

  @override
  State<CarerInboxScreen> createState() => _CarerInboxScreenState();
}

class _CarerInboxScreenState extends State<CarerInboxScreen> with SingleTickerProviderStateMixin {
  final _service = MessageService(Supabase.instance.client);
  bool _loading = true;
  List<Message> _messages = [];
  int _unreadCount = 0;
  String _currentFolder = 'inbox';
  String? _filterPriority;
  String? _filterType;
  bool _selectionMode = false;
  final Set<String> _selectedMessages = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMessages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final messages = await _service.getMessages(
        folder: _currentFolder,
        priority: _filterPriority,
        messageType: _filterType,
      );
      final unreadCount = await _service.getUnreadCount();
      setState(() {
        _messages = messages;
        _unreadCount = unreadCount;
        _loading = false;
        _selectionMode = false;
        _selectedMessages.clear();
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead() async {
    if (_selectedMessages.isEmpty) return;
    try {
      await _service.markAsRead(_selectedMessages.toList());
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedMessages.isEmpty) return;
    try {
      for (final messageId in _selectedMessages) {
        await _service.deleteMessage(messageId);
      }
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _toggleSelection(String messageId) {
    setState(() {
      if (_selectedMessages.contains(messageId)) {
        _selectedMessages.remove(messageId);
      } else {
        _selectedMessages.add(messageId);
      }
      if (_selectedMessages.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Messages'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
              value: _filterPriority,
              items: const [
                DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
                DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                DropdownMenuItem(value: 'low', child: Text('Low')),
              ],
              onChanged: (v) => setState(() => _filterPriority = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Message Type', border: OutlineInputBorder()),
              value: _filterType,
              items: const [
                DropdownMenuItem(value: 'direct', child: Text('Direct')),
                DropdownMenuItem(value: 'broadcast', child: Text('Broadcast')),
                DropdownMenuItem(value: 'shift_notification', child: Text('Shift Notification')),
                DropdownMenuItem(value: 'policy_update', child: Text('Policy Update')),
                DropdownMenuItem(value: 'training_reminder', child: Text('Training Reminder')),
                DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
                DropdownMenuItem(value: 'whistleblower', child: Text('Whistleblower')),
              ],
              onChanged: (v) => setState(() => _filterType = v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterPriority = null;
                _filterType = null;
              });
              Navigator.pop(context);
              _loadMessages();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadMessages();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentFolder == 'inbox' ? 'Inbox' : _currentFolder == 'sent' ? 'Sent' : _currentFolder == 'archived' ? 'Archived' : 'Action Required'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          if (_selectionMode) ...[
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAsRead,
              tooltip: 'Mark as read',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
              tooltip: 'Delete',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: 'Filter',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Navigate to compose screen
              },
              tooltip: 'Compose',
            ),
          ],
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
                  _currentFolder = 'inbox';
                  break;
                case 1:
                  _currentFolder = 'sent';
                  break;
                case 2:
                  _currentFolder = 'action_required';
                  break;
                case 3:
                  _currentFolder = 'archived';
                  break;
              }
              _loadMessages();
            });
          },
          tabs: const [
            Tab(text: 'Inbox'),
            Tab(text: 'Sent'),
            Tab(text: 'Action'),
            Tab(text: 'Archived'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No messages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Your inbox is empty', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isSelected = _selectedMessages.contains(message.id);
                    return Card(
                      color: message.isUnread ? Colors.blue.shade50 : null,
                      child: ListTile(
                        leading: _selectionMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleSelection(message.id!),
                              )
                            : Icon(
                                message.icon,
                                color: message.priorityColor,
                              ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                message.subject ?? '',
                                style: TextStyle(
                                  fontWeight: message.isUnread ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (message.isUrgent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: message.priorityColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  message.priorityLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.senderName ?? 'Unknown',
                              style: TextStyle(
                                fontWeight: message.isUnread ? FontWeight.w600 : FontWeight.normal,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message.content ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message.timeAgo,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        trailing: message.actionRequired
                            ? Icon(Icons.check_circle, color: Colors.orange.shade600)
                            : null,
                        onTap: () {
                          if (_selectionMode) {
                            _toggleSelection(message.id!);
                          } else {
                            // Navigate to message detail
                          }
                        },
                        onLongPress: () {
                          setState(() {
                            _selectionMode = true;
                            _selectedMessages.add(message.id!);
                          });
                        },
                      ),
                    );
                  },
                ),
    );
  }
}