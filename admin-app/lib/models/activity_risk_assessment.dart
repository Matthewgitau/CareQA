import 'package:supabase/supabase.dart';

enum ActivityType {
  bathing,
  dressing,
  toileting,
  mobility,
  eating,
  drinking,
  cooking,
  cleaning,
  shopping,
  appointments,
  visits,
  outings,
  hobbies,
  exercise,
  personalCare
}

enum FrequencyType {
  daily,
  multipleTimesPerDay,
  weekly,
  monthly,
  occasionally,
  asNeeded
}

enum SupportLevelType {
  independent,
  supervision,
  assistance,
  fullAssistance
}

class ActivityRiskAssessment {
  final String? id;
  final String serviceUserId;
  final String assessorId;
  final ActivityType activityType;
  final FrequencyType frequency;
  final SupportLevelType supportLevel;
  final List<String> equipmentRequired;
  final List<String> identifiedRisks;
  final String riskLevel;
  final List<String> controlMeasures;
  final List<String> staffCompetencyRequired;
  final String emergencyProcedures;
  final DateTime reviewDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final String? submittedBy;
  final DateTime? escalatedAt;
  final String? escalatedBy;
  final DateTime? completedAt;
  final String? completedBy;
  final String? notes;
  final Map<String, dynamic> assessmentData;

  ActivityRiskAssessment({
    this.id,
    required this.serviceUserId,
    required this.assessorId,
    required this.activityType,
    required this.frequency,
    required this.supportLevel,
    required this.equipmentRequired,
    required this.identifiedRisks,
    required this.riskLevel,
    required this.controlMeasures,
    required this.staffCompetencyRequired,
    required this.emergencyProcedures,
    required this.reviewDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.submittedAt,
    this.submittedBy,
    this.escalatedAt,
    this.escalatedBy,
    this.completedAt,
    this.completedBy,
    this.notes,
    required this.assessmentData,
  });

  factory ActivityRiskAssessment.fromMap(Map<String, dynamic> map) {
    return ActivityRiskAssessment(
      id: map['id'],
      serviceUserId: map['service_user_id'],
      assessorId: map['assessor_id'],
      activityType: _mapActivityType(map['activity_type']),
      frequency: _mapFrequencyType(map['frequency']),
      supportLevel: _mapSupportLevelType(map['support_level']),
      equipmentRequired: List<String>.from(map['equipment_required'] ?? []),
      identifiedRisks: List<String>.from(map['identified_risks'] ?? []),
      riskLevel: map['risk_level'],
      controlMeasures: List<String>.from(map['control_measures'] ?? []),
      staffCompetencyRequired: List<String>.from(map['staff_competency_required'] ?? []),
      emergencyProcedures: map['emergency_procedures'] ?? '',
      reviewDate: map['review_date'] != null ? DateTime.parse(map['review_date']).toLocal() : DateTime.now(),
      status: map['status'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']).toLocal() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']).toLocal() : DateTime.now(),
      submittedAt: map['submitted_at'] != null ? DateTime.parse(map['submitted_at']).toLocal() : null,
      submittedBy: map['submitted_by'],
      escalatedAt: map['escalated_at'] != null ? DateTime.parse(map['escalated_at']).toLocal() : null,
      escalatedBy: map['escalated_by'],
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at']).toLocal() : null,
      completedBy: map['completed_by'],
      notes: map['notes'],
      assessmentData: map['assessment_data'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'service_user_id': serviceUserId,
      'assessor_id': assessorId,
      'activity_type': _activityTypeToString(activityType),
      'frequency': _frequencyTypeToString(frequency),
      'support_level': _supportLevelTypeToString(supportLevel),
      'equipment_required': equipmentRequired,
      'identified_risks': identifiedRisks,
      'risk_level': riskLevel,
      'control_measures': controlMeasures,
      'staff_competency_required': staffCompetencyRequired,
      'emergency_procedures': emergencyProcedures,
      'review_date': reviewDate.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'notes': notes,
      'assessment_data': assessmentData,
    };
  }

