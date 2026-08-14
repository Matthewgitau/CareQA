import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';

class MessageService {
  final SupabaseClient _client;

  MessageService(this._client);

  Future<List<Message>> getMessages({
    String? folder, // inbox, sent, archived, action_required
    bool? unreadOnly,
    String? priority,
    String? messageType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _client.from('messages').select();

      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      // Folder filtering
      if (folder == 'inbox' || folder == null) {
        query = query.eq('recipient_id', userId);
        query = query.filter('deleted_at', 'is', null);
      } else if (folder == 'sent') {
        query = query.eq('sender_id', userId);
      } else if (folder == 'archived') {
        query = query.eq('deleted_by', userId);
      } else if (folder == 'action_required') {
        query = query.eq('recipient_id', userId);
        query = query.eq('action_required', true);
        query = query.eq('action_completed', false);
      }

      // Additional filters
      if (unreadOnly == true) {
        query = query.eq('is_read', false);
      }
      if (priority != null) {
        query = query.eq('priority', priority);
      }
      if (messageType != null) {
        query = query.eq('message_type', messageType);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _client
          .from('messages')
          .select('id')
          .eq('recipient_id', userId)
          .eq('is_read', false)
          .filter('deleted_at', 'is', null);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  Future<Message?> getMessage(String messageId) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('id', messageId)
          .maybeSingle();

      if (response == null) return null;
      return Message.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<Message> sendMessage({
    required String recipientId,
    required String recipientName,
    required String subject,
    required String content,
    String? recipientRole,
    String messageType = 'direct',
    String priority = 'normal',
    bool isAnonymous = false,
    List<Map<String, dynamic>> attachments = const [],
    bool actionRequired = false,
    DateTime? actionDeadline,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Get sender details
      final senderProfile = await _client
          .from('profiles')
          .select('full_name, role')
          .eq('id', userId)
          .maybeSingle();

      final senderName = senderProfile?['full_name'] ?? 'Unknown';
      final senderRole = senderProfile?['role'] ?? 'admin';

      final orgId = await _getOrganisationId();
      if (orgId == null) throw Exception('No organisation found');

      final response = await _client.from('messages').insert({
        'sender_id': userId,
        'sender_name': senderName,
        'sender_role': senderRole,
        'recipient_id': recipientId,
        'recipient_name': recipientName,
        'recipient_role': recipientRole,
        'subject': subject,
        'content': content,
        'message_type': messageType,
        'priority': priority,
        'is_anonymous': isAnonymous,
        'attachments': attachments,
        'action_required': actionRequired,
        'action_deadline': actionDeadline?.toIso8601String().split('T')[0],
        'metadata': metadata,
        'organisation_id': orgId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      return Message.fromJson(response);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<Message> sendBroadcastMessage({
    required String subject,
    required String content,
    required List<String> recipientIds,
    String priority = 'normal',
    List<Map<String, dynamic>> attachments = const [],
    bool actionRequired = false,
    DateTime? actionDeadline,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final senderProfile = await _client
          .from('profiles')
          .select('full_name, role')
          .eq('id', userId)
          .maybeSingle();

      final senderName = senderProfile?['full_name'] ?? 'System';
      final senderRole = senderProfile?['role'] ?? 'admin';

      final orgId = await _getOrganisationId();
      if (orgId == null) throw Exception('No organisation found');

      // Send to all recipients
      final messages = <Map<String, dynamic>>[];
      for (final recipientId in recipientIds) {
        messages.add({
          'sender_id': userId,
          'sender_name': senderName,
          'sender_role': senderRole,
          'recipient_id': recipientId,
          'message_type': 'broadcast',
          'subject': subject,
          'content': content,
          'priority': priority,
          'attachments': attachments,
          'action_required': actionRequired,
          'action_deadline': actionDeadline?.toIso8601String().split('T')[0],
          'metadata': metadata,
          'organisation_id': orgId,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      final response = await _client.from('messages').insert(messages).select();
      return Message.fromJson((response as List).first);
    } catch (e) {
      throw Exception('Failed to send broadcast: $e');
    }
  }

  Future<Message> sendAnonymousMessage({
    required String recipientId,
    required String recipientName,
    required String subject,
    required String content,
    String messageType = 'whistleblower',
  }) async {
    try {
      final orgId = await _getOrganisationId();
      if (orgId == null) throw Exception('No organisation found');

      final anonymousId = 'anon_${DateTime.now().millisecondsSinceEpoch}';

      final response = await _client.from('messages').insert({
        'sender_id': null,
        'sender_name': 'Anonymous',
        'sender_role': 'system',
        'recipient_id': recipientId,
        'recipient_name': recipientName,
        'message_type': messageType,
        'subject': subject,
        'content': content,
        'is_anonymous': true,
        'anonymous_id': anonymousId,
        'priority': 'normal',
        'organisation_id': orgId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      return Message.fromJson(response);
    } catch (e) {
      throw Exception('Failed to send anonymous message: $e');
    }
  }

  Future<void> markAsRead(List<String> messageIds) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('messages').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).inFilter('id', messageIds).eq('recipient_id', userId);
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> markAsReplied(String messageId) async {
    try {
      await _client.from('messages').update({
        'is_replied': true,
        'replied_at': DateTime.now().toIso8601String(),
      }).eq('id', messageId);
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('messages').update({
        'deleted_by': userId,
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', messageId);
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> deleteForAll(String messageId) async {
    try {
      await _client.from('messages').update({
        'deleted_for_all': true,
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', messageId);
    } catch (e) {
      // Silent fail
    }
  }

  Future<List<Message>> getThread(String threadId) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('thread_id', threadId)
          .order('created_at', ascending: true);

      return (response as List).map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Message> replyToMessage({
    required String parentMessageId,
    required String content,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    try {
      final parentMessage = await getMessage(parentMessageId);
      if (parentMessage == null) throw Exception('Parent message not found');

      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final senderProfile = await _client
          .from('profiles')
          .select('full_name, role')
          .eq('id', userId)
          .maybeSingle();

      final senderName = senderProfile?['full_name'] ?? 'Unknown';
      final senderRole = senderProfile?['role'] ?? 'admin';

      final orgId = await _getOrganisationId();
      if (orgId == null) throw Exception('No organisation found');

      final response = await _client.from('messages').insert({
        'sender_id': userId,
        'sender_name': senderName,
        'sender_role': senderRole,
        'recipient_id': parentMessage.senderId,
        'recipient_name': parentMessage.senderName,
        'recipient_role': parentMessage.senderRole,
        'subject': 'Re: ${parentMessage.subject}',
        'content': content,
        'message_type': parentMessage.messageType,
        'priority': parentMessage.priority,
        'parent_message_id': parentMessageId,
        'thread_id': parentMessage.threadId ?? parentMessageId,
        'is_thread_start': false,
        'attachments': attachments,
        'organisation_id': orgId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      // Mark parent as replied
      await markAsReplied(parentMessageId);

      return Message.fromJson(response);
    } catch (e) {
      throw Exception('Failed to reply: $e');
    }
  }

  Future<List<Message>> getActionRequiredMessages() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('messages')
          .select()
          .eq('recipient_id', userId)
          .eq('action_required', true)
          .eq('action_completed', false)
          .filter('deleted_at', 'is', null)
          .order('action_deadline');

      return (response as List).map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> markActionCompleted(String messageId, {String? notes}) async {
    try {
      await _client.from('messages').update({
        'action_completed': true,
        'action_notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', messageId);
    } catch (e) {
      // Silent fail
    }
  }

  Future<String?> _getOrganisationId() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('profiles')
          .select('organisation_id')
          .eq('id', userId)
          .maybeSingle();

      return response?['organisation_id']?.toString();
    } catch (e) {
      return null;
    }
  }
}