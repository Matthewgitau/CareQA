import 'package:flutter/material.dart';

class CarePlanAudit {
  final String? id;
  final String? carePlanId;
  final String serviceUserId;
  final String serviceUserName;
  final DateTime auditDate;
  final String auditorName;
  final String? auditorId;

  // Section 1: Person-Centred Care (0-2 each, max 12)
  final int? pcWhatMattersToMe;
  final int? pcPersonalHistory;
  final int? pcCommunicationNeeds;
  final int? pcCulturalSpiritual;
  final int? pcSocialConnections;
  final int? pcGoalsAspirations;

  // Section 2: Risk Assessment Integration (0-2 each, max 18)
  final int? riskFalls;
  final int? riskMedication;
  final int? riskNutrition;
  final int? riskPressureSores;
  final int? riskContinence;
  final int? riskMentalCapacity;
  final int? riskChallengingBehaviour;
  final int? riskSelfHarm;
  final int? riskEpilepsy;
  final int? riskDiabetes;

  // Section 3: Care Delivery Instructions (0-2 each, max 14)
  final int? deliveryDailyLiving;
  final int? deliveryPersonalCare;
  final int? deliveryMobility;
  final int? deliveryMedicationSupport;
  final int? deliveryMealtimes;
  final int? deliverySocialActivities;
  final int? deliveryNightTime;

  // Section 4: Legal & Ethical (0-2 each, max 12)
  final int? legalMca2005;
  final int? legalConsent;
  final int? legalDols;
  final int? legalAdvanceDecisions;
  final int? legalEpr;
  final int? legalDataProtection;

  // Section 5: Review & Monitoring (0-2 each, max 12)
  final int? reviewFrequency;
  final int? reviewLastDate;
  final int? reviewNextDate;
  final int? reviewEffectiveness;
  final int? reviewChangesDocumented;
  final int? reviewIncidentIntegration;

  // Section 6: Multi-Disciplinary (0-2 each, max 20)
  final int? mdGpDetails;
  final int? mdDistrictNurse;
  final int? mdSpecialistNurse;
  final int? mdPharmacist;
  final int? mdOccupationalTherapist;
  final int? mdPhysiotherapist;
  final int? mdSpeechTherapy;
  final int? mdDietitian;
  final int? mdMentalHealth;
  final int? mdFamilyCarers;

  // Section 7: End of Life (0-2 each, max 10)
  final bool eolApplicable;
  final int? eolPreferences;
  final int? eolCarePlan;
  final int? eolPreferredPlace;
  final int? eolAdvancedCarePlan;
  final int? eolDnacpr;

  // Section 8: Format & Accessibility (0-2 each, max 10)
  final int? formatAccessible;
  final int? formatLanguage;
  final int? formatLegible;
  final int? formatSectioned;
  final int? formatVersionControl;

  // Section 9: Critical Compliance Flags
  final bool criticalNoCarePlan;
  final bool criticalNotReviewedAnnually;
  final bool criticalMissingMca;
  final bool criticalMissingConsent;
  final bool criticalRiskNotManaged;
  final bool criticalMedicationError;
  final bool criticalSafeguardingMissing;
  final bool criticalContradictoryInstructions;
  final bool criticalOutdatedInformation;

  // Calculated scores
  final int? pcTotalScore;
  final int riskMaxPossible;
  final int? deliveryTotalScore;
  final int? legalTotalScore;
  final int? reviewTotalScore;
  final int? mdTotalScore;
  final int? eolTotalScore;
  final int? formatTotalScore;
  final int? totalScore;
  final int? maxPossibleScore;
  final double? overallPercentage;
  final String? riskLevel;

  // Critical flags
  final bool criticalFlagsPresent;
  final int criticalFlagsCount;
  final String? criticalFlagsDetails;

  // Action plan
  final bool requiresAction;
  final String? actionRequired;
  final String? actionAssignedTo;
  final DateTime? actionDeadline;
  final bool actionCompleted;
  final DateTime? actionCompletedDate;
  final String? actionNotes;
  final String? recommendations;

  // Sign-off
  final String? auditorSignature;
  final bool clinicalLeadReviewed;
  final String? clinicalLeadReviewedBy;
  final DateTime? clinicalLeadReviewedAt;
  final String? clinicalLeadNotes;
  final bool registeredManagerReviewed;
  final String? registeredManagerReviewedBy;
  final DateTime? registeredManagerReviewedAt;
  final String? registeredManagerNotes;

  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? organisationId;