  ActivityRiskAssessment copyWith({
    String? id,
    String? serviceUserId,
    String? assessorId,
    ActivityType? activityType,
    FrequencyType? frequency,
    SupportLevelType? supportLevel,
    List<String>? equipmentRequired,
    List<String>? identifiedRisks,
    String? riskLevel,
    List<String>? controlMeasures,
    List<String>? staffCompetencyRequired,
    String? emergencyProcedures,
    DateTime? reviewDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
    String? submittedBy,
    DateTime? escalatedAt,
    String? escalatedBy,
    DateTime? completedAt,
    String? completedBy,
    String? notes,
    Map<String, dynamic>? assessmentData,
  }) {
    return ActivityRiskAssessment(
      id: id ?? this.id,
      serviceUserId: serviceUserId ?? this.serviceUserId,
      assessorId: assessorId ?? this.assessorId,
      activityType: activityType ?? this.activityType,
      frequency: frequency ?? this.frequency,
      supportLevel: supportLevel ?? this.supportLevel,
      equipmentRequired: equipmentRequired ?? this.equipmentRequired,
      identifiedRisks: identifiedRisks ?? this.identifiedRisks,
      riskLevel: riskLevel ?? this.riskLevel,
      controlMeasures: controlMeasures ?? this.controlMeasures,
      staffCompetencyRequired: staffCompetencyRequired ?? this.staffCompetencyRequired,
      emergencyProcedures: emergencyProcedures ?? this.emergencyProcedures,
      reviewDate: reviewDate ?? this.reviewDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      submittedBy: submittedBy ?? this.submittedBy,
      escalatedAt: escalatedAt ?? this.escalatedAt,
      escalatedBy: escalatedBy ?? this.escalatedBy,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      notes: notes ?? this.notes,
      assessmentData: assessmentData ?? this.assessmentData,
    );
  }

  // Risk calculation methods
  String calculateRiskLevel() {
    // Base risk based on activity type
    int baseRisk = _getBaseRiskScore();
    
    // Additional risk based on support level
    int supportRisk = _getSupportRiskScore();
    
    // Additional risk based on identified risks count
    int riskCount = identifiedRisks.length;
    int totalRisk = baseRisk + supportRisk + riskCount;

    if (totalRisk >= 8) return 'high';
    if (totalRisk >= 5) return 'medium';
    return 'low';
  }

  bool needsEscalation() {
    return calculateRiskLevel() == 'high' || 
           calculateRiskLevel() == 'extreme' ||
           identifiedRisks.contains('falls') ||
           identifiedRisks.contains('choking') ||
           identifiedRisks.contains('self_harm');
  }

  String getActivityTypeDisplay() {
    switch (activityType) {
      case ActivityType.bathing: return 'Bathing';
      case ActivityType.dressing: return 'Dressing';
      case ActivityType.toileting: return 'Toileting';
      case ActivityType.mobility: return 'Mobility';
      case ActivityType.eating: return 'Eating';
      case ActivityType.drinking: return 'Drinking';
      case ActivityType.cooking: return 'Cooking';
      case ActivityType.cleaning: return 'Cleaning';
      case ActivityType.shopping: return 'Shopping';
      case ActivityType.appointments: return 'Appointments';
      case ActivityType.visits: return 'Visits';
      case ActivityType.outings: return 'Outings';
      case ActivityType.hobbies: return 'Hobbies';
      case ActivityType.exercise: return 'Exercise';
      case ActivityType.personalCare: return 'Personal Care';
    }
  }

  String getFrequencyDisplay() {
    switch (frequency) {
      case FrequencyType.daily: return 'Daily';
      case FrequencyType.multipleTimesPerDay: return 'Multiple times per day';
      case FrequencyType.weekly: return 'Weekly';
      case FrequencyType.monthly: return 'Monthly';
      case FrequencyType.occasionally: return 'Occasionally';
      case FrequencyType.asNeeded: return 'As needed';
    }
  }

