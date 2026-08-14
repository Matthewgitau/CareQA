import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/message.dart';
import '../../services/message_service.dart';
import 'message_detail_screen.dart';

class WhistleblowerInboxScreen extends StatefulWidget {
  const WhistleblowerInboxScreen({super.key});

  @override
  State<WhistleblowerInboxScreen> createState() => _WhistleblowerInboxScreenState();
}

class _WhistleblowerInboxScreenState extends State<WhistleblowerInboxScreen> {
  final _service = MessageService(Supabase.instance.client);
  bool _loading = true;
  List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final messages = await _service.getMessages(
        messageType: 'whistleblower',
      );
      setState(() {
        _messages = messages;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String messageId, String status) async {
    try {
      await _service.markActionCompleted(messageId, notes: 'Status: $status');
      await _loadMessages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $status'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Whistleblower Inbox'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.visibility_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No whistleblower messages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Anonymous reports will appear here', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return Card(
                      color: Colors.red.shade50,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          child: const Icon(Icons.visibility_off, color: Colors.red),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                message.subject ?? 'Anonymous Report',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ANONYMOUS',
                                style: TextStyle(
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
                              'ID: ${message.anonymousId ?? 'Unknown'}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'monospace'),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message.content ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message.timeAgo,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        trailing: message.actionCompleted
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.pending, color: Colors.orange),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MessageDetailScreen(messageId: message.id!),
                            ),
                          );
                          if (result == true) {
                            _loadMessages();
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}