import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

class NotificationService {
  final SupabaseClient _client;

  NotificationService(this._client);

  Future<List<Notification>> getNotifications({int limit = 50, int offset = 0}) async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => Notification.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('read', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _client.from('notifications').update({
        'read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('notifications').update({
        'read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId).eq('read', false);
    } catch (e) {
      // Silent fail
    }
  }
}