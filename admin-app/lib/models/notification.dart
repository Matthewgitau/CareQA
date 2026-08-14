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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'priority': priority,
      'read': read,
      'read_at': readAt?.toIso8601String(),
      'delivered': delivered,
      'delivered_at': deliveredAt?.toIso8601String(),
      'action_required': actionRequired,
      'action_url': actionUrl,
      'action_label': actionLabel,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
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
      case 'shift_swap_request':
        return Icons.swap_horiz;
      case 'shift_swap_approved':
        return Icons.check_circle;
      case 'time_off_approved':
        return Icons.verified;
      case 'time_off_rejected':
        return Icons.cancel;
      case 'document_expiring':
        return Icons.warning;
      case 'document_expired':
        return Icons.error;
      case 'training_due':
        return Icons.school;
      case 'training_overdue':
        return Icons.warning_amber;
      case 'competency_expiring':
        return Icons.workspace_premium;
      case 'incident_reported':
        return Icons.report;
      case 'safeguarding_alert':
        return Icons.security;
      case 'complaint_raised':
        return Icons.feedback;
      case 'action_plan_assigned':
        return Icons.assignment;
      case 'action_plan_overdue':
        return Icons.alarm;
      case 'invoice_generated':
        return Icons.receipt;
      case 'payment_received':
        return Icons.payments;
      case 'message_received':
        return Icons.message;
      case 'announcement':
        return Icons.campaign;
      case 'system_alert':
        return Icons.system_update;
      default:
        return Icons.notifications;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'shift_assigned':
        return 'Shift Assigned';
      case 'shift_cancelled':
        return 'Shift Cancelled';
      case 'shift_swap_request':
        return 'Shift Swap Request';
      case 'shift_swap_approved':
        return 'Shift Swap Approved';
      case 'time_off_approved':
        return 'Time Off Approved';
      case 'time_off_rejected':
        return 'Time Off Rejected';
      case 'document_expiring':
        return 'Document Expiring';
      case 'document_expired':
        return 'Document Expired';
      case 'training_due':
        return 'Training Due';
      case 'training_overdue':
        return 'Training Overdue';
      case 'competency_expiring':
        return 'Competency Expiring';
      case 'incident_reported':
        return 'Incident Reported';
      case 'safeguarding_alert':
        return 'Safeguarding Alert';
      case 'complaint_raised':
        return 'Complaint Raised';
      case 'action_plan_assigned':
        return 'Action Plan Assigned';
      case 'action_plan_overdue':
        return 'Action Plan Overdue';
      case 'invoice_generated':
        return 'Invoice Generated';
      case 'payment_received':
        return 'Payment Received';
      case 'message_received':
        return 'Message Received';
      case 'announcement':
        return 'Announcement';
      case 'system_alert':
        return 'System Alert';
      default:
        return 'Notification';
    }
  }
}