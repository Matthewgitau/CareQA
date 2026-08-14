import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import '../models/message.dart';
import '../utils/supabase_client.dart';

class MessagingService {
  final SupabaseClient _client = SupabaseManager.instance.client;

  Future<List<Message>> getMessages(String organisationId) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('organisation_id', organisationId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  Future<Message> sendMessage(String senderId, String senderName, 
      String recipientId, String recipientName, String content, String organisationId) async {
    try {
      final message = Message(
        id: '',
        senderId: senderId,
        senderName: senderName,
        recipientId: recipientId,
        recipientName: recipientName,
        content: content,
        isRead: false,
        organisationId: organisationId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final response = await _client
          .from('messages')
          .insert(message.toJson())
          .single();

      return Message.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> markAsRead(String messageId) async {
    try {
      await _client
          .from('messages')
          .update({'is_read': true})
          .eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }
}