import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import '../utils/supabase_client.dart';

class NotificationService {
  final SupabaseClient _client = SupabaseManager.instance.client;

  Future<void> sendNotification(String title, String message, String organisationId) async {
    try {
      await _client
          .from('notifications')
          .insert({
            'title': title,
            'message': message,
            'organisation_id': organisationId,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw Exception('Failed to send notification: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications(String organisationId) async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('organisation_id', organisationId)
          .order('created_at', ascending: false);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      throw Exception('Failed to load notifications: $e');
    }
  }
}