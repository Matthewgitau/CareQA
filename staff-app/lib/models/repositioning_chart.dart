import 'package:flutter/material.dart';

class RepositioningChart {
  final String? id;
  final String serviceUserId;
  final DateTime chartDate;
  final List<RepositioningEntry> entries;
  final int totalRepositions;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;

  RepositioningChart({
    this.id,
    required this.serviceUserId,
    required this.chartDate,
    required this.entries,
    required this.totalRepositions,
    this.notes,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
  });

  factory RepositioningChart.fromJson(Map<String, dynamic> json) => RepositioningChart(
    id: json['id'],
    serviceUserId: json['service_user_id'],
    chartDate: DateTime.parse(json['chart_date']),
    entries: (json['entries'] as List).map((e) => RepositioningEntry.fromJson(e)).toList(),
    totalRepositions: json['total_repositions'],
    notes: json['notes'],
    createdBy: json['created_by'],
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    updatedBy: json['updated_by'],
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'service_user_id': serviceUserId,
    'chart_date': chartDate.toIso8601String(),
    'entries': entries.map((e) => e.toJson()).toList(),
    'total_repositions': totalRepositions,
    'notes': notes,
  };

  // Calculate total repositions
  int calculateTotalRepositions() {
    return entries.length;
  }

  // Check if any skin concerns
  bool hasSkinConcerns() {
    return entries.any((entry) => entry.skinCheck == 'Yes-Concern');
  }
}

class RepositioningEntry {
  final DateTime time;
  final String positionCode; // L, R, B, S, S30, S30R, U
  final String skinCheck; // 'Yes-NAD', 'Yes-Concern', 'No'
  final String? skinCheckNotes;
  final String staffInitials;

  RepositioningEntry({
    required this.time,
    required this.positionCode,
    required this.skinCheck,
    this.skinCheckNotes,
    required this.staffInitials,
  });

  factory RepositioningEntry.fromJson(Map<String, dynamic> json) => RepositioningEntry(
    time: DateTime.parse(json['time']),
    positionCode: json['position_code'],
    skinCheck: json['skin_check'],
    skinCheckNotes: json['skin_check_notes'],
    staffInitials: json['staff_initials'],
  );

  Map<String, dynamic> toJson() => {
    'time': time.toIso8601String(),
    'position_code': positionCode,
    'skin_check': skinCheck,
    'skin_check_notes': skinCheckNotes,
    'staff_initials': staffInitials,
  };

  // Get position description
  String getPositionDescription() {
    return RepositioningConstants.positionCodes[positionCode] ?? 'Unknown';
  }

  // Get skin check color
  Color getSkinCheckColor() {
    switch (skinCheck) {
      case 'Yes-NAD':
        return Colors.green; // No Abnormalities Detected
      case 'Yes-Concern':
        return Colors.red; // Concern
      case 'No':
        return Colors.orange; // Not checked
      default:
        return Colors.grey;
    }
  }

  // Get skin check icon
  IconData getSkinCheckIcon() {
    switch (skinCheck) {
      case 'Yes-NAD':
        return Icons.check_circle;
      case 'Yes-Concern':
        return Icons.warning;
      case 'No':
        return Icons.remove_circle;
      default:
        return Icons.circle;
    }
  }
}

// Constants for position codes
class RepositioningConstants {
  static const Map<String, String> positionCodes = {
    'L': 'Left side',
    'R': 'Right side',
    'B': 'Back (supine)',
    'S': 'Sitting',
    'S30': '30° tilt left',
    'S30R': '30° tilt right',
    'U': 'Up in chair',
  };

  static const List<String> positionOptions = [
    'L',
    'R',
    'B',
    'S',
    'S30',
    'S30R',
    'U',
  ];

  static const List<String> skinCheckOptions = [
    'Yes-NAD', // No Abnormalities Detected
    'Yes-Concern',
    'No',
  ];
}