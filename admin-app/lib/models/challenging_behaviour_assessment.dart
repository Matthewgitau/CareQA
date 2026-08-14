import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';

class ChallengingBehaviourAssessment {
  final String? id;
  final String? serviceUserId;
  final DateTime assessmentDate;
  final String behaviourType;
  final String behaviourFrequency;
  final int? behaviourDurationMinutes;
  final String intensity;
  final List<String>? triggers;
  final List<String>? warningSigns;
  final List<String>? deEscalationStrategies;
  final String medicationUsed;
  final String injuriesCaused;
  final bool injuriesToSelf;
  final bool injuriesToOthers;
  final bool propertyDamage;
  final bool staffTrainedDeEscalation;
  final bool pbsPlanInPlace;
  final String? environmentalModificationsNeeded;
  final String supportNeeds;
  final String riskLevel;
  final String? actionPlan;
  final DateTime? reviewDate;
  final DateTime? nextBehaviourMonitoringDate;
  final String assessorName;
  final String? assessorSignature;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChallengingBehaviourAssessment({
    this.id,
    this.serviceUserId,
    required this.assessmentDate,
    required this.behaviourType,
    required this.behaviourFrequency,
    this.behaviourDurationMinutes,
    required this.intensity,
    this.triggers,
    this.warningSigns,
    this.deEscalationStrategies,
    required this.medicationUsed,
    required this.injuriesCaused,
    required this.injuriesToSelf,
    required this.injuriesToOthers,
    required this.propertyDamage,
    required this.staffTrainedDeEscalation,
    required this.pbsPlanInPlace,
    this.environmentalModificationsNeeded,
    required this.supportNeeds,
    required this.riskLevel,
    this.actionPlan,
    this.reviewDate,
    this.nextBehaviourMonitoringDate,
    required this.assessorName,
    this.assessorSignature,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChallengingBehaviourAssessment.fromMap(Map<String, dynamic> map) {
    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value.toLocal();
      return DateTime.parse(value).toLocal();
    }

    return ChallengingBehaviourAssessment(
      id: map['id'],
      serviceUserId: map['service_user_id'],
      assessmentDate: _parseDate(map['assessment_date']),
      behaviourType: map['behaviour_type'] as String? ?? '',
      behaviourFrequency: map['behaviour_frequency'] as String? ?? '',
      behaviourDurationMinutes: map['behaviour_duration_minutes'],
      intensity: map['intensity'] as String? ?? '',
      triggers: map['triggers'] != null ? List<String>.from(map['triggers']) : [],
      warningSigns: map['warning_signs'] != null ? List<String>.from(map['warning_signs']) : [],
      deEscalationStrategies: map['de_escalation_strategies'] != null ? List<String>.from(map['de_escalation_strategies']) : [],
      medicationUsed: map['medication_used'] as String? ?? '',
      injuriesCaused: map['injuries_caused'] as String? ?? '',
      injuriesToSelf: map['injuries_to_self'] as bool? ?? false,
      injuriesToOthers: map['injuries_to_others'] as bool? ?? false,
      propertyDamage: map['property_damage'] as bool? ?? false,
      staffTrainedDeEscalation: map['staff_trained_de_escalation'] as bool? ?? false,
      pbsPlanInPlace: map['pbs_plan_in_place'] as bool? ?? false,
      environmentalModificationsNeeded: map['environmental_modifications_needed'],
      supportNeeds: map['support_needs'] as String? ?? '',
      riskLevel: map['risk_level'] as String? ?? '',
      actionPlan: map['action_plan'],
      reviewDate: map['review_date'] != null ? _parseDate(map['review_date']) : null,
      nextBehaviourMonitoringDate: map['next_behaviour_monitoring_date'] != null ? _parseDate(map['next_behaviour_monitoring_date']) : null,
      assessorName: map['assessor_name'] as String? ?? '',
      assessorSignature: map['assessor_signature'],
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'service_user_id': serviceUserId,
      'assessment_date': assessmentDate.toIso8601String(),
      'behaviour_type': behaviourType,
      'behaviour_frequency': behaviourFrequency,
      'behaviour_duration_minutes': behaviourDurationMinutes,
      'intensity': intensity,
      'triggers': triggers,
      'warning_signs': warningSigns,
      'de_escalation_strategies': deEscalationStrategies,
      'medication_used': medicationUsed,
      'injuries_caused': injuriesCaused,
      'injuries_to_self': injuriesToSelf,
      'injuries_to_others': injuriesToOthers,
      'property_damage': propertyDamage,
      'staff_trained_de_escalation': staffTrainedDeEscalation,
      'pbs_plan_in_place': pbsPlanInPlace,
      'environmental_modifications_needed': environmentalModificationsNeeded,
      'support_needs': supportNeeds,
      'risk_level': riskLevel,
      'action_plan': actionPlan,
      'review_date': reviewDate?.toIso8601String(),
      'next_behaviour_monitoring_date': nextBehaviourMonitoringDate?.toIso8601String(),
      'assessor_name': assessorName,
      'assessor_signature': assessorSignature,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Get behaviour type display text
  String get behaviourTypeText {
    switch (behaviourType) {
      case 'aggression':
        return 'Aggression';
      case 'self_harm':
        return 'Self-Harm';
      case 'wandering':
        return 'Wandering';
      case 'sexual':
        return 'Sexual Behaviour';
      case 'inappropriate':
        return 'Inappropriate Behaviour';
      case 'vocal':
        return 'Vocal Behaviour';
      case 'withdrawal':
        return 'Withdrawal';
      default:
        return behaviourType;
    }
  }

  // Get frequency display text
  String get frequencyText {
    switch (behaviourFrequency) {
      case 'hourly':
        return 'Hourly';
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return behaviourFrequency;
    }
  }

  // Get intensity display text
  String get intensityText {
    switch (intensity) {
      case 'mild':
        return 'Mild';
      case 'moderate':
        return 'Moderate';
      case 'severe':
        return 'Severe';
      default:
        return intensity;
    }
  }

  // Get medication display text
  String get medicationText {
    switch (medicationUsed) {
      case 'none':
        return 'None';
      case 'prn':
        return 'PRN (As Needed)';
      case 'regular':
        return 'Regular';
      default:
        return medicationUsed;
    }
  }

  // Get support needs display text
  String get supportNeedsText {
    switch (supportNeeds) {
      case 'none':
        return 'None';
      case '1:1':
        return '1:1 Support';
      case '2:1':
        return '2:1 Support';
      case 'specialist':
        return 'Specialist Support';
      default:
        return supportNeeds;
    }
  }

  // Get risk level color
  String get riskLevelColor {
    switch (riskLevel) {
      case 'low':
        return '🟢';
      case 'medium':
        return '🟡';
      case 'high':
        return '🟠';
      case 'critical':
        return '🔴';
      default:
        return '⚪';
    }
  }

  // Get risk level text with severity
  String get riskLevelText {
    switch (riskLevel) {
      case 'low':
        return 'Low Risk';
      case 'medium':
        return 'Medium Risk';
      case 'high':
        return 'High Risk';
      case 'critical':
        return 'CRITICAL RISK';
      default:
        return riskLevel;
    }
  }

  // Check if critical rules are triggered
  bool get isUrgent {
    return injuriesToOthers && intensity == 'severe';
  }

  bool get needsEscalation {
    return injuriesToSelf && (behaviourFrequency == 'hourly' || behaviourFrequency == 'daily');
  }

  bool get needsReview {
    return propertyDamage && behaviourType == 'aggression';
  }

  // Get high-risk factors count
  int get highRiskFactorsCount {
    int count = 0;
    
    if (intensity == 'severe') count += 2;
    if (intensity == 'moderate') count += 1;
    if (behaviourFrequency == 'hourly' || behaviourFrequency == 'daily') count += 1;
    if (injuriesToOthers) count += 2;
    if (injuriesToSelf) count += 1;
    if (propertyDamage) count += 1;
    
    return count;
  }

  // Get behaviour duration text
  String get durationText {
    if (behaviourDurationMinutes == null) {
      return 'Not specified';
    }
    if (behaviourDurationMinutes! == 0) {
      return 'Brief';
    }
    return '${behaviourDurationMinutes!} minutes';
  }

  // Get triggers summary
  String get triggersSummary {
    if (triggers == null || triggers!.isEmpty) {
      return 'No triggers identified';
    }
    return triggers!.join(', ');
  }

  // Get warning signs summary
  String get warningSignsSummary {
    if (warningSigns == null || warningSigns!.isEmpty) {
      return 'No warning signs identified';
    }
    return warningSigns!.join(', ');
  }

  // Get de-escalation strategies summary
  String get deEscalationSummary {
    if (deEscalationStrategies == null || deEscalationStrategies!.isEmpty) {
      return 'No strategies identified';
    }
    return deEscalationStrategies!.join(', ');
  }

  // Check if review is due
  bool get isReviewDue {
    if (reviewDate == null) {
      return false;
    }
    return reviewDate!.isBefore(DateTime.now());
  }

  // Check if behaviour monitoring is due
  bool get isMonitoringDue {
    if (nextBehaviourMonitoringDate == null) {
      return false;
    }
    return nextBehaviourMonitoringDate!.isBefore(DateTime.now());
  }

  // Get action plan summary
  String get actionPlanSummary {
    if (actionPlan == null || actionPlan!.isEmpty) {
      return 'No action plan specified';
    }
    return actionPlan!;
  }

  // Get environmental modifications summary
  String get environmentalModificationsSummary {
    if (environmentalModificationsNeeded == null || environmentalModificationsNeeded!.isEmpty) {
      return 'No modifications needed';
    }
    return environmentalModificationsNeeded!;
  }

  // Get PBS plan status text
  String get pbsPlanStatus {
    return pbsPlanInPlace ? 'In Place' : 'Not in Place';
  }

  // Get staff training status text
  String get staffTrainingStatus {
    return staffTrainedDeEscalation ? 'Trained' : 'Not Trained';
  }

  @override
  String toString() {
    return 'ChallengingBehaviourAssessment(id: $id, serviceUserId: $serviceUserId, assessmentDate: $assessmentDate, behaviourType: $behaviourType, riskLevel: $riskLevel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ChallengingBehaviourAssessment &&
           other.id == id &&
           other.serviceUserId == serviceUserId &&
           other.assessmentDate == assessmentDate &&
           other.behaviourType == behaviourType &&
           other.behaviourFrequency == behaviourFrequency &&
           other.behaviourDurationMinutes == behaviourDurationMinutes &&
           other.intensity == intensity &&
           other.triggers == triggers &&
           other.warningSigns == warningSigns &&
           other.deEscalationStrategies == deEscalationStrategies &&
           other.medicationUsed == medicationUsed &&
           other.injuriesCaused == injuriesCaused &&
           other.injuriesToSelf == injuriesToSelf &&
           other.injuriesToOthers == injuriesToOthers &&
           other.propertyDamage == propertyDamage &&
           other.staffTrainedDeEscalation == staffTrainedDeEscalation &&
           other.pbsPlanInPlace == pbsPlanInPlace &&
           other.environmentalModificationsNeeded == environmentalModificationsNeeded &&
           other.supportNeeds == supportNeeds &&
           other.riskLevel == riskLevel &&
           other.actionPlan == actionPlan &&
           other.reviewDate == reviewDate &&
           other.nextBehaviourMonitoringDate == nextBehaviourMonitoringDate &&
           other.assessorName == assessorName &&
           other.assessorSignature == assessorSignature &&
           other.createdAt == createdAt &&
           other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
           serviceUserId.hashCode ^
           assessmentDate.hashCode ^
           behaviourType.hashCode ^
           behaviourFrequency.hashCode ^
           behaviourDurationMinutes.hashCode ^
           intensity.hashCode ^
           triggers.hashCode ^
           warningSigns.hashCode ^
           deEscalationStrategies.hashCode ^
           medicationUsed.hashCode ^
           injuriesCaused.hashCode ^
           injuriesToSelf.hashCode ^
           injuriesToOthers.hashCode ^
           propertyDamage.hashCode ^
           staffTrainedDeEscalation.hashCode ^
           pbsPlanInPlace.hashCode ^
           environmentalModificationsNeeded.hashCode ^
           supportNeeds.hashCode ^
           riskLevel.hashCode ^
           actionPlan.hashCode ^
           reviewDate.hashCode ^
           nextBehaviourMonitoringDate.hashCode ^
           assessorName.hashCode ^
           assessorSignature.hashCode ^
           createdAt.hashCode ^
           updatedAt.hashCode;
  }
}