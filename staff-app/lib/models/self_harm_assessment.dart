import 'package:flutter/material.dart';

class SelfHarmAssessment {
  final String? id;
  final String serviceUserId;
  final String? assessorId;
  
  // Current suicidal ideation (critical field)
  final String currentSuicidalIdeation;
  final String? currentSuicidalIdeationDetails;
  
  // Previous self-harm attempts
  final int previousSelfHarmAttempts;
  final String? previousSelfHarmDetails;
  
  // Method of self-harm
  final String? selfHarmMethod;
  final String? selfHarmMethodOther;
  final bool methodPlanned;
  
  // Frequency of thoughts
  final String? frequencyOfThoughts;
  
  // Triggers
  final bool relationshipTriggers;
  final bool financialTriggers;
  final bool healthTriggers;
  final bool otherTriggers;
  final String? triggerDetails;
  
  // Protective factors
  final bool familySupport;
  final bool friendSupport;
  final bool routineStructure;
  final bool otherProtectiveFactors;
  final String? protectiveFactorsDetails;
  
  // Risk factors
  final bool accessToMeans;
  final String? accessToMeansDetails;
  final String? mentalHealthDiagnosis;
  final String? currentTreatment;
  final String? treatmentDetails;
  
  // Recent life events
  final String? recentLifeEvents;
  final String? substanceUse;
  final String? substanceDetails;
  
  // Behavioral indicators
  final bool sleepDisturbances;
  final bool withdrawalFromActivities;
  final bool givingAwayPossessions;
  final bool makingPlansArrangements;
  
  // Risk assessment
  final String? overallRiskLevel;
  final List<String> riskFactorsIdentified;
  final List<String> protectiveFactorsIdentified;
  
  // Action plan
  final bool immediateActionsRequired;
  final String? immediateActions;
  final String? followUpActions;
  final String? crisisContacts;
  final DateTime? nextReviewDate;
  
  // Status and compliance
  final String status;
  final String? signature;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  SelfHarmAssessment({
    this.id,
    required this.serviceUserId,
    this.assessorId,
    required this.currentSuicidalIdeation,
    this.currentSuicidalIdeationDetails,
    required this.previousSelfHarmAttempts,
    this.previousSelfHarmDetails,
    this.selfHarmMethod,
    this.selfHarmMethodOther,
    required this.methodPlanned,
    this.frequencyOfThoughts,
    required this.relationshipTriggers,
    required this.financialTriggers,
    required this.healthTriggers,
    required this.otherTriggers,
    this.triggerDetails,
    required this.familySupport,
    required this.friendSupport,
    required this.routineStructure,
    required this.otherProtectiveFactors,
    this.protectiveFactorsDetails,
    required this.accessToMeans,
    this.accessToMeansDetails,
    this.mentalHealthDiagnosis,
    this.currentTreatment,
    this.treatmentDetails,
    this.recentLifeEvents,
    this.substanceUse,
    this.substanceDetails,
    required this.sleepDisturbances,
    required this.withdrawalFromActivities,
    required this.givingAwayPossessions,
    required this.makingPlansArrangements,
    this.overallRiskLevel,
    required this.riskFactorsIdentified,
    required this.protectiveFactorsIdentified,
    required this.immediateActionsRequired,
    this.immediateActions,
    this.followUpActions,
    this.crisisContacts,
    this.nextReviewDate,
    required this.status,
    this.signature,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SelfHarmAssessment.fromJson(Map<String, dynamic> json) {
    return SelfHarmAssessment(
      id: json['id'],
      serviceUserId: json['service_user_id'],
      assessorId: json['assessor_id'],
      currentSuicidalIdeation: json['current_suicidal_ideation'],
      currentSuicidalIdeationDetails: json['current_suicidal_ideation_details'],
      previousSelfHarmAttempts: json['previous_self_harm_attempts'] ?? 0,
      previousSelfHarmDetails: json['previous_self_harm_details'],
      selfHarmMethod: json['self_harm_method'],
      selfHarmMethodOther: json['self_harm_method_other'],
      methodPlanned: json['method_planned'] ?? false,
      frequencyOfThoughts: json['frequency_of_thoughts'],
      relationshipTriggers: json['relationship_triggers'] ?? false,
      financialTriggers: json['financial_triggers'] ?? false,
      healthTriggers: json['health_triggers'] ?? false,
      otherTriggers: json['other_triggers'] ?? false,
      triggerDetails: json['trigger_details'],
      familySupport: json['family_support'] ?? false,
      friendSupport: json['friend_support'] ?? false,
      routineStructure: json['routine_structure'] ?? false,
      otherProtectiveFactors: json['other_protective_factors'] ?? false,
      protectiveFactorsDetails: json['protective_factors_details'],
      accessToMeans: json['access_to_means'] ?? false,
      accessToMeansDetails: json['access_to_means_details'],
      mentalHealthDiagnosis: json['mental_health_diagnosis'],
      currentTreatment: json['current_treatment'],
      treatmentDetails: json['treatment_details'],
      recentLifeEvents: json['recent_life_events'],
      substanceUse: json['substance_use'],
      substanceDetails: json['substance_details'],
      sleepDisturbances: json['sleep_disturbances'] ?? false,
      withdrawalFromActivities: json['withdrawal_from_activities'] ?? false,
      givingAwayPossessions: json['giving_away_possessions'] ?? false,
      makingPlansArrangements: json['making_plans_arrangements'] ?? false,
      overallRiskLevel: json['overall_risk_level'],
      riskFactorsIdentified: List<String>.from(json['risk_factors_identified'] ?? []),
      protectiveFactorsIdentified: List<String>.from(json['protective_factors_identified'] ?? []),
      immediateActionsRequired: json['immediate_actions_required'] ?? false,
      immediateActions: json['immediate_actions'],
      followUpActions: json['follow_up_actions'],
      crisisContacts: json['crisis_contacts'],
      nextReviewDate: json['next_review_date'] != null ? DateTime.parse(json['next_review_date']) : null,
      status: json['status'] ?? 'draft',
      signature: json['signature'],
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_user_id': serviceUserId,
      'assessor_id': assessorId,
      'current_suicidal_ideation': currentSuicidalIdeation,
      'current_suicidal_ideation_details': currentSuicidalIdeationDetails,
      'previous_self_harm_attempts': previousSelfHarmAttempts,
      'previous_self_harm_details': previousSelfHarmDetails,
      'self_harm_method': selfHarmMethod,
      'self_harm_method_other': selfHarmMethodOther,
      'method_planned': methodPlanned,
      'frequency_of_thoughts': frequencyOfThoughts,
      'relationship_triggers': relationshipTriggers,
      'financial_triggers': financialTriggers,
      'health_triggers': healthTriggers,
      'other_triggers': otherTriggers,
      'trigger_details': triggerDetails,
      'family_support': familySupport,
      'friend_support': friendSupport,
      'routine_structure': routineStructure,
      'other_protective_factors': otherProtectiveFactors,
      'protective_factors_details': protectiveFactorsDetails,
      'access_to_means': accessToMeans,
      'access_to_means_details': accessToMeansDetails,
      'mental_health_diagnosis': mentalHealthDiagnosis,
      'current_treatment': currentTreatment,
      'treatment_details': treatmentDetails,
      'recent_life_events': recentLifeEvents,
      'substance_use': substanceUse,
      'substance_details': substanceDetails,
      'sleep_disturbances': sleepDisturbances,
      'withdrawal_from_activities': withdrawalFromActivities,
      'giving_away_possessions': givingAwayPossessions,
      'making_plans_arrangements': makingPlansArrangements,
      'overall_risk_level': overallRiskLevel,
      'risk_factors_identified': riskFactorsIdentified,
      'protective_factors_identified': protectiveFactorsIdentified,
      'immediate_actions_required': immediateActionsRequired,
      'immediate_actions': immediateActions,
      'follow_up_actions': followUpActions,
      'crisis_contacts': crisisContacts,
      'next_review_date': nextReviewDate?.toIso8601String(),
      'status': status,
      'signature': signature,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods for business logic
  String getCurrentSuicidalIdeationDisplay() {
    switch (currentSuicidalIdeation) {
      case 'never':
        return 'Never';
      case 'sometimes':
        return 'Sometimes';
      case 'frequently':
        return 'Frequently';
      case 'constant':
        return 'Constant';
      default:
        return 'Unknown';
    }
  }

  String getFrequencyOfThoughtsDisplay() {
    switch (frequencyOfThoughts) {
      case 'never':
        return 'Never';
      case 'rarely':
        return 'Rarely';
      case 'sometimes':
        return 'Sometimes';
      case 'often':
        return 'Often';
      case 'constant':
        return 'Constant';
      default:
        return 'Unknown';
    }
  }

  String getCurrentTreatmentDisplay() {
    switch (currentTreatment) {
      case 'none':
        return 'None';
      case 'medication':
        return 'Medication Only';
      case 'therapy':
        return 'Therapy Only';
      case 'both':
        return 'Medication and Therapy';
      default:
        return 'Unknown';
    }
  }

  String getSubstanceUseDisplay() {
    switch (substanceUse) {
      case 'none':
        return 'None';
      case 'occasional':
        return 'Occasional';
      case 'regular':
        return 'Regular';
      case 'problematic':
        return 'Problematic';
      default:
        return 'Unknown';
    }
  }

  // Risk calculation methods
  bool get isHighRisk => overallRiskLevel == 'high' || overallRiskLevel == 'immediate';
  bool get isImmediateRisk => currentSuicidalIdeation == 'constant' || methodPlanned || givingAwayPossessions;
  bool get needsEscalation => isImmediateRisk || overallRiskLevel == 'immediate';
  bool get hasRiskFactors => riskFactorsIdentified.isNotEmpty;
  bool get hasProtectiveFactors => protectiveFactorsIdentified.isNotEmpty;

  // Trigger methods
  List<String> getActiveTriggers() {
    final triggers = <String>[];
    if (relationshipTriggers) triggers.add('Relationship');
    if (financialTriggers) triggers.add('Financial');
    if (healthTriggers) triggers.add('Health');
    if (otherTriggers && triggerDetails != null && triggerDetails!.isNotEmpty) {
      triggers.add('Other: $triggerDetails');
    }
    return triggers;
  }

  // Protective factors methods
  List<String> getActiveProtectiveFactors() {
    final factors = <String>[];
    if (familySupport) factors.add('Family Support');
    if (friendSupport) factors.add('Friend Support');
    if (routineStructure) factors.add('Routine Structure');
    if (otherProtectiveFactors && protectiveFactorsDetails != null && protectiveFactorsDetails!.isNotEmpty) {
      factors.add('Other: $protectiveFactorsDetails');
    }
    return factors;
  }

  // Validation methods
  bool get isComplete {
    return currentSuicidalIdeation.isNotEmpty &&
           frequencyOfThoughts != null &&
           overallRiskLevel != null &&
           nextReviewDate != null;
  }

  String getCompletionStatus() {
    if (isComplete) return 'Complete';
    return 'Incomplete';
  }

  // Escalation checks
  bool get requiresImmediateEscalation => currentSuicidalIdeation == 'constant';
  bool get requiresSafeguardingAlert => methodPlanned || givingAwayPossessions;

  // Common options for dropdowns
  static List<String> getCurrentSuicidalIdeationOptions() => ['never', 'sometimes', 'frequently', 'constant'];
  static List<String> getFrequencyOfThoughtsOptions() => ['never', 'rarely', 'sometimes', 'often', 'constant'];
  static List<String> getSelfHarmMethodOptions() => ['cutting', 'overdose', 'hanging', 'jumping', 'other'];
  static List<String> getCurrentTreatmentOptions() => ['none', 'medication', 'therapy', 'both'];
  static List<String> getSubstanceUseOptions() => ['none', 'occasional', 'regular', 'problematic'];
  static List<String> getRiskLevels() => ['low', 'medium', 'high', 'immediate'];
  static List<String> getRiskFactors() => [
    'Previous attempts',
    'Access to means',
    'Mental health diagnosis',
    'Substance use',
    'Sleep disturbances',
    'Social isolation',
    'Recent life events'
  ];

  // Factory method for creating a new assessment
  static SelfHarmAssessment createNew(String serviceUserId, String? assessorId) {
    return SelfHarmAssessment(
      serviceUserId: serviceUserId,
      assessorId: assessorId,
      currentSuicidalIdeation: 'never', // Default to never
      previousSelfHarmAttempts: 0,
      methodPlanned: false,
      relationshipTriggers: false,
      financialTriggers: false,
      healthTriggers: false,
      otherTriggers: false,
      familySupport: false,
      friendSupport: false,
      routineStructure: false,
      otherProtectiveFactors: false,
      accessToMeans: false,
      sleepDisturbances: false,
      withdrawalFromActivities: false,
      givingAwayPossessions: false,
      makingPlansArrangements: false,
      riskFactorsIdentified: [],
      protectiveFactorsIdentified: [],
      immediateActionsRequired: false,
      status: 'draft',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // CopyWith method for updating specific fields
  SelfHarmAssessment copyWith({
    String? id,
    String? serviceUserId,
    String? assessorId,
    String? currentSuicidalIdeation,
    String? currentSuicidalIdeationDetails,
    int? previousSelfHarmAttempts,
    String? previousSelfHarmDetails,
    String? selfHarmMethod,
    String? selfHarmMethodOther,
    bool? methodPlanned,
    String? frequencyOfThoughts,
    bool? relationshipTriggers,
    bool? financialTriggers,
    bool? healthTriggers,
    bool? otherTriggers,
    String? triggerDetails,
    bool? familySupport,
    bool? friendSupport,
    bool? routineStructure,
    bool? otherProtectiveFactors,
    String? protectiveFactorsDetails,
    bool? accessToMeans,
    String? accessToMeansDetails,
    String? mentalHealthDiagnosis,
    String? currentTreatment,
    String? treatmentDetails,
    String? recentLifeEvents,
    String? substanceUse,
    String? substanceDetails,
    bool? sleepDisturbances,
    bool? withdrawalFromActivities,
    bool? givingAwayPossessions,
    bool? makingPlansArrangements,
    String? overallRiskLevel,
    List<String>? riskFactorsIdentified,
    List<String>? protectiveFactorsIdentified,
    bool? immediateActionsRequired,
    String? immediateActions,
    String? followUpActions,
    String? crisisContacts,
    DateTime? nextReviewDate,
    String? status,
    String? signature,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SelfHarmAssessment(
      id: id ?? this.id,
      serviceUserId: serviceUserId ?? this.serviceUserId,
      assessorId: assessorId ?? this.assessorId,
      currentSuicidalIdeation: currentSuicidalIdeation ?? this.currentSuicidalIdeation,
      currentSuicidalIdeationDetails: currentSuicidalIdeationDetails ?? this.currentSuicidalIdeationDetails,
      previousSelfHarmAttempts: previousSelfHarmAttempts ?? this.previousSelfHarmAttempts,
      previousSelfHarmDetails: previousSelfHarmDetails ?? this.previousSelfHarmDetails,
      selfHarmMethod: selfHarmMethod ?? this.selfHarmMethod,
      selfHarmMethodOther: selfHarmMethodOther ?? this.selfHarmMethodOther,
      methodPlanned: methodPlanned ?? this.methodPlanned,
      frequencyOfThoughts: frequencyOfThoughts ?? this.frequencyOfThoughts,
      relationshipTriggers: relationshipTriggers ?? this.relationshipTriggers,
      financialTriggers: financialTriggers ?? this.financialTriggers,
      healthTriggers: healthTriggers ?? this.healthTriggers,
      otherTriggers: otherTriggers ?? this.otherTriggers,
      triggerDetails: triggerDetails ?? this.triggerDetails,
      familySupport: familySupport ?? this.familySupport,
      friendSupport: friendSupport ?? this.friendSupport,
      routineStructure: routineStructure ?? this.routineStructure,
      otherProtectiveFactors: otherProtectiveFactors ?? this.otherProtectiveFactors,
      protectiveFactorsDetails: protectiveFactorsDetails ?? this.protectiveFactorsDetails,
      accessToMeans: accessToMeans ?? this.accessToMeans,
      accessToMeansDetails: accessToMeansDetails ?? this.accessToMeansDetails,
      mentalHealthDiagnosis: mentalHealthDiagnosis ?? this.mentalHealthDiagnosis,
      currentTreatment: currentTreatment ?? this.currentTreatment,
      treatmentDetails: treatmentDetails ?? this.treatmentDetails,
      recentLifeEvents: recentLifeEvents ?? this.recentLifeEvents,
      substanceUse: substanceUse ?? this.substanceUse,
      substanceDetails: substanceDetails ?? this.substanceDetails,
      sleepDisturbances: sleepDisturbances ?? this.sleepDisturbances,
      withdrawalFromActivities: withdrawalFromActivities ?? this.withdrawalFromActivities,
      givingAwayPossessions: givingAwayPossessions ?? this.givingAwayPossessions,
      makingPlansArrangements: makingPlansArrangements ?? this.makingPlansArrangements,
      overallRiskLevel: overallRiskLevel ?? this.overallRiskLevel,
      riskFactorsIdentified: riskFactorsIdentified ?? this.riskFactorsIdentified,
      protectiveFactorsIdentified: protectiveFactorsIdentified ?? this.protectiveFactorsIdentified,
      immediateActionsRequired: immediateActionsRequired ?? this.immediateActionsRequired,
      immediateActions: immediateActions ?? this.immediateActions,
      followUpActions: followUpActions ?? this.followUpActions,
      crisisContacts: crisisContacts ?? this.crisisContacts,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      status: status ?? this.status,
      signature: signature ?? this.signature,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}