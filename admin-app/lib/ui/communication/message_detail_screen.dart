import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/message.dart';
import '../../services/message_service.dart';
import 'message_compose_screen.dart';

class MessageDetailScreen extends StatefulWidget {
  final String messageId;

  const MessageDetailScreen({super.key, required this.messageId});

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  final _service = MessageService(Supabase.instance.client);
  Message? _message;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessage();
  }

  Future<void> _loadMessage() async {
    final message = await _service.getMessage(widget.messageId);
    if (message != null && mounted) {
      // Mark as read
      await _service.markAsRead([message.id!]);
    }
    setState(() {
      _message = message;
      _loading = false;
    });
  }

  Future<void> _reply() async {
    if (_message == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageComposeScreen(
          replyToMessageId: _message!.id,
          recipientId: _message!.senderId,
          recipientName: _message!.senderName,
        ),
      ),
    );
    if (result == true) {
      _loadMessage();
    }
  }

  Future<void> _delete() async {
    if (_message == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteMessage(_message!.id!);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          if (_message != null) ...[
            IconButton(
              icon: const Icon(Icons.reply),
              onPressed: _reply,
              tooltip: 'Reply',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _delete,
              tooltip: 'Delete',
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _message == null
              ? const Center(child: Text('Message not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Priority Badge
                      if (_message!.isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _message!.priorityColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _message!.priorityLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Subject
                      Text(
                        _message!.subject ?? '',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Sender Info
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _message!.priorityColor.withOpacity(0.1),
                                child: Icon(_message!.icon, color: _message!.priorityColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _message!.senderName ?? 'Unknown',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      _message!.senderRole ?? '',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _message!.timeAgo,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Message Content
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _message!.content ?? '',
                            style: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Action Required
                      if (_message!.actionRequired) ...[
                        Card(
                          color: Colors.orange.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.orange.shade600),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Action Required',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                                if (_message!.actionDeadline != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Deadline: ${_message!.actionDeadline!.day}/${_message!.actionDeadline!.month}/${_message!.actionDeadline!.year}',
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                ],
                                if (_message!.actionNotes != null) ...[
                                  const SizedBox(height: 8),
                                  Text(_message!.actionNotes!),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Reply Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _reply,
                          icon: const Icon(Icons.reply),
                          label: const Text('Reply'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}