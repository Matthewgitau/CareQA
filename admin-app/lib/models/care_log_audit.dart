import 'package:flutter/material.dart';

class CareLogAudit {
  final String? id;
  final String dailyNoteId;
  final String serviceUserId;
  final String serviceUserName;
  final DateTime auditDate;
  final String auditorName;
  final String? auditorId;

  // Section 1: Completeness (0-2 each)
  final int? completenessBasicInfo;
  final int? completenessVisitType;
  final int? completenessCareAcceptance;
  final int? completenessEmotionalState;
  final int? completenessPadCheck;
  final int? completenessFoodFluid;
  final int? completenessMedication;
  final int? completenessObservations;
  final int? completenessIncidents;
  final int? completenessSignature;

  // Section 2: Accuracy (booleans)
  final bool? accuracyEmotionalStateMatch;
  final bool? accuracyFoodFluidAmounts;
  final bool? accuracyMedicationDetails;
  final bool? accuracySkinCondition;
  final bool? accuracyIncidentDetails;

  // Section 3: Compliance (booleans)
  final bool? complianceCareAct2014;
  final bool? complianceMca2005;
  final bool? complianceDols;
  final bool? complianceConfidentiality;
  final bool? complianceTimeliness;

  // Section 4: Quality (booleans)
  final bool? qualityProfessionalLanguage;
  final bool? qualityObjectiveObservations;
  final bool? qualityLegibilityReadability;
  final bool? qualityActionableInformation;
  final bool? qualityContinuityOfCare;

  // Section 5: Clinical Safety (booleans)
  final bool clinicalSafetyMedicationErrors;
  final bool clinicalSafetySafeguarding;
  final bool clinicalSafetyHealthDeterioration;
  final bool clinicalSafetyFallsRisk;
  final bool clinicalSafetyNutritionHydration;

  // Overall scores
  final int? totalCompletenessScore;
  final int maxCompletenessPossible;
  final int? totalAccuracyScore;
  final int maxAccuracyPossible;
  final int? totalComplianceScore;
  final int maxCompliancePossible;
  final int? totalQualityScore;
  final int maxQualityPossible;
  final int? overallScore;
  final double? overallPercentage;
  final String? riskLevel;

  // Clinical safety
  final bool clinicalSafetyAlert;
  final String? clinicalSafetyNotes;

  // Action plan
  final bool requiresAction;
  final String? actionRequired;
  final String? actionAssignedTo;
  final DateTime? actionDeadline;
  final bool actionCompleted;
  final DateTime? actionCompletedDate;
  final String? actionNotes;

  // Sign-off
  final String? auditorSignature;
  final bool managerReviewed;
  final String? managerReviewedBy;
  final DateTime? managerReviewedAt;
  final String? managerNotes;

  // Metadata
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? organisationId;

  CareLogAudit({
    this.id,
    required this.dailyNoteId,
    required this.serviceUserId,
    required this.serviceUserName,
    required this.auditDate,
    required this.auditorName,
    this.auditorId,
    this.completenessBasicInfo,
    this.completenessVisitType,
    this.completenessCareAcceptance,
    this.completenessEmotionalState,
    this.completenessPadCheck,
    this.completenessFoodFluid,
    this.completenessMedication,
    this.completenessObservations,
    this.completenessIncidents,
    this.completenessSignature,
    this.accuracyEmotionalStateMatch,
    this.accuracyFoodFluidAmounts,
    this.accuracyMedicationDetails,
    this.accuracySkinCondition,
    this.accuracyIncidentDetails,
    this.complianceCareAct2014,
    this.complianceMca2005,
    this.complianceDols,
    this.complianceConfidentiality,
    this.complianceTimeliness,
    this.qualityProfessionalLanguage,
    this.qualityObjectiveObservations,
    this.qualityLegibilityReadability,
    this.qualityActionableInformation,
    this.qualityContinuityOfCare,
    this.clinicalSafetyMedicationErrors = false,
    this.clinicalSafetySafeguarding = false,
    this.clinicalSafetyHealthDeterioration = false,
    this.clinicalSafetyFallsRisk = false,
    this.clinicalSafetyNutritionHydration = false,
    this.totalCompletenessScore,
    this.maxCompletenessPossible = 20,
    this.totalAccuracyScore,
    this.maxAccuracyPossible = 10,
    this.totalComplianceScore,
    this.maxCompliancePossible = 10,
    this.totalQualityScore,
    this.maxQualityPossible = 10,
    this.overallScore,
    this.overallPercentage,
    this.riskLevel,
    this.clinicalSafetyAlert = false,
    this.clinicalSafetyNotes,
    this.requiresAction = false,
    this.actionRequired,
    this.actionAssignedTo,
    this.actionDeadline,
    this.actionCompleted = false,
    this.actionCompletedDate,
    this.actionNotes,
    this.auditorSignature,
    this.managerReviewed = false,
    this.managerReviewedBy,
    this.managerReviewedAt,
    this.managerNotes,
    this.status = 'draft',
    required this.createdAt,
    required this.updatedAt,
    this.organisationId,
  });

