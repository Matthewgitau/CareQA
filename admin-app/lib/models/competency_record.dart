import 'package:flutter/material.dart';

/// Represents a competency record for staff training and assessment tracking.
/// This model is used across all competency types (Medication, Manual Handling, etc.)
class CompetencyRecord {
  final String id;
  final String staffId;
  final String? staffName;
  final String competencyType;
  final DateTime completedDate;
  final DateTime? expiryDate;
  final String status; // 'valid', 'expiring', 'expired'
  final String outcome; // 'pass', 'fail', 'requires_training'
  final String? assessorId;
  final String? assessorName;
  final Map<String, dynamic>? answers;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  CompetencyRecord({
    required this.id,
    required this.staffId,
    this.staffName,
    required this.competencyType,
    required this.completedDate,
    this.expiryDate,
    required this.status,
    required this.outcome,
    this.assessorId,
    this.assessorName,
    this.answers,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompetencyRecord.fromJson(Map<String, dynamic> json) {
    return CompetencyRecord(
      id: json['id'] ?? '',
      staffId: json['staff_id'] ?? '',
      staffName: json['staff_name'],
      competencyType: json['competency_type'] ?? '',
      completedDate: json['completed_date'] != null 
          ? DateTime.parse(json['completed_date']) 
          : DateTime.now(),
      expiryDate: json['expiry_date'] != null 
          ? DateTime.parse(json['expiry_date']) 
          : null,
      status: json['status'] ?? 'valid',
      outcome: json['outcome'] ?? 'pass',
      assessorId: json['assessor_id'],
      assessorName: json['assessor_name'],
      answers: json['answers'] != null 
          ? Map<String, dynamic>.from(json['answers']) 
          : null,
      notes: json['notes'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staff_id': staffId,
      'staff_name': staffName,
      'competency_type': competencyType,
      'completed_date': completedDate.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'status': status,
      'outcome': outcome,
      'assessor_id': assessorId,
      'assessor_name': assessorName,
      'answers': answers,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if the competency is expiring within the given number of days
  bool isExpiringWithin(int days) {
    if (expiryDate == null) return false;
    return expiryDate!.difference(DateTime.now()).inDays <= days;
  }

  /// Check if the competency has expired
  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());

  /// Get days until expiry (negative if expired)
  int? get daysUntilExpiry => expiryDate?.difference(DateTime.now()).inDays;

  /// Get display color based on status
  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'expired':
        return Colors.red;
      case 'expiring':
        return Colors.orange;
      case 'valid':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Get display color based on outcome
  Color getOutcomeColor() {
    switch (outcome.toLowerCase()) {
      case 'pass':
        return Colors.green;
      case 'fail':
        return Colors.red;
      case 'requires_training':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Get status display text
  String getStatusDisplay() {
    switch (status.toLowerCase()) {
      case 'expired':
        return 'Expired';
      case 'expiring':
        return 'Expiring Soon';
      case 'valid':
        return 'Valid';
      default:
        return status;
    }
  }

  /// Get outcome display text
  String getOutcomeDisplay() {
    switch (outcome.toLowerCase()) {
      case 'pass':
        return 'Pass';
      case 'fail':
        return 'Fail';
      case 'requires_training':
        return 'Requires Training';
      default:
        return outcome;
    }
  }

  /// Get competency type display name
  String getCompetencyTypeDisplay() {
    switch (competencyType.toLowerCase()) {
      case 'medication':
        return 'Medication Competency';
      case 'manual_handling':
        return 'Manual Handling Competency';
      case 'catheter_care':
        return 'Catheter Care Competency';
      case 'spot_check':
        return 'Spot Check Competency';
      case 'pressure_prevention':
        return 'Pressure Prevention Competency';
      case 'infection_control':
        return 'Infection Control Competency';
      case 'fire_safety':
        return 'Fire Safety Competency';
      case 'first_aid':
        return 'First Aid Competency';
      case 'moving_handling':
        return 'Moving & Handling Competency';
      case 'safeguarding':
        return 'Safeguarding Competency';
      case 'dignity_respect':
        return 'Dignity & Respect Competency';
      case 'communication':
        return 'Communication Competency';
      default:
        return competencyType;
    }
  }

  /// Get icon for competency type
  IconData getCompetencyIcon() {
    switch (competencyType.toLowerCase()) {
      case 'medication':
        return Icons.medication;
      case 'manual_handling':
      case 'moving_handling':
        return Icons.fitness_center;
      case 'catheter_care':
        return Icons.water_drop;
      case 'spot_check':
        return Icons.search;
      case 'pressure_prevention':
        return Icons.accessibility_new;
      case 'infection_control':
        return Icons.sanitizer;
      case 'fire_safety':
        return Icons.local_fire_department;
      case 'first_aid':
        return Icons.medical_services;
      case 'safeguarding':
        return Icons.shield;
      case 'dignity_respect':
        return Icons.favorite;
      case 'communication':
        return Icons.chat;
      default:
        return Icons.workspace_premium;
    }
  }

  /// Create a new competency record
  factory CompetencyRecord.createNew({
    required String staffId,
    required String competencyType,
    String? assessorId,
    Map<String, dynamic>? answers,
    String? notes,
  }) {
    // Default expiry is 1 year from now
    final expiryDate = DateTime.now().add(const Duration(days: 365));
    
    return CompetencyRecord(
      id: '',
      staffId: staffId,
      competencyType: competencyType,
      completedDate: DateTime.now(),
      expiryDate: expiryDate,
      status: 'valid',
      outcome: 'pass',
      assessorId: assessorId,
      answers: answers,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Copy with method for updating specific fields
  CompetencyRecord copyWith({
    String? id,
    String? staffId,
    String? staffName,
    String? competencyType,
    DateTime? completedDate,
    DateTime? expiryDate,
    String? status,
    String? outcome,
    String? assessorId,
    String? assessorName,
    Map<String, dynamic>? answers,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompetencyRecord(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      competencyType: competencyType ?? this.competencyType,
      completedDate: completedDate ?? this.completedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      outcome: outcome ?? this.outcome,
      assessorId: assessorId ?? this.assessorId,
      assessorName: assessorName ?? this.assessorName,
      answers: answers ?? this.answers,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Summary statistics for a competency type
class CompetencySummary {
  final String competencyType;
  final int totalStaff;
  final int completedCount;
  final int expiringCount; // Expiring within 30 days
  final int expiredCount;
  final int validCount;

  CompetencySummary({
    required this.competencyType,
    required this.totalStaff,
    required this.completedCount,
    required this.expiringCount,
    required this.expiredCount,
    required this.validCount,
  });

  factory CompetencySummary.fromRecords(List<CompetencyRecord> records, int totalStaff) {
    int completed = 0;
    int expiring = 0;
    int expired = 0;
    int valid = 0;

    for (final record in records) {
      if (record.status == 'expired') {
        expired++;
      } else if (record.status == 'expiring') {
        expiring++;
      } else if (record.status == 'valid') {
        valid++;
      }
      completed++;
    }

    return CompetencySummary(
      competencyType: records.first.competencyType,
      totalStaff: totalStaff,
      completedCount: completed,
      expiringCount: expiring,
      expiredCount: expired,
      validCount: valid,
    );
  }
}

/// All available competency types
class CompetencyTypes {
  static const String medication = 'medication';
  static const String manualHandling = 'manual_handling';
  static const String catheterCare = 'catheter_care';
  static const String spotCheck = 'spot_check';
  static const String pressurePrevention = 'pressure_prevention';
  static const String infectionControl = 'infection_control';
  static const String fireSafety = 'fire_safety';
  static const String firstAid = 'first_aid';
  static const String movingHandling = 'moving_handling';
  static const String safeguarding = 'safeguarding';
  static const String dignityRespect = 'dignity_respect';
  static const String communication = 'communication';

  static List<Map<String, dynamic>> getAll() => [
    {'type': medication, 'name': 'Medication Competency', 'icon': Icons.medication},
    {'type': manualHandling, 'name': 'Manual Handling Competency', 'icon': Icons.fitness_center},
    {'type': catheterCare, 'name': 'Catheter Care Competency', 'icon': Icons.water_drop},
    {'type': spotCheck, 'name': 'Spot Check Competency', 'icon': Icons.search},
    {'type': pressurePrevention, 'name': 'Pressure Prevention Competency', 'icon': Icons.accessibility_new},
    {'type': infectionControl, 'name': 'Infection Control Competency', 'icon': Icons.sanitizer},
    {'type': fireSafety, 'name': 'Fire Safety Competency', 'icon': Icons.local_fire_department},
    {'type': firstAid, 'name': 'First Aid Competency', 'icon': Icons.medical_services},
    {'type': movingHandling, 'name': 'Moving & Handling Competency', 'icon': Icons.accessibility},
    {'type': safeguarding, 'name': 'Safeguarding Competency', 'icon': Icons.shield},
    {'type': dignityRespect, 'name': 'Dignity & Respect Competency', 'icon': Icons.favorite},
    {'type': communication, 'name': 'Communication Competency', 'icon': Icons.chat},
  ];

  static String getDisplayName(String type) {
    final competency = getAll().firstWhere(
      (c) => c['type'] == type,
      orElse: () => {'name': type},
    );
    return competency['name'] as String;
  }

  static IconData getIcon(String type) {
    final competency = getAll().firstWhere(
      (c) => c['type'] == type,
      orElse: () => {'icon': Icons.workspace_premium},
    );
    return competency['icon'] as IconData;
  }
}