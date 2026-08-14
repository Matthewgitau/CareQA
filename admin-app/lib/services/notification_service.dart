import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

class NotificationService {
  final SupabaseClient _client;

  NotificationService(this._client);

  Future<List<Notification>> getNotifications({
    bool? unreadOnly,
    String? type,
    String? priority,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _client.from('notifications').select();

      if (unreadOnly == true) {
        query = query.eq('read', false);
      }
      if (type != null) {
        query = query.eq('type', type);
      }
      if (priority != null) {
        query = query.eq('priority', priority);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => Notification.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _client
          .from('notifications')
          .select('id')
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
      throw Exception('Failed to mark notification as read: $e');
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
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  Future<Notification> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String priority = 'normal',
    bool actionRequired = false,
    String? actionUrl,
    String? actionLabel,
    DateTime? expiresAt,
  }) async {
    try {
      final orgId = await _getOrganisationId();
      if (orgId == null) throw Exception('No organisation found');

      final response = await _client.from('notifications').insert({
        'user_id': userId,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'priority': priority,
        'action_required': actionRequired,
        'action_url': actionUrl,
        'action_label': actionLabel,
        'expires_at': expiresAt?.toIso8601String(),
        'created_by': _client.auth.currentUser?.id,
        'organisation_id': orgId,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      return Notification.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  Future<List<Notification>> getNotificationsByType(String type) async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('type', type)
          .order('created_at', ascending: false);
      
      return (response as List).map((json) => Notification.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications by type: $e');
    }
  }

  Future<List<Notification>> getUrgentNotifications() async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .or('priority.eq.urgent,priority.eq.high')
          .order('created_at', ascending: false);
      
      return (response as List).map((json) => Notification.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch urgent notifications: $e');
    }
  }

  Future<void> markAsDelivered(String notificationId) async {
    try {
      await _client.from('notifications').update({
        'delivered': true,
        'delivered_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as delivered: $e');
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