  factory CareLogAudit.fromMap(Map<String, dynamic> map) {
    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value.toLocal();
      return DateTime.parse(value).toLocal();
    }

    return CareLogAudit(
      id: map['id'],
      dailyNoteId: map['daily_note_id'],
      serviceUserId: map['service_user_id'],
      serviceUserName: map['service_user_name'],
      auditDate: _parseDate(map['audit_date']),
      auditorName: map['auditor_name'],
      auditorId: map['auditor_id'],
      completenessBasicInfo: map['completeness_basic_info'],
      completenessVisitType: map['completeness_visit_type'],
      completenessCareAcceptance: map['completeness_care_acceptance'],
      completenessEmotionalState: map['completeness_emotional_state'],
      completenessPadCheck: map['completeness_pad_check'],
      completenessFoodFluid: map['completeness_food_fluid'],
      completenessMedication: map['completeness_medication'],
      completenessObservations: map['completeness_observations'],
      completenessIncidents: map['completeness_incidents'],
      completenessSignature: map['completeness_signature'],
      accuracyEmotionalStateMatch: map['accuracy_emotional_state_match'],
      accuracyFoodFluidAmounts: map['accuracy_food_fluid_amounts'],
      accuracyMedicationDetails: map['accuracy_medication_details'],
      accuracySkinCondition: map['accuracy_skin_condition'],
      accuracyIncidentDetails: map['accuracy_incident_details'],
      complianceCareAct2014: map['compliance_care_act_2014'],
      complianceMca2005: map['compliance_mca_2005'],
      complianceDols: map['compliance_dols'],
      complianceConfidentiality: map['compliance_confidentiality'],
      complianceTimeliness: map['compliance_timeliness'],
      qualityProfessionalLanguage: map['quality_professional_language'],
      qualityObjectiveObservations: map['quality_objective_observations'],
      qualityLegibilityReadability: map['quality_legibility_readability'],
      qualityActionableInformation: map['quality_actionable_information'],
      qualityContinuityOfCare: map['quality_continuity_of_care'],
      clinicalSafetyMedicationErrors:
          map['clinical_safety_medication_errors'] as bool? ?? false,
      clinicalSafetySafeguarding:
          map['clinical_safety_safeguarding'] as bool? ?? false,
      clinicalSafetyHealthDeterioration:
          map['clinical_safety_health_deterioration'] as bool? ?? false,
      clinicalSafetyFallsRisk:
          map['clinical_safety_falls_risk'] as bool? ?? false,
      clinicalSafetyNutritionHydration:
          map['clinical_safety_nutrition_hydration'] as bool? ?? false,
      totalCompletenessScore: map['total_completeness_score'],
      maxCompletenessPossible: map['max_completeness_possible'] as int? ?? 20,
      totalAccuracyScore: map['total_accuracy_score'],
      maxAccuracyPossible: map['max_accuracy_possible'] as int? ?? 10,
      totalComplianceScore: map['total_compliance_score'],
      maxCompliancePossible: map['max_compliance_possible'] as int? ?? 10,
      totalQualityScore: map['total_quality_score'],
      maxQualityPossible: map['max_quality_possible'] as int? ?? 10,
      overallScore: map['overall_score'],
      overallPercentage: (map['overall_percentage'] as num?)?.toDouble(),
      riskLevel: map['risk_level'],
      clinicalSafetyAlert:
          map['clinical_safety_alert'] as bool? ?? false,
      clinicalSafetyNotes: map['clinical_safety_notes'],
      requiresAction: map['requires_action'] as bool? ?? false,
      actionRequired: map['action_required'],
      actionAssignedTo: map['action_assigned_to'],
      actionDeadline: map['action_deadline'] != null
          ? _parseDate(map['action_deadline'])
          : null,
      actionCompleted: map['action_completed'] as bool? ?? false,
      actionCompletedDate: map['action_completed_date'] != null
          ? _parseDate(map['action_completed_date'])
          : null,
      actionNotes: map['action_notes'],
      auditorSignature: map['auditor_signature'],
      managerReviewed: map['manager_reviewed'] as bool? ?? false,
      managerReviewedBy: map['manager_reviewed_by'],
      managerReviewedAt: map['manager_reviewed_at'] != null
          ? _parseDate(map['manager_reviewed_at'])
          : null,
      managerNotes: map['manager_notes'],
      status: map['status'] as String? ?? 'draft',
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
      organisationId: map['organisation_id'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      if (id != null) 'id': id,
      'daily_note_id': dailyNoteId,
      'service_user_id': serviceUserId,
      'service_user_name': serviceUserName,
      'audit_date': auditDate.toIso8601String().split('T').first,
      'auditor_name': auditorName,
      'auditor_id': auditorId,
      'completeness_basic_info': completenessBasicInfo,
      'completeness_visit_type': completenessVisitType,
      'completeness_care_acceptance': completenessCareAcceptance,
      'completeness_emotional_state': completenessEmotionalState,
      'completeness_pad_check': completenessPadCheck,
      'completeness_food_fluid': completenessFoodFluid,
      'completeness_medication': completenessMedication,
      'completeness_observations': completenessObservations,
      'completeness_incidents': completenessIncidents,
      'completeness_signature': completenessSignature,
      'accuracy_emotional_state_match': accuracyEmotionalStateMatch,
      'accuracy_food_fluid_amounts': accuracyFoodFluidAmounts,
      'accuracy_medication_details': accuracyMedicationDetails,
      'accuracy_skin_condition': accuracySkinCondition,
      'accuracy_incident_details': accuracyIncidentDetails,
      'compliance_care_act_2014': complianceCareAct2014,
      'compliance_mca_2005': complianceMca2005,
      'compliance_dols': complianceDols,
      'compliance_confidentiality': complianceConfidentiality,
      'compliance_timeliness': complianceTimeliness,
      'quality_professional_language': qualityProfessionalLanguage,
      'quality_objective_observations': qualityObjectiveObservations,
      'quality_legibility_readability': qualityLegibilityReadability,
      'quality_actionable_information': qualityActionableInformation,
      'quality_continuity_of_care': qualityContinuityOfCare,
      'clinical_safety_medication_errors': clinicalSafetyMedicationErrors,
      'clinical_safety_safeguarding': clinicalSafetySafeguarding,
      'clinical_safety_health_deterioration': clinicalSafetyHealthDeterioration,
      'clinical_safety_falls_risk': clinicalSafetyFallsRisk,
      'clinical_safety_nutrition_hydration': clinicalSafetyNutritionHydration,
      'total_completeness_score': totalCompletenessScore,
      'max_completeness_possible': maxCompletenessPossible,
      'total_accuracy_score': totalAccuracyScore,
      'max_accuracy_possible': maxAccuracyPossible,
      'total_compliance_score': totalComplianceScore,
      'max_compliance_possible': maxCompliancePossible,
      'total_quality_score': totalQualityScore,
      'max_quality_possible': maxQualityPossible,
      'overall_score': overallScore,
      'overall_percentage': overallPercentage,
      'risk_level': riskLevel,
      'clinical_safety_alert': clinicalSafetyAlert,
      'clinical_safety_notes': clinicalSafetyNotes,
      'requires_action': requiresAction,
      'action_required': actionRequired,
      'action_assigned_to': actionAssignedTo,
      'action_deadline':
          actionDeadline?.toIso8601String().split('T').first,
      'action_completed': actionCompleted,
      'action_completed_date':
          actionCompletedDate?.toIso8601String().split('T').first,
      'action_notes': actionNotes,
      'auditor_signature': auditorSignature,
      'manager_reviewed': managerReviewed,
      'manager_reviewed_by': managerReviewedBy,
      'manager_reviewed_at': managerReviewedAt?.toIso8601String(),
      'manager_notes': managerNotes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'organisation_id': organisationId,
    };
    map.removeWhere((k, v) => v == null);
    return map;
  }

