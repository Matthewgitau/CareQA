import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/message.dart';
import '../../services/message_service.dart';

class MessageComposeScreen extends StatefulWidget {
  final String? replyToMessageId;
  final String? recipientId;
  final String? recipientName;

  const MessageComposeScreen({
    super.key,
    this.replyToMessageId,
    this.recipientId,
    this.recipientName,
  });

  @override
  State<MessageComposeScreen> createState() => _MessageComposeScreenState();
}

class _MessageComposeScreenState extends State<MessageComposeScreen> {
  final _service = MessageService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  final _actionNotesController = TextEditingController();

  String? _selectedRecipientId;
  String? _selectedRecipientName;
  String _messageType = 'direct';
  String _priority = 'normal';
  bool _isAnonymous = false;
  bool _actionRequired = false;
  DateTime? _actionDeadline;
  bool _isLoading = false;
  List<Map<String, dynamic>> _attachments = [];

  @override
  void initState() {
    super.initState();
    if (widget.recipientId != null) {
      _selectedRecipientId = widget.recipientId;
      _selectedRecipientName = widget.recipientName;
    }
    if (widget.replyToMessageId != null) {
      _loadReplyMessage();
    }
  }

  Future<void> _loadReplyMessage() async {
    final message = await _service.getMessage(widget.replyToMessageId!);
    if (message != null) {
      setState(() {
        _selectedRecipientId = message.senderId;
        _selectedRecipientName = message.senderName;
        _subjectController.text = 'Re: ${message.subject}';
        _contentController.text = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.replyToMessageId != null ? 'Reply' : 'Compose Message'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _sendMessage,
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.replyToMessageId == null) ...[
              // Recipient Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recipient', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _selectedRecipientName,
                        decoration: const InputDecoration(
                          labelText: 'Search staff member',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        readOnly: true,
                        onTap: _showRecipientPicker,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Message Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Subject is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Message Type
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Message Type',
                        border: OutlineInputBorder(),
                      ),
                      value: _messageType,
                      items: const [
                        DropdownMenuItem(value: 'direct', child: Text('Direct')),
                        DropdownMenuItem(value: 'broadcast', child: Text('Broadcast')),
                        DropdownMenuItem(value: 'shift_notification', child: Text('Shift Notification')),
                        DropdownMenuItem(value: 'policy_update', child: Text('Policy Update')),
                        DropdownMenuItem(value: 'training_reminder', child: Text('Training Reminder')),
                        DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
                      ],
                      onChanged: (v) => setState(() => _messageType = v ?? 'direct'),
                    ),
                    const SizedBox(height: 16),

                    // Priority
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      value: _priority,
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(value: 'normal', child: Text('Normal')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                        DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
                      ],
                      onChanged: (v) => setState(() => _priority = v ?? 'normal'),
                    ),
                    const SizedBox(height: 16),

                    // Content
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Message *',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 8,
                      validator: (v) => v?.isEmpty ?? true ? 'Message is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Anonymous Toggle
                    SwitchListTile(
                      title: const Text('Send Anonymously'),
                      subtitle: const Text('Your identity will be hidden'),
                      value: _isAnonymous,
                      onChanged: (v) => setState(() => _isAnonymous = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),

                    // Action Required
                    SwitchListTile(
                      title: const Text('Action Required'),
                      subtitle: const Text('Recipient must take action'),
                      value: _actionRequired,
                      onChanged: (v) => setState(() => _actionRequired = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_actionRequired) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _actionNotesController,
                        decoration: const InputDecoration(
                          labelText: 'Action Notes',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _pickActionDeadline,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Action Deadline',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _actionDeadline != null
                                ? '${_actionDeadline!.day}/${_actionDeadline!.month}/${_actionDeadline!.year}'
                                : 'Select date',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipientPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Recipient'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _getStaffMembers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No staff members found'));
              }
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final staff = snapshot.data![index];
                  return ListTile(
                    title: Text(staff['full_name'] ?? 'Unknown'),
                    subtitle: Text(staff['role'] ?? ''),
                    onTap: () {
                      setState(() {
                        _selectedRecipientId = staff['id']?.toString();
                        _selectedRecipientName = staff['full_name'];
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getStaffMembers() async {
    final response = await Supabase.instance.client
        .from('profiles')
        .select('id, full_name, role')
        .order('full_name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _pickActionDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _actionDeadline = picked);
    }
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRecipientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a recipient'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _service.sendMessage(
        recipientId: _selectedRecipientId!,
        recipientName: _selectedRecipientName!,
        subject: _subjectController.text,
        content: _contentController.text,
        messageType: _messageType,
        priority: _priority,
        isAnonymous: _isAnonymous,
        actionRequired: _actionRequired,
        actionDeadline: _actionDeadline,
        attachments: _attachments,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    _actionNotesController.dispose();
    super.dispose();
  }
}