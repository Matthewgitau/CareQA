import 'package:flutter/material.dart';

class SpotCheck {
  final String? id;
  final String? spotCheckNumber;
  final String serviceUserId;
  final String serviceUserName;
  final DateTime? serviceUserDob;
  final String carerId;
  final String carerName;
  final String? carerRole;
  final String? carerEmploymentType;
  final DateTime spotCheckDate;
  final String spotCheckTime;
  final int? spotCheckDurationMinutes;
  final String spotCheckType;
  final String? spotCheckReason;
  final String conductedById;
  final String conductedByName;
  final String? conductedByRole;
  final bool witnessPresent;
  final String? witnessName;
  final String? witnessRole;

  // Section 1: Prep & Arrival
  final int? prepHandoverReviewed; final int? prepMedicationChecked; final int? prepEquipmentReady;
  final int? arrivalPunctuality; final int? arrivalPresentation; final int? arrivalCommunication;

  // Section 2: Infection Control
  final int? icHandHygiene; final int? icPpeWorn; final int? icPpeChanged;
  final int? icEquipmentCleanliness; final int? icEnvironmentHygiene; final int? icWasteDisposal;

  // Section 3: Interaction
  final int? interactionGreeting; final int? interactionConsent; final int? interactionDignity;
  final int? interactionPrivacy; final int? interactionCommunication; final int? interactionHearingListening;
  final int? interactionChoicePromoted; final int? interactionCapacityConsidered; final int? interactionEmotionalSupport;

  // Section 4: Care Delivery
  final int? careFollowsCarePlan; final int? carePersonalCareQuality; final int? careMobilityAssistance;
  final int? careMedicationAdministration; final int? careNutritionHydration; final int? careDocumentation; final int? careHandoverCommunication;

  // Section 5: Safety
  final int? safetyRiskAssessment; final int? safetyEnvironmentCheck; final int? safetyMovingHandling;
  final int? safetyEmergencyKnowledge; final int? safetyMedicationSecurity; final int? safetyChallengingBehaviour;

  // Section 6: Communication
  final int? commDailyNoteQuality; final int? commIncidentReporting; final int? commFamilyCommunication;
  final int? commOtherProfessionals; final int? commEscalationAwareness;

  // Section 7: Professionalism
  final int? profCodeOfConduct; final int? profMedicationKnowledge; final int? profSafeguardingKnowledge;
  final int? profDataProtection; final int? profTeamWorking; final int? profFeedbackReceptiveness;

  // Critical Flags
  final bool flagMedicationError; final bool flagInfectionBreach; final bool flagDignityBreach;
  final bool flagSafeguardingConcern; final bool flagUnauthorizedAbsence; final bool flagUntrainedTask;
  final bool flagFalsifiedRecords; final bool flagRefusedCare; final bool flagAggressiveBehaviour;

  // Scores
  final int? totalScore; final int maxPossibleScore;
  final double? overallPercentage; final String? competencyRating;

  // Findings
  final String? strengths; final String? areasForImprovement; final String? immediateConcerns; final String? additionalObservations;

  // Action plan
  final bool requiresAction; final String? actionRequired; final String? actionAssignedTo; final DateTime? actionDeadline;
  final bool actionCompleted; final DateTime? actionCompletedDate; final String? actionNotes;

  // Follow-up
  final bool followUpRequired; final DateTime? followUpDate; final String? followUpType; final bool followUpCompleted;

  // Sign-off
  final String auditorSignature; final bool carerAcknowledged; final DateTime? carerAcknowledgedAt; final String? carerComments;
  final bool managerReviewed; final String? managerReviewedBy; final DateTime? managerReviewedAt; final String? managerNotes;

  final String status; final DateTime createdAt; final DateTime updatedAt; final String? organisationId;