  CareLogAudit copyWith({
    String? id,
    String? dailyNoteId,
    String? serviceUserId,
    String? serviceUserName,
    DateTime? auditDate,
    String? auditorName,
    String? auditorId,
    int? completenessBasicInfo,
    int? completenessVisitType,
    int? completenessCareAcceptance,
    int? completenessEmotionalState,
    int? completenessPadCheck,
    int? completenessFoodFluid,
    int? completenessMedication,
    int? completenessObservations,
    int? completenessIncidents,
    int? completenessSignature,
    bool? accuracyEmotionalStateMatch,
    bool? accuracyFoodFluidAmounts,
    bool? accuracyMedicationDetails,
    bool? accuracySkinCondition,
    bool? accuracyIncidentDetails,
    bool? complianceCareAct2014,
    bool? complianceMca2005,
    bool? complianceDols,
    bool? complianceConfidentiality,
    bool? complianceTimeliness,
    bool? qualityProfessionalLanguage,
    bool? qualityObjectiveObservations,
    bool? qualityLegibilityReadability,
    bool? qualityActionableInformation,
    bool? qualityContinuityOfCare,
    bool? clinicalSafetyMedicationErrors,
    bool? clinicalSafetySafeguarding,
    bool? clinicalSafetyHealthDeterioration,
    bool? clinicalSafetyFallsRisk,
    bool? clinicalSafetyNutritionHydration,
    int? totalCompletenessScore,
    int? maxCompletenessPossible,
    int? totalAccuracyScore,
    int? maxAccuracyPossible,
    int? totalComplianceScore,
    int? maxCompliancePossible,
    int? totalQualityScore,
    int? maxQualityPossible,
    int? overallScore,
    double? overallPercentage,
    String? riskLevel,
    bool? clinicalSafetyAlert,
    String? clinicalSafetyNotes,
    bool? requiresAction,
    String? actionRequired,
    String? actionAssignedTo,
    DateTime? actionDeadline,
    bool? actionCompleted,
    DateTime? actionCompletedDate,
    String? actionNotes,
    String? auditorSignature,
    bool? managerReviewed,
    String? managerReviewedBy,
    DateTime? managerReviewedAt,
    String? managerNotes,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? organisationId,
  }) {
    return CareLogAudit(
      id: id ?? this.id,
      dailyNoteId: dailyNoteId ?? this.dailyNoteId,
      serviceUserId: serviceUserId ?? this.serviceUserId,
      serviceUserName: serviceUserName ?? this.serviceUserName,
      auditDate: auditDate ?? this.auditDate,
      auditorName: auditorName ?? this.auditorName,
      auditorId: auditorId ?? this.auditorId,
      completenessBasicInfo:
          completenessBasicInfo ?? this.completenessBasicInfo,
      completenessVisitType: completenessVisitType ?? this.completenessVisitType,
      completenessCareAcceptance:
          completenessCareAcceptance ?? this.completenessCareAcceptance,
      completenessEmotionalState:
          completenessEmotionalState ?? this.completenessEmotionalState,
      completenessPadCheck: completenessPadCheck ?? this.completenessPadCheck,
      completenessFoodFluid:
          completenessFoodFluid ?? this.completenessFoodFluid,
      completenessMedication:
          completenessMedication ?? this.completenessMedication,
      completenessObservations:
          completenessObservations ?? this.completenessObservations,
      completenessIncidents:
          completenessIncidents ?? this.completenessIncidents,
      completenessSignature:
          completenessSignature ?? this.completenessSignature,
      accuracyEmotionalStateMatch:
          accuracyEmotionalStateMatch ?? this.accuracyEmotionalStateMatch,
      accuracyFoodFluidAmounts:
          accuracyFoodFluidAmounts ?? this.accuracyFoodFluidAmounts,
      accuracyMedicationDetails:
          accuracyMedicationDetails ?? this.accuracyMedicationDetails,
      accuracySkinCondition:
          accuracySkinCondition ?? this.accuracySkinCondition,
      accuracyIncidentDetails:
          accuracyIncidentDetails ?? this.accuracyIncidentDetails,
      complianceCareAct2014:
          complianceCareAct2014 ?? this.complianceCareAct2014,
      complianceMca2005: complianceMca2005 ?? this.complianceMca2005,
      complianceDols: complianceDols ?? this.complianceDols,
      complianceConfidentiality:
          complianceConfidentiality ?? this.complianceConfidentiality,
      complianceTimeliness:
          complianceTimeliness ?? this.complianceTimeliness,
      qualityProfessionalLanguage:
          qualityProfessionalLanguage ?? this.qualityProfessionalLanguage,
      qualityObjectiveObservations:
          qualityObjectiveObservations ?? this.qualityObjectiveObservations,
      qualityLegibilityReadability:
          qualityLegibilityReadability ?? this.qualityLegibilityReadability,
      qualityActionableInformation:
          qualityActionableInformation ?? this.qualityActionableInformation,
      qualityContinuityOfCare:
          qualityContinuityOfCare ?? this.qualityContinuityOfCare,
      clinicalSafetyMedicationErrors:
          clinicalSafetyMedicationErrors ?? this.clinicalSafetyMedicationErrors,
      clinicalSafetySafeguarding:
          clinicalSafetySafeguarding ?? this.clinicalSafetySafeguarding,
      clinicalSafetyHealthDeterioration: clinicalSafetyHealthDeterioration ??
          this.clinicalSafetyHealthDeterioration,
      clinicalSafetyFallsRisk:
          clinicalSafetyFallsRisk ?? this.clinicalSafetyFallsRisk,
      clinicalSafetyNutritionHydration:
          clinicalSafetyNutritionHydration ??
              this.clinicalSafetyNutritionHydration,
      totalCompletenessScore:
          totalCompletenessScore ?? this.totalCompletenessScore,
      maxCompletenessPossible:
          maxCompletenessPossible ?? this.maxCompletenessPossible,
      totalAccuracyScore: totalAccuracyScore ?? this.totalAccuracyScore,
      maxAccuracyPossible: maxAccuracyPossible ?? this.maxAccuracyPossible,
      totalComplianceScore:
          totalComplianceScore ?? this.totalComplianceScore,
      maxCompliancePossible:
          maxCompliancePossible ?? this.maxCompliancePossible,
      totalQualityScore: totalQualityScore ?? this.totalQualityScore,
      maxQualityPossible: maxQualityPossible ?? this.maxQualityPossible,
      overallScore: overallScore ?? this.overallScore,
      overallPercentage: overallPercentage ?? this.overallPercentage,
      riskLevel: riskLevel ?? this.riskLevel,
      clinicalSafetyAlert:
          clinicalSafetyAlert ?? this.clinicalSafetyAlert,
      clinicalSafetyNotes:
          clinicalSafetyNotes ?? this.clinicalSafetyNotes,
      requiresAction: requiresAction ?? this.requiresAction,
      actionRequired: actionRequired ?? this.actionRequired,
      actionAssignedTo: actionAssignedTo ?? this.actionAssignedTo,
      actionDeadline: actionDeadline ?? this.actionDeadline,
      actionCompleted: actionCompleted ?? this.actionCompleted,
      actionCompletedDate:
          actionCompletedDate ?? this.actionCompletedDate,
      actionNotes: actionNotes ?? this.actionNotes,
      auditorSignature: auditorSignature ?? this.auditorSignature,
      managerReviewed: managerReviewed ?? this.managerReviewed,
      managerReviewedBy: managerReviewedBy ?? this.managerReviewedBy,
      managerReviewedAt: managerReviewedAt ?? this.managerReviewedAt,
      managerNotes: managerNotes ?? this.managerNotes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      organisationId: organisationId ?? this.organisationId,
    );
  }
}

/// Helper to calculate risk level from percentage
class AuditRiskHelper {
  static String calculateRiskLevel(double percentage, bool hasClinicalSafetyFlag) {
    if (hasClinicalSafetyFlag) return 'critical';
    if (percentage >= 90) return 'low';
    if (percentage >= 75) return 'medium';
    if (percentage >= 50) return 'high';
    return 'critical';
  }

  static Color getRiskColor(String? riskLevel) {
    switch (riskLevel) {
      case 'low':
        return const Color(0xFF4CAF50);
      case 'medium':
        return const Color(0xFFFF9800);
      case 'high':
        return const Color(0xFFF44336);
      case 'critical':
        return const Color(0xFFB71C1C);
      default:
        return Colors.grey;
    }
  }

  static String getRiskLabel(String? riskLevel) {
    switch (riskLevel) {
      case 'low':
        return 'Low Risk';
      case 'medium':
        return 'Medium Risk';
      case 'high':
        return 'High Risk';
      case 'critical':
        return 'CRITICAL';
      default:
        return 'Not Assessed';
    }
  }

  static IconData getRiskIcon(String? riskLevel) {
    switch (riskLevel) {
      case 'low':
        return Icons.check_circle;
      case 'medium':
        return Icons.warning;
      case 'high':
        return Icons.error;
      case 'critical':
        return Icons.gpp_bad;
      default:
        return Icons.help;
    }
  }
}