  String getSupportLevelDisplay() {
    switch (supportLevel) {
      case SupportLevelType.independent: return 'Independent';
      case SupportLevelType.supervision: return 'Supervision';
      case SupportLevelType.assistance: return 'Assistance';
      case SupportLevelType.fullAssistance: return 'Full Assistance';
    }
  }

  Map<String, dynamic> getSummary() {
    return {
      'activity_type': getActivityTypeDisplay(),
      'frequency': getFrequencyDisplay(),
      'support_level': getSupportLevelDisplay(),
      'risk_level': calculateRiskLevel(),
      'equipment_count': equipmentRequired.length,
      'risk_count': identifiedRisks.length,
      'control_count': controlMeasures.length,
      'competency_count': staffCompetencyRequired.length,
      'needs_escalation': needsEscalation(),
      'days_until_review': reviewDate.difference(DateTime.now()).inDays,
    };
  }

  // Private helper methods
  int _getBaseRiskScore() {
    switch (activityType) {
      case ActivityType.mobility:
      case ActivityType.bathing:
      case ActivityType.eating:
        return 3;
      case ActivityType.dressing:
      case ActivityType.toileting:
      case ActivityType.drinking:
        return 2;
      case ActivityType.cooking:
      case ActivityType.shopping:
      case ActivityType.appointments:
        return 2;
      case ActivityType.visits:
      case ActivityType.outings:
      case ActivityType.exercise:
        return 1;
      case ActivityType.cleaning:
      case ActivityType.hobbies:
      case ActivityType.personalCare:
        return 1;
    }
  }

  int _getSupportRiskScore() {
    switch (supportLevel) {
      case SupportLevelType.fullAssistance: return 3;
      case SupportLevelType.assistance: return 2;
      case SupportLevelType.supervision: return 1;
      case SupportLevelType.independent: return 0;
    }
  }

  static ActivityType _mapActivityType(String? value) {
    return ActivityType.values.firstWhere(
      (type) => _activityTypeToString(type) == value,
      orElse: () => ActivityType.personalCare,
    );
  }

  static FrequencyType _mapFrequencyType(String? value) {
    return FrequencyType.values.firstWhere(
      (type) => _frequencyTypeToString(type) == value,
      orElse: () => FrequencyType.daily,
    );
  }

  static SupportLevelType _mapSupportLevelType(String? value) {
    return SupportLevelType.values.firstWhere(
      (type) => _supportLevelTypeToString(type) == value,
      orElse: () => SupportLevelType.independent,
    );
  }

  static String _activityTypeToString(ActivityType type) {
    switch (type) {
      case ActivityType.bathing: return 'bathing';
      case ActivityType.dressing: return 'dressing';
      case ActivityType.toileting: return 'toileting';
      case ActivityType.mobility: return 'mobility';
      case ActivityType.eating: return 'eating';
      case ActivityType.drinking: return 'drinking';
      case ActivityType.cooking: return 'cooking';
      case ActivityType.cleaning: return 'cleaning';
      case ActivityType.shopping: return 'shopping';
      case ActivityType.appointments: return 'appointments';
      case ActivityType.visits: return 'visits';
      case ActivityType.outings: return 'outings';
      case ActivityType.hobbies: return 'hobbies';
      case ActivityType.exercise: return 'exercise';
      case ActivityType.personalCare: return 'personal_care';
    }
  }

  static String _frequencyTypeToString(FrequencyType type) {
    switch (type) {
      case FrequencyType.daily: return 'daily';
      case FrequencyType.multipleTimesPerDay: return 'multiple_times_per_day';
      case FrequencyType.weekly: return 'weekly';
      case FrequencyType.monthly: return 'monthly';
      case FrequencyType.occasionally: return 'occasionally';
      case FrequencyType.asNeeded: return 'as_needed';
    }
  }

  static String _supportLevelTypeToString(SupportLevelType type) {
    switch (type) {
      case SupportLevelType.independent: return 'independent';
      case SupportLevelType.supervision: return 'supervision';
      case SupportLevelType.assistance: return 'assistance';
      case SupportLevelType.fullAssistance: return 'full_assistance';
    }
  }
}