  SpotCheck({
    this.id, this.spotCheckNumber,
    required this.serviceUserId, required this.serviceUserName, this.serviceUserDob,
    required this.carerId, required this.carerName, this.carerRole, this.carerEmploymentType,
    required this.spotCheckDate, required this.spotCheckTime, this.spotCheckDurationMinutes,
    required this.spotCheckType, this.spotCheckReason,
    required this.conductedById, required this.conductedByName, this.conductedByRole,
    this.witnessPresent = false, this.witnessName, this.witnessRole,
    this.prepHandoverReviewed, this.prepMedicationChecked, this.prepEquipmentReady,
    this.arrivalPunctuality, this.arrivalPresentation, this.arrivalCommunication,
    this.icHandHygiene, this.icPpeWorn, this.icPpeChanged,
    this.icEquipmentCleanliness, this.icEnvironmentHygiene, this.icWasteDisposal,
    this.interactionGreeting, this.interactionConsent, this.interactionDignity,
    this.interactionPrivacy, this.interactionCommunication, this.interactionHearingListening,
    this.interactionChoicePromoted, this.interactionCapacityConsidered, this.interactionEmotionalSupport,
    this.careFollowsCarePlan, this.carePersonalCareQuality, this.careMobilityAssistance,
    this.careMedicationAdministration, this.careNutritionHydration, this.careDocumentation, this.careHandoverCommunication,
    this.safetyRiskAssessment, this.safetyEnvironmentCheck, this.safetyMovingHandling,
    this.safetyEmergencyKnowledge, this.safetyMedicationSecurity, this.safetyChallengingBehaviour,
    this.commDailyNoteQuality, this.commIncidentReporting, this.commFamilyCommunication,
    this.commOtherProfessionals, this.commEscalationAwareness,
    this.profCodeOfConduct, this.profMedicationKnowledge, this.profSafeguardingKnowledge,
    this.profDataProtection, this.profTeamWorking, this.profFeedbackReceptiveness,
    this.flagMedicationError = false, this.flagInfectionBreach = false, this.flagDignityBreach = false,
    this.flagSafeguardingConcern = false, this.flagUnauthorizedAbsence = false, this.flagUntrainedTask = false,
    this.flagFalsifiedRecords = false, this.flagRefusedCare = false, this.flagAggressiveBehaviour = false,
    this.totalScore, this.maxPossibleScore = 240, this.overallPercentage, this.competencyRating,
    this.strengths, this.areasForImprovement, this.immediateConcerns, this.additionalObservations,
    this.requiresAction = false, this.actionRequired, this.actionAssignedTo, this.actionDeadline,
    this.actionCompleted = false, this.actionCompletedDate, this.actionNotes,
    this.followUpRequired = false, this.followUpDate, this.followUpType, this.followUpCompleted = false,
    required this.auditorSignature,
    this.carerAcknowledged = false, this.carerAcknowledgedAt, this.carerComments,
    this.managerReviewed = false, this.managerReviewedBy, this.managerReviewedAt, this.managerNotes,
    this.status = 'draft', required this.createdAt, required this.updatedAt, this.organisationId,
  });

  factory SpotCheck.fromMap(Map<String, dynamic> m) {
    DateTime _p(dynamic v) => v == null ? DateTime.now() : (v is DateTime ? v.toLocal() : DateTime.parse(v).toLocal());
    return SpotCheck(
      id: m['id'], spotCheckNumber: m['spot_check_number'],
      serviceUserId: m['service_user_id'], serviceUserName: m['service_user_name'],
      serviceUserDob: m['service_user_dob'] != null ? _p(m['service_user_dob']) : null,
      carerId: m['carer_id'], carerName: m['carer_name'], carerRole: m['carer_role'], carerEmploymentType: m['carer_employment_type'],
      spotCheckDate: _p(m['spot_check_date']),
      spotCheckTime: m['spot_check_time'] as String? ?? '00:00',
      spotCheckDurationMinutes: m['spot_check_duration_minutes'],
      spotCheckType: m['spot_check_type'], spotCheckReason: m['spot_check_reason'],
      conductedById: m['conducted_by_id'], conductedByName: m['conducted_by_name'], conductedByRole: m['conducted_by_role'],
      witnessPresent: m['witness_present'] as bool? ?? false, witnessName: m['witness_name'], witnessRole: m['witness_role'],
      prepHandoverReviewed: m['prep_handover_reviewed'], prepMedicationChecked: m['prep_medication_checked'], prepEquipmentReady: m['prep_equipment_ready'],
      arrivalPunctuality: m['arrival_punctuality'], arrivalPresentation: m['arrival_presentation'], arrivalCommunication: m['arrival_communication'],
      icHandHygiene: m['ic_hand_hygiene'], icPpeWorn: m['ic_ppe_worn'], icPpeChanged: m['ic_ppe_changed'],
      icEquipmentCleanliness: m['ic_equipment_cleanliness'], icEnvironmentHygiene: m['ic_environment_hygiene'], icWasteDisposal: m['ic_waste_disposal'],
      interactionGreeting: m['interaction_greeting'], interactionConsent: m['interaction_consent'], interactionDignity: m['interaction_dignity'],
      interactionPrivacy: m['interaction_privacy'], interactionCommunication: m['interaction_communication'], interactionHearingListening: m['interaction_hearing_listening'],
      interactionChoicePromoted: m['interaction_choice_promoted'], interactionCapacityConsidered: m['interaction_capacity_considered'], interactionEmotionalSupport: m['interaction_emotional_support'],
      careFollowsCarePlan: m['care_follows_care_plan'], carePersonalCareQuality: m['care_personal_care_quality'], careMobilityAssistance: m['care_mobility_assistance'],
      careMedicationAdministration: m['care_medication_administration'], careNutritionHydration: m['care_nutrition_hydration'], careDocumentation: m['care_documentation'], careHandoverCommunication: m['care_handover_communication'],
      safetyRiskAssessment: m['safety_risk_assessment'], safetyEnvironmentCheck: m['safety_environment_check'], safetyMovingHandling: m['safety_moving_handling'],
      safetyEmergencyKnowledge: m['safety_emergency_knowledge'], safetyMedicationSecurity: m['safety_medication_security'], safetyChallengingBehaviour: m['safety_challenging_behaviour'],
      commDailyNoteQuality: m['comm_daily_note_quality'], commIncidentReporting: m['comm_incident_reporting'], commFamilyCommunication: m['comm_family_communication'],
      commOtherProfessionals: m['comm_other_professionals'], commEscalationAwareness: m['comm_escalation_awareness'],
      profCodeOfConduct: m['prof_code_of_conduct'], profMedicationKnowledge: m['prof_medication_knowledge'], profSafeguardingKnowledge: m['prof_safeguarding_knowledge'],
      profDataProtection: m['prof_data_protection'], profTeamWorking: m['prof_team_working'], profFeedbackReceptiveness: m['prof_feedback_receptiveness'],
      flagMedicationError: m['flag_medication_error'] as bool? ?? false, flagInfectionBreach: m['flag_infection_breach'] as bool? ?? false,
      flagDignityBreach: m['flag_dignity_breach'] as bool? ?? false, flagSafeguardingConcern: m['flag_safeguarding_concern'] as bool? ?? false,
      flagUnauthorizedAbsence: m['flag_unauthorized_absence'] as bool? ?? false, flagUntrainedTask: m['flag_untrained_task'] as bool? ?? false,
      flagFalsifiedRecords: m['flag_falsified_records'] as bool? ?? false, flagRefusedCare: m['flag_refused_care'] as bool? ?? false,
      flagAggressiveBehaviour: m['flag_aggressive_behaviour'] as bool? ?? false,
      totalScore: m['total_score'], maxPossibleScore: m['max_possible_score'] as int? ?? 240,
      overallPercentage: (m['overall_percentage'] as num?)?.toDouble(), competencyRating: m['competency_rating'],
      strengths: m['strengths'], areasForImprovement: m['areas_for_improvement'], immediateConcerns: m['immediate_concerns'], additionalObservations: m['additional_observations'],
      requiresAction: m['requires_action'] as bool? ?? false, actionRequired: m['action_required'],
      actionAssignedTo: m['action_assigned_to'], actionDeadline: m['action_deadline'] != null ? _p(m['action_deadline']) : null,
      actionCompleted: m['action_completed'] as bool? ?? false, actionCompletedDate: m['action_completed_date'] != null ? _p(m['action_completed_date']) : null, actionNotes: m['action_notes'],
      followUpRequired: m['follow_up_required'] as bool? ?? false, followUpDate: m['follow_up_date'] != null ? _p(m['follow_up_date']) : null, followUpType: m['follow_up_type'], followUpCompleted: m['follow_up_completed'] as bool? ?? false,
      auditorSignature: m['auditor_signature'],
      carerAcknowledged: m['carer_acknowledged'] as bool? ?? false, carerAcknowledgedAt: m['carer_acknowledged_at'] != null ? _p(m['carer_acknowledged_at']) : null, carerComments: m['carer_comments'],
      managerReviewed: m['manager_reviewed'] as bool? ?? false, managerReviewedBy: m['manager_reviewed_by'], managerReviewedAt: m['manager_reviewed_at'] != null ? _p(m['manager_reviewed_at']) : null, managerNotes: m['manager_notes'],
      status: m['status'] as String? ?? 'draft', createdAt: _p(m['created_at']), updatedAt: _p(m['updated_at']), organisationId: m['organisation_id'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      if (id != null) 'id': id,
      'service_user_id': serviceUserId, 'service_user_name': serviceUserName,
      'service_user_dob': serviceUserDob?.toIso8601String().split('T').first,
      'carer_id': carerId, 'carer_name': carerName, 'carer_role': carerRole, 'carer_employment_type': carerEmploymentType,
      'spot_check_date': spotCheckDate.toIso8601String().split('T').first, 'spot_check_time': spotCheckTime,
      'spot_check_duration_minutes': spotCheckDurationMinutes, 'spot_check_type': spotCheckType, 'spot_check_reason': spotCheckReason,
      'conducted_by_id': conductedById, 'conducted_by_name': conductedByName, 'conducted_by_role': conductedByRole,
      'witness_present': witnessPresent, 'witness_name': witnessName, 'witness_role': witnessRole,
      'prep_handover_reviewed': prepHandoverReviewed, 'prep_medication_checked': prepMedicationChecked, 'prep_equipment_ready': prepEquipmentReady,
      'arrival_punctuality': arrivalPunctuality, 'arrival_presentation': arrivalPresentation, 'arrival_communication': arrivalCommunication,
      'ic_hand_hygiene': icHandHygiene, 'ic_ppe_worn': icPpeWorn, 'ic_ppe_changed': icPpeChanged,
      'ic_equipment_cleanliness': icEquipmentCleanliness, 'ic_environment_hygiene': icEnvironmentHygiene, 'ic_waste_disposal': icWasteDisposal,
      'interaction_greeting': interactionGreeting, 'interaction_consent': interactionConsent, 'interaction_dignity': interactionDignity,
      'interaction_privacy': interactionPrivacy, 'interaction_communication': interactionCommunication, 'interaction_hearing_listening': interactionHearingListening,
      'interaction_choice_promoted': interactionChoicePromoted, 'interaction_capacity_considered': interactionCapacityConsidered, 'interaction_emotional_support': interactionEmotionalSupport,
      'care_follows_care_plan': careFollowsCarePlan, 'care_personal_care_quality': carePersonalCareQuality, 'care_mobility_assistance': careMobilityAssistance,
      'care_medication_administration': careMedicationAdministration, 'care_nutrition_hydration': careNutritionHydration, 'care_documentation': careDocumentation, 'care_handover_communication': careHandoverCommunication,
      'safety_risk_assessment': safetyRiskAssessment, 'safety_environment_check': safetyEnvironmentCheck, 'safety_moving_handling': safetyMovingHandling,
      'safety_emergency_knowledge': safetyEmergencyKnowledge, 'safety_medication_security': safetyMedicationSecurity, 'safety_challenging_behaviour': safetyChallengingBehaviour,
      'comm_daily_note_quality': commDailyNoteQuality, 'comm_incident_reporting': commIncidentReporting, 'comm_family_communication': commFamilyCommunication,
      'comm_other_professionals': commOtherProfessionals, 'comm_escalation_awareness': commEscalationAwareness,
      'prof_code_of_conduct': profCodeOfConduct, 'prof_medication_knowledge': profMedicationKnowledge, 'prof_safeguarding_knowledge': profSafeguardingKnowledge,
      'prof_data_protection': profDataProtection, 'prof_team_working': profTeamWorking, 'prof_feedback_receptiveness': profFeedbackReceptiveness,
      'flag_medication_error': flagMedicationError, 'flag_infection_breach': flagInfectionBreach, 'flag_dignity_breach': flagDignityBreach,
      'flag_safeguarding_concern': flagSafeguardingConcern, 'flag_unauthorized_absence': flagUnauthorizedAbsence, 'flag_untrained_task': flagUntrainedTask,
      'flag_falsified_records': flagFalsifiedRecords, 'flag_refused_care': flagRefusedCare, 'flag_aggressive_behaviour': flagAggressiveBehaviour,
      'total_score': totalScore, 'overall_percentage': overallPercentage, 'competency_rating': competencyRating,
      'strengths': strengths, 'areas_for_improvement': areasForImprovement, 'immediate_concerns': immediateConcerns, 'additional_observations': additionalObservations,
      'requires_action': requiresAction, 'action_required': actionRequired, 'action_assigned_to': actionAssignedTo,
      'action_deadline': actionDeadline?.toIso8601String().split('T').first, 'action_completed': actionCompleted,
      'action_completed_date': actionCompletedDate?.toIso8601String().split('T').first, 'action_notes': actionNotes,
      'follow_up_required': followUpRequired, 'follow_up_date': followUpDate?.toIso8601String().split('T').first, 'follow_up_type': followUpType, 'follow_up_completed': followUpCompleted,
      'auditor_signature': auditorSignature, 'carer_acknowledged': carerAcknowledged, 'carer_acknowledged_at': carerAcknowledgedAt?.toIso8601String(),
      'carer_comments': carerComments, 'manager_reviewed': managerReviewed, 'manager_reviewed_by': managerReviewedBy,
      'manager_reviewed_at': managerReviewedAt?.toIso8601String(), 'manager_notes': managerNotes,
      'status': status, 'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(), 'organisation_id': organisationId,
    };
    map.removeWhere((k, v) => v == null);
    return map;
  }
}

class SpotCheckHelper {
  static String calcRating(double pct, bool hasFlags) {
    if (hasFlags || pct < 50) return 'immediate_action';
    if (pct >= 90) return 'exceeds_expectations';
    if (pct >= 70) return 'meets_expectations';
    if (pct >= 50) return 'requires_improvement';
    return 'unsatisfactory';
  }

  static Color getRatingColor(String? r) {
    switch (r) {
      case 'exceeds_expectations': return const Color(0xFF4CAF50);
      case 'meets_expectations': return const Color(0xFFFF9800);
      case 'requires_improvement': return const Color(0xFFF44336);
      case 'unsatisfactory': return const Color(0xFFB71C1C);
      case 'immediate_action': return const Color(0xFFB71C1C);
      default: return Colors.grey;
    }
  }

  static String getRatingLabel(String? r) {
    switch (r) {
      case 'exceeds_expectations': return 'Exceeds Expectations';
      case 'meets_expectations': return 'Meets Expectations';
      case 'requires_improvement': return 'Requires Improvement';
      case 'unsatisfactory': return 'Unsatisfactory';
      case 'immediate_action': return 'Immediate Action Required';
      default: return 'Not Rated';
    }
  }

  static String getRatingBadge(String? r) {
    switch (r) {
      case 'exceeds_expectations': return 'Excellent';
      case 'meets_expectations': return 'Good';
      case 'requires_improvement': return 'Needs Work';
      case 'unsatisfactory': return 'Unsatisfactory';
      case 'immediate_action': return '⚠️ IMMEDIATE ACTION';
      default: return 'Draft';
    }
  }

  static IconData getRatingIcon(String? r) {
    switch (r) {
      case 'exceeds_expectations': return Icons.star;
      case 'meets_expectations': return Icons.thumb_up;
      case 'requires_improvement': return Icons.warning;
      case 'unsatisfactory': return Icons.error;
      case 'immediate_action': return Icons.gpp_bad;
      default: return Icons.help;
    }
  }

  static const ratingLabels = ['Not Observed', 'Poor', 'Needs Improvement', 'Good', 'Very Good', 'Excellent'];
  static const ratingColors = [Colors.grey, Colors.red, Colors.orange, Colors.blue, Colors.green, Colors.teal];
}