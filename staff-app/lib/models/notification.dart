import 'package:flutter/material.dart';

class Notification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final String priority;
  final bool read;
  final DateTime? readAt;
  final bool delivered;
  final DateTime? deliveredAt;
  final bool actionRequired;
  final String? actionUrl;
  final String? actionLabel;
  final DateTime? expiresAt;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.priority = 'normal',
    this.read = false,
    this.readAt,
    this.delivered = false,
    this.deliveredAt,
    this.actionRequired = false,
    this.actionUrl,
    this.actionLabel,
    this.expiresAt,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      type: json['type'] ?? 'other',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      priority: json['priority'] ?? 'normal',
      read: json['read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      delivered: json['delivered'] ?? false,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
      actionRequired: json['action_required'] ?? false,
      actionUrl: json['action_url'],
      actionLabel: json['action_label'],
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  bool get isUrgent => priority == 'urgent';
  bool get isHigh => priority == 'high';
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inDays > 7) return '${(difference.inDays / 7).floor()}w';
    if (difference.inDays > 0) return '${difference.inDays}d';
    if (difference.inHours > 0) return '${difference.inHours}h';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m';
    return 'now';
  }

  Color get priorityColor {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'normal':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData get icon {
    switch (type) {
      case 'shift_assigned':
        return Icons.event_available;
      case 'shift_cancelled':
        return Icons.event_busy;
      case 'training_due':
        return Icons.school;
      case 'document_expiring':
        return Icons.warning;
      case 'safeguarding_alert':
        return Icons.security;
      case 'action_plan_assigned':
        return Icons.assignment;
      default:
        return Icons.notifications;
    }
  }
}