  CarePlanAudit({
    this.id,
    this.carePlanId,
    required this.serviceUserId,
    required this.serviceUserName,
    required this.auditDate,
    required this.auditorName,
    this.auditorId,
    this.pcWhatMattersToMe,
    this.pcPersonalHistory,
    this.pcCommunicationNeeds,
    this.pcCulturalSpiritual,
    this.pcSocialConnections,
    this.pcGoalsAspirations,
    this.riskFalls,
    this.riskMedication,
    this.riskNutrition,
    this.riskPressureSores,
    this.riskContinence,
    this.riskMentalCapacity,
    this.riskChallengingBehaviour,
    this.riskSelfHarm,
    this.riskEpilepsy,
    this.riskDiabetes,
    this.deliveryDailyLiving,
    this.deliveryPersonalCare,
    this.deliveryMobility,
    this.deliveryMedicationSupport,
    this.deliveryMealtimes,
    this.deliverySocialActivities,
    this.deliveryNightTime,
    this.legalMca2005,
    this.legalConsent,
    this.legalDols,
    this.legalAdvanceDecisions,
    this.legalEpr,
    this.legalDataProtection,
    this.reviewFrequency,
    this.reviewLastDate,
    this.reviewNextDate,
    this.reviewEffectiveness,
    this.reviewChangesDocumented,
    this.reviewIncidentIntegration,
    this.mdGpDetails,
    this.mdDistrictNurse,
    this.mdSpecialistNurse,
    this.mdPharmacist,
    this.mdOccupationalTherapist,
    this.mdPhysiotherapist,
    this.mdSpeechTherapy,
    this.mdDietitian,
    this.mdMentalHealth,
    this.mdFamilyCarers,
    this.eolApplicable = false,
    this.eolPreferences,
    this.eolCarePlan,
    this.eolPreferredPlace,
    this.eolAdvancedCarePlan,
    this.eolDnacpr,
    this.formatAccessible,
    this.formatLanguage,
    this.formatLegible,
    this.formatSectioned,
    this.formatVersionControl,
    this.criticalNoCarePlan = false,
    this.criticalNotReviewedAnnually = false,
    this.criticalMissingMca = false,
    this.criticalMissingConsent = false,
    this.criticalRiskNotManaged = false,
    this.criticalMedicationError = false,
    this.criticalSafeguardingMissing = false,
    this.criticalContradictoryInstructions = false,
    this.criticalOutdatedInformation = false,
    this.pcTotalScore,
    this.riskMaxPossible = 18,
    this.deliveryTotalScore,
    this.legalTotalScore,
    this.reviewTotalScore,
    this.mdTotalScore,
    this.eolTotalScore,
    this.formatTotalScore,
    this.totalScore,
    this.maxPossibleScore,
    this.overallPercentage,
    this.riskLevel,
    this.criticalFlagsPresent = false,
    this.criticalFlagsCount = 0,
    this.criticalFlagsDetails,
    this.requiresAction = false,
    this.actionRequired,
    this.actionAssignedTo,
    this.actionDeadline,
    this.actionCompleted = false,
    this.actionCompletedDate,
    this.actionNotes,
    this.recommendations,
    this.auditorSignature,
    this.clinicalLeadReviewed = false,
    this.clinicalLeadReviewedBy,
    this.clinicalLeadReviewedAt,
    this.clinicalLeadNotes,
    this.registeredManagerReviewed = false,
    this.registeredManagerReviewedBy,
    this.registeredManagerReviewedAt,
    this.registeredManagerNotes,
    this.status = 'draft',
    required this.createdAt,
    required this.updatedAt,
    this.organisationId,
  });

  factory CarePlanAudit.fromMap(Map<String, dynamic> map) {
    DateTime _p(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v.toLocal();
      return DateTime.parse(v).toLocal();
    }

    return CarePlanAudit(
      id: map['id'],
      carePlanId: map['care_plan_id'],
      serviceUserId: map['service_user_id'],
      serviceUserName: map['service_user_name'],
      auditDate: _p(map['audit_date']),
      auditorName: map['auditor_name'],
      auditorId: map['auditor_id'],
      pcWhatMattersToMe: map['pc_what_matters_to_me'],
      pcPersonalHistory: map['pc_personal_history'],
      pcCommunicationNeeds: map['pc_communication_needs'],
      pcCulturalSpiritual: map['pc_cultural_spiritual'],
      pcSocialConnections: map['pc_social_connections'],
      pcGoalsAspirations: map['pc_goals_aspirations'],
      riskFalls: map['risk_falls'],
      riskMedication: map['risk_medication'],
      riskNutrition: map['risk_nutrition'],
      riskPressureSores: map['risk_pressure_sores'],
      riskContinence: map['risk_continence'],
      riskMentalCapacity: map['risk_mental_capacity'],
      riskChallengingBehaviour: map['risk_challenging_behaviour'],
      riskSelfHarm: map['risk_self_harm'],
      riskEpilepsy: map['risk_epilepsy'],
      riskDiabetes: map['risk_diabetes'],
      deliveryDailyLiving: map['delivery_daily_living'],
      deliveryPersonalCare: map['delivery_personal_care'],
      deliveryMobility: map['delivery_mobility'],
      deliveryMedicationSupport: map['delivery_medication_support'],
      deliveryMealtimes: map['delivery_mealtimes'],
      deliverySocialActivities: map['delivery_social_activities'],
      deliveryNightTime: map['delivery_night_time'],
      legalMca2005: map['legal_mca_2005'],
      legalConsent: map['legal_consent'],
      legalDols: map['legal_dols'],
      legalAdvanceDecisions: map['legal_advance_decisions'],
      legalEpr: map['legal_epr'],
      legalDataProtection: map['legal_data_protection'],
      reviewFrequency: map['review_frequency'],
      reviewLastDate: map['review_last_date'],
      reviewNextDate: map['review_next_date'],
      reviewEffectiveness: map['review_effectiveness'],
      reviewChangesDocumented: map['review_changes_documented'],
      reviewIncidentIntegration: map['review_incident_integration'],
      mdGpDetails: map['md_gp_details'],
      mdDistrictNurse: map['md_district_nurse'],
      mdSpecialistNurse: map['md_specialist_nurse'],
      mdPharmacist: map['md_pharmacist'],
      mdOccupationalTherapist: map['md_occupational_therapist'],
      mdPhysiotherapist: map['md_physiotherapist'],
      mdSpeechTherapy: map['md_speech_therapy'],
      mdDietitian: map['md_dietitian'],
      mdMentalHealth: map['md_mental_health'],
      mdFamilyCarers: map['md_family_carers'],
      eolApplicable: map['eol_applicable'] as bool? ?? false,
      eolPreferences: map['eol_preferences'],
      eolCarePlan: map['eol_care_plan'],
      eolPreferredPlace: map['eol_preferred_place'],
      eolAdvancedCarePlan: map['eol_advanced_care_plan'],
      eolDnacpr: map['eol_dnacpr'],
      formatAccessible: map['format_accessible'],
      formatLanguage: map['format_language'],
      formatLegible: map['format_legible'],
      formatSectioned: map['format_sectioned'],
      formatVersionControl: map['format_version_control'],
      criticalNoCarePlan: map['critical_no_care_plan'] as bool? ?? false,
      criticalNotReviewedAnnually: map['critical_not_reviewed_annually'] as bool? ?? false,
      criticalMissingMca: map['critical_missing_mca'] as bool? ?? false,
      criticalMissingConsent: map['critical_missing_consent'] as bool? ?? false,
      criticalRiskNotManaged: map['critical_risk_not_managed'] as bool? ?? false,
      criticalMedicationError: map['critical_medication_error'] as bool? ?? false,
      criticalSafeguardingMissing: map['critical_safeguarding_missing'] as bool? ?? false,
      criticalContradictoryInstructions: map['critical_contradictory_instructions'] as bool? ?? false,
      criticalOutdatedInformation: map['critical_outdated_information'] as bool? ?? false,
      pcTotalScore: map['pc_total_score'],
      riskMaxPossible: map['risk_max_possible'] as int? ?? 18,
      deliveryTotalScore: map['delivery_total_score'],
      legalTotalScore: map['legal_total_score'],
      reviewTotalScore: map['review_total_score'],
      mdTotalScore: map['md_total_score'],
      eolTotalScore: map['eol_total_score'],
      formatTotalScore: map['format_total_score'],
      totalScore: map['total_score'],
      maxPossibleScore: map['max_possible_score'],
      overallPercentage: (map['overall_percentage'] as num?)?.toDouble(),
      riskLevel: map['risk_level'],
      criticalFlagsPresent: map['critical_flags_present'] as bool? ?? false,
      criticalFlagsCount: map['critical_flags_count'] as int? ?? 0,
      criticalFlagsDetails: map['critical_flags_details'],
      requiresAction: map['requires_action'] as bool? ?? false,
      actionRequired: map['action_required'],
      actionAssignedTo: map['action_assigned_to'],
      actionDeadline: map['action_deadline'] != null ? _p(map['action_deadline']) : null,
      actionCompleted: map['action_completed'] as bool? ?? false,
      actionCompletedDate: map['action_completed_date'] != null ? _p(map['action_completed_date']) : null,
      actionNotes: map['action_notes'],
      recommendations: map['recommendations'],
      auditorSignature: map['auditor_signature'],
      clinicalLeadReviewed: map['clinical_lead_reviewed'] as bool? ?? false,
      clinicalLeadReviewedBy: map['clinical_lead_reviewed_by'],
      clinicalLeadReviewedAt: map['clinical_lead_reviewed_at'] != null ? _p(map['clinical_lead_reviewed_at']) : null,
      clinicalLeadNotes: map['clinical_lead_notes'],
      registeredManagerReviewed: map['registered_manager_reviewed'] as bool? ?? false,
      registeredManagerReviewedBy: map['registered_manager_reviewed_by'],
      registeredManagerReviewedAt: map['registered_manager_reviewed_at'] != null ? _p(map['registered_manager_reviewed_at']) : null,
      registeredManagerNotes: map['registered_manager_notes'],
      status: map['status'] as String? ?? 'draft',
      createdAt: _p(map['created_at']),
      updatedAt: _p(map['updated_at']),
      organisationId: map['organisation_id'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      if (id != null) 'id': id,
      'service_user_id': serviceUserId,
      'service_user_name': serviceUserName,
      'audit_date': auditDate.toIso8601String().split('T').first,
      'auditor_name': auditorName,
      'auditor_id': auditorId,
      'pc_what_matters_to_me': pcWhatMattersToMe,
      'pc_personal_history': pcPersonalHistory,
      'pc_communication_needs': pcCommunicationNeeds,
      'pc_cultural_spiritual': pcCulturalSpiritual,
      'pc_social_connections': pcSocialConnections,
      'pc_goals_aspirations': pcGoalsAspirations,
      'risk_falls': riskFalls,
      'risk_medication': riskMedication,
      'risk_nutrition': riskNutrition,
      'risk_pressure_sores': riskPressureSores,
      'risk_continence': riskContinence,
      'risk_mental_capacity': riskMentalCapacity,
      'risk_challenging_behaviour': riskChallengingBehaviour,
      'risk_self_harm': riskSelfHarm,
      'risk_epilepsy': riskEpilepsy,
      'risk_diabetes': riskDiabetes,
      'delivery_daily_living': deliveryDailyLiving,
      'delivery_personal_care': deliveryPersonalCare,
      'delivery_mobility': deliveryMobility,
      'delivery_medication_support': deliveryMedicationSupport,
      'delivery_mealtimes': deliveryMealtimes,
      'delivery_social_activities': deliverySocialActivities,
      'delivery_night_time': deliveryNightTime,
      'legal_mca_2005': legalMca2005,
      'legal_consent': legalConsent,
      'legal_dols': legalDols,
      'legal_advance_decisions': legalAdvanceDecisions,
      'legal_epr': legalEpr,
      'legal_data_protection': legalDataProtection,
      'review_frequency': reviewFrequency,
      'review_last_date': reviewLastDate,
      'review_next_date': reviewNextDate,
      'review_effectiveness': reviewEffectiveness,
      'review_changes_documented': reviewChangesDocumented,
      'review_incident_integration': reviewIncidentIntegration,
      'md_gp_details': mdGpDetails,
      'md_district_nurse': mdDistrictNurse,
      'md_specialist_nurse': mdSpecialistNurse,
      'md_pharmacist': mdPharmacist,
      'md_occupational_therapist': mdOccupationalTherapist,
      'md_physiotherapist': mdPhysiotherapist,
      'md_speech_therapy': mdSpeechTherapy,
      'md_dietitian': mdDietitian,
      'md_mental_health': mdMentalHealth,
      'md_family_carers': mdFamilyCarers,
      'eol_applicable': eolApplicable,
      'eol_preferences': eolPreferences,
      'eol_care_plan': eolCarePlan,
      'eol_preferred_place': eolPreferredPlace,
      'eol_advanced_care_plan': eolAdvancedCarePlan,
      'eol_dnacpr': eolDnacpr,
      'format_accessible': formatAccessible,
      'format_language': formatLanguage,
      'format_legible': formatLegible,
      'format_sectioned': formatSectioned,
      'format_version_control': formatVersionControl,
      'critical_no_care_plan': criticalNoCarePlan,
      'critical_not_reviewed_annually': criticalNotReviewedAnnually,
      'critical_missing_mca': criticalMissingMca,
      'critical_missing_consent': criticalMissingConsent,
      'critical_risk_not_managed': criticalRiskNotManaged,
      'critical_medication_error': criticalMedicationError,
      'critical_safeguarding_missing': criticalSafeguardingMissing,
      'critical_contradictory_instructions': criticalContradictoryInstructions,
      'critical_outdated_information': criticalOutdatedInformation,
      'total_score': totalScore,
      'max_possible_score': maxPossibleScore,
      'overall_percentage': overallPercentage,
      'risk_level': riskLevel,
      'critical_flags_present': criticalFlagsPresent,
      'critical_flags_count': criticalFlagsCount,
      'critical_flags_details': criticalFlagsDetails,
      'requires_action': requiresAction,
      'action_required': actionRequired,
      'action_assigned_to': actionAssignedTo,
      'action_deadline': actionDeadline?.toIso8601String().split('T').first,
      'action_completed': actionCompleted,
      'action_completed_date': actionCompletedDate?.toIso8601String().split('T').first,
      'action_notes': actionNotes,
      'recommendations': recommendations,
      'auditor_signature': auditorSignature,
      'clinical_lead_reviewed': clinicalLeadReviewed,
      'clinical_lead_reviewed_by': clinicalLeadReviewedBy,
      'clinical_lead_reviewed_at': clinicalLeadReviewedAt?.toIso8601String(),
      'clinical_lead_notes': clinicalLeadNotes,
      'registered_manager_reviewed': registeredManagerReviewed,
      'registered_manager_reviewed_by': registeredManagerReviewedBy,
      'registered_manager_reviewed_at': registeredManagerReviewedAt?.toIso8601String(),
      'registered_manager_notes': registeredManagerNotes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'organisation_id': organisationId,
    };
    map.removeWhere((k, v) => v == null);
    return map;
  }
}

class CarePlanAuditRiskHelper {
  static String calculateRiskLevel(double percentage, bool hasCriticalFlags) {
    if (hasCriticalFlags || percentage < 50) return 'critical';
    if (percentage >= 90) return 'low';
    if (percentage >= 75) return 'medium';
    if (percentage >= 50) return 'high';
    return 'critical';
  }

  static Color getRiskColor(String? riskLevel) {
    switch (riskLevel) {
      case 'low': return const Color(0xFF4CAF50);
      case 'medium': return const Color(0xFFFF9800);
      case 'high': return const Color(0xFFF44336);
      case 'critical': return const Color(0xFFB71C1C);
      default: return Colors.grey;
    }
  }

  static String getRiskLabel(String? riskLevel) {
    switch (riskLevel) {
      case 'low': return 'Exceeds expectations';
      case 'medium': return 'Meets requirements';
      case 'high': return 'Action required';
      case 'critical': return 'Immediate action required';
      default: return 'Not assessed';
    }
  }

  static String getRiskBadge(String? riskLevel) {
    switch (riskLevel) {
      case 'low': return 'Low Risk';
      case 'medium': return 'Medium Risk';
      case 'high': return 'High Risk';
      case 'critical': return 'CRITICAL';
      default: return 'Not Assessed';
    }
  }

  static IconData getRiskIcon(String? riskLevel) {
    switch (riskLevel) {
      case 'low': return Icons.check_circle;
      case 'medium': return Icons.warning;
      case 'high': return Icons.error;
      case 'critical': return Icons.gpp_bad;
      default: return Icons.help;
    }
  }
}