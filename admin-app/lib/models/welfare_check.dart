import 'package:flutter/material.dart';

class WelfareCheck {
  final String id;
  final String? staffId;
  final String staffName;
  final String? employeeNumber;
  final String? jobRole;
  final String? department;
  final DateTime checkDate;
  final String checkTime;
  final String? checkType;
  final int? wellbeingScore;
  final int? stressScore;
  final int? jobSatisfactionScore;
  final int? workloadScore;
  final String? physicalHealthIssues;
  final String? recentIllness;
  final bool medicationImpact;
  final String? medicationImpactNotes;
  final String? anxietyLevel;
  final String? depressionSymptoms;
  final String? burnoutSymptoms;
  final String? sleepingIssues;
  final bool? workloadManageable;
  final bool? supportAvailable;
  final String? teamRelationships;
  final String? managerSupport;
  final String? workLifeBalance;
  final bool caringResponsibilities;
  final String? caringResponsibilitiesNotes;
  final List<String> identifiedStressors;
  final String? stressLevelTrend;
  final String? supportProvided;
  final bool referralMade;
  final String? referralType;
  final DateTime? referralDate;
  final bool followUpRequired;
  final DateTime? followUpDate;
  final String? actionPlan;
  final bool actionPlanCompleted;
  final DateTime? actionPlanCompletionDate;
  final String? checkedById;
  final String? checkedByName;
  final String? staffSignatureUrl;
  final String? managerSignatureUrl;
  final bool isConfidential;
  final bool shareWithManager;
  final String? notes;
  final String? organisationId;
  final String? createdById;
  final DateTime createdAt;
  final DateTime updatedAt;

  WelfareCheck({
    required this.id,
    this.staffId,
    required this.staffName,
    this.employeeNumber,
    this.jobRole,
    this.department,
    required this.checkDate,
    required this.checkTime,
    this.checkType,
    this.wellbeingScore,
    this.stressScore,
    this.jobSatisfactionScore,
    this.workloadScore,
    this.physicalHealthIssues,
    this.recentIllness,
    this.medicationImpact = false,
    this.medicationImpactNotes,
    this.anxietyLevel,
    this.depressionSymptoms,
    this.burnoutSymptoms,
    this.sleepingIssues,
    this.workloadManageable,
    this.supportAvailable,
    this.teamRelationships,
    this.managerSupport,
    this.workLifeBalance,
    this.caringResponsibilities = false,
    this.caringResponsibilitiesNotes,
    this.identifiedStressors = const [],
    this.stressLevelTrend,
    this.supportProvided,
    this.referralMade = false,
    this.referralType,
    this.referralDate,
    this.followUpRequired = false,
    this.followUpDate,
    this.actionPlan,
    this.actionPlanCompleted = false,
    this.actionPlanCompletionDate,
    this.checkedById,
    this.checkedByName,
    this.staffSignatureUrl,
    this.managerSignatureUrl,
    this.isConfidential = true,
    this.shareWithManager = true,
    this.notes,
    this.organisationId,
    this.createdById,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WelfareCheck.fromJson(Map<String, dynamic> json) {
    return WelfareCheck(
      id: json['id'] ?? '',
      staffId: json['staff_id'],
      staffName: json['staff_name'] ?? '',
      employeeNumber: json['employee_number'],
      jobRole: json['job_role'],
      department: json['department'],
      checkDate: json['check_date'] != null ? DateTime.parse(json['check_date']) : DateTime.now(),
      checkTime: json['check_time'] ?? '${DateTime.now().hour}:${DateTime.now().minute}',
      checkType: json['check_type'],
      wellbeingScore: json['wellbeing_score'],
      stressScore: json['stress_score'],
      jobSatisfactionScore: json['job_satisfaction_score'],
      workloadScore: json['workload_score'],
      physicalHealthIssues: json['physical_health_issues'],
      recentIllness: json['recent_illness'],
      medicationImpact: json['medication_impact'] ?? false,
      medicationImpactNotes: json['medication_impact_notes'],
      anxietyLevel: json['anxiety_level'],
      depressionSymptoms: json['depression_symptoms'],
      burnoutSymptoms: json['burnout_symptoms'],
      sleepingIssues: json['sleeping_issues'],
      workloadManageable: json['workload_manageable'],
      supportAvailable: json['support_available'],
      teamRelationships: json['team_relationships'],
      managerSupport: json['manager_support'],
      workLifeBalance: json['work_life_balance'],
      caringResponsibilities: json['caring_responsibilities'] ?? false,
      caringResponsibilitiesNotes: json['caring_responsibilities_notes'],
      identifiedStressors: json['identified_stressors'] != null ? List<String>.from(json['identified_stressors']) : [],
      stressLevelTrend: json['stress_level_trend'],
      supportProvided: json['support_provided'],
      referralMade: json['referral_made'] ?? false,
      referralType: json['referral_type'],
      referralDate: json['referral_date'] != null ? DateTime.parse(json['referral_date']) : null,
      followUpRequired: json['follow_up_required'] ?? false,
      followUpDate: json['follow_up_date'] != null ? DateTime.parse(json['follow_up_date']) : null,
      actionPlan: json['action_plan'],
      actionPlanCompleted: json['action_plan_completed'] ?? false,
      actionPlanCompletionDate: json['action_plan_completion_date'] != null ? DateTime.parse(json['action_plan_completion_date']) : null,
      checkedById: json['checked_by'],
      checkedByName: json['checked_by_name'],
      staffSignatureUrl: json['staff_signature_url'],
      managerSignatureUrl: json['manager_signature_url'],
      isConfidential: json['is_confidential'] ?? true,
      shareWithManager: json['share_with_manager'] ?? true,
      notes: json['notes'],
      organisationId: json['organisation_id'],
      createdById: json['created_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'staff_id': staffId,
      'staff_name': staffName,
      'employee_number': employeeNumber,
      'job_role': jobRole,
      'department': department,
      'check_date': checkDate.toIso8601String().split('T').first,
      'check_time': checkTime,
      'check_type': checkType,
      'wellbeing_score': wellbeingScore,
      'stress_score': stressScore,
      'job_satisfaction_score': jobSatisfactionScore,
      'workload_score': workloadScore,
      'physical_health_issues': physicalHealthIssues,
      'recent_illness': recentIllness,
      'medication_impact': medicationImpact,
      'medication_impact_notes': medicationImpactNotes,
      'anxiety_level': anxietyLevel,
      'depression_symptoms': depressionSymptoms,
      'burnout_symptoms': burnoutSymptoms,
      'sleeping_issues': sleepingIssues,
      'workload_manageable': workloadManageable,
      'support_available': supportAvailable,
      'team_relationships': teamRelationships,
      'manager_support': managerSupport,
      'work_life_balance': workLifeBalance,
      'caring_responsibilities': caringResponsibilities,
      'caring_responsibilities_notes': caringResponsibilitiesNotes,
      'identified_stressors': identifiedStressors,
      'stress_level_trend': stressLevelTrend,
      'support_provided': supportProvided,
      'referral_made': referralMade,
      'referral_type': referralType,
      'referral_date': referralDate?.toIso8601String().split('T').first,
      'follow_up_required': followUpRequired,
      'follow_up_date': followUpDate?.toIso8601String().split('T').first,
      'action_plan': actionPlan,
      'action_plan_completed': actionPlanCompleted,
      'action_plan_completion_date': actionPlanCompletionDate?.toIso8601String().split('T').first,
      'checked_by': checkedById,
      'checked_by_name': checkedByName,
      'staff_signature_url': staffSignatureUrl,
      'manager_signature_url': managerSignatureUrl,
      'is_confidential': isConfidential,
      'share_with_manager': shareWithManager,
      'notes': notes,
      'organisation_id': organisationId,
      'created_by': createdById,
    };
  }

  String getCheckTypeDisplay() {
    switch (checkType) {
      case 'annual_wellbeing': return 'Annual Wellbeing';
      case 'return_to_work': return 'Return to Work';
      case 'stress_risk_assessment': return 'Stress Risk Assessment';
      case 'health_questionnaire': return 'Health Questionnaire';
      case 'ergonomic_assessment': return 'Ergonomic Assessment';
      case 'mental_health_check': return 'Mental Health Check';
      case 'general_welfare': return 'General Welfare';
      case 'exit_interview': return 'Exit Interview';
      default: return checkType ?? 'Unknown';
    }
  }

  String getWellbeingStatus() {
    if (wellbeingScore == null) return 'Not assessed';
    if (wellbeingScore! >= 8) return 'Good';
    if (wellbeingScore! >= 5) return 'Moderate';
    return 'At Risk';
  }

  int getWellbeingColorValue() {
    if (wellbeingScore == null) return 0xFF9E9E9E; // grey
    if (wellbeingScore! >= 8) return 0xFF4CAF50; // green
    if (wellbeingScore! >= 5) return 0xFFFF9800; // orange
    return 0xFFF44336; // red
  }
}