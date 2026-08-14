import 'package:flutter/material.dart';

class Message {
  final String? id;
  final String? senderId;
  final String senderName;
  final String? senderRole;
  final String recipientId;
  final String recipientName;
  final String? recipientRole;
  final String subject;
  final String content;
  final String? messageType;
  final bool isAnonymous;
  final String? anonymousId;
  final String? priority;
  final bool isRead;
  final DateTime? readAt;
  final bool isReplied;
  final DateTime? repliedAt;
  final String? parentMessageId;
  final String? threadId;
  final bool isThreadStart;
  final List<Map<String, dynamic>> attachments;
  final bool actionRequired;
  final DateTime? actionDeadline;
  final bool actionCompleted;
  final String? actionNotes;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Message({
    this.id,
    this.senderId,
    required this.senderName,
    this.senderRole,
    required this.recipientId,
    required this.recipientName,
    this.recipientRole,
    required this.subject,
    required this.content,
    this.messageType = 'direct',
    this.isAnonymous = false,
    this.anonymousId,
    this.priority = 'normal',
    this.isRead = false,
    this.readAt,
    this.isReplied = false,
    this.repliedAt,
    this.parentMessageId,
    this.threadId,
    this.isThreadStart = true,
    this.attachments = const [],
    this.actionRequired = false,
    this.actionDeadline,
    this.actionCompleted = false,
    this.actionNotes,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString(),
      senderId: json['sender_id']?.toString(),
      senderName: json['sender_name'] ?? 'Unknown',
      senderRole: json['sender_role'],
      recipientId: json['recipient_id']?.toString() ?? '',
      recipientName: json['recipient_name'] ?? 'Unknown',
      recipientRole: json['recipient_role'],
      subject: json['subject'] ?? '',
      content: json['content'] ?? '',
      messageType: json['message_type'] ?? 'direct',
      isAnonymous: json['is_anonymous'] ?? false,
      anonymousId: json['anonymous_id'],
      priority: json['priority'] ?? 'normal',
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      isReplied: json['is_replied'] ?? false,
      repliedAt: json['replied_at'] != null ? DateTime.parse(json['replied_at']) : null,
      parentMessageId: json['parent_message_id']?.toString(),
      threadId: json['thread_id']?.toString(),
      isThreadStart: json['is_thread_start'] ?? true,
      attachments: json['attachments'] != null ? List<Map<String, dynamic>>.from(json['attachments']) : [],
      actionRequired: json['action_required'] ?? false,
      actionDeadline: json['action_deadline'] != null ? DateTime.parse(json['action_deadline']) : null,
      actionCompleted: json['action_completed'] ?? false,
      actionNotes: json['action_notes'],
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_role': senderRole,
      'recipient_id': recipientId,
      'recipient_name': recipientName,
      'recipient_role': recipientRole,
      'subject': subject,
      'content': content,
      'message_type': messageType,
      'is_anonymous': isAnonymous,
      'anonymous_id': anonymousId,
      'priority': priority,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'is_replied': isReplied,
      'replied_at': repliedAt?.toIso8601String(),
      'parent_message_id': parentMessageId,
      'thread_id': threadId,
      'is_thread_start': isThreadStart,
      'attachments': attachments,
      'action_required': actionRequired,
      'action_deadline': actionDeadline?.toIso8601String().split('T')[0],
      'action_completed': actionCompleted,
      'action_notes': actionNotes,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isUrgent => priority == 'urgent' || priority == 'emergency';
  bool get isUnread => !isRead;
  bool get isEmergency => priority == 'emergency';

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
      case 'emergency':
        return Colors.red;
      case 'urgent':
        return Colors.deepOrange;
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
    switch (messageType) {
      case 'emergency':
        return Icons.emergency;
      case 'whistleblower':
        return Icons.visibility_off;
      case 'broadcast':
        return Icons.campaign;
      case 'shift_notification':
        return Icons.schedule;
      case 'policy_update':
        return Icons.policy;
      case 'training_reminder':
        return Icons.school;
      default:
        return Icons.message;
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'emergency':
        return 'EMERGENCY';
      case 'urgent':
        return 'URGENT';
      case 'high':
        return 'HIGH';
      case 'normal':
        return 'NORMAL';
      case 'low':
        return 'LOW';
      default:
        return priority?.toUpperCase() ?? 'NORMAL';
    }
  }
}