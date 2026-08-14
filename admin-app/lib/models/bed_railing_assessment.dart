import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class BedRailingAssessment {
  final String? id;
  final String? serviceUserId;
  final DateTime assessmentDate;
  final String bedType;
  final String bedRailsType;
  final String railCondition;
  final bool manufacturerInstructionsAvailable;
  final String railHeightAndFit;
  final bool entrapmentRiskAssessed;
  final String patientMobility;
  final bool cognitiveImpairment;
  final bool agitationRestlessness;
  final String riskOfFallingOutOfBed;
  final String riskOfEntrapment;
  final bool alternativeMeasuresConsidered;
  final bool familyConsentObtained;
  final bool staffTrainedInBedRailUse;
  final bool railRegularlyChecked;
  final DateTime? lastCheckDate;
  final DateTime? nextCheckDate;
  final String? actionPlan;
  final DateTime? reviewDate;
  final String assessorName;
  final String? assessorSignature;
  final DateTime createdAt;
  final DateTime updatedAt;

  BedRailingAssessment({
    this.id,
    this.serviceUserId,
    required this.assessmentDate,
    required this.bedType,
    required this.bedRailsType,
    required this.railCondition,
    required this.manufacturerInstructionsAvailable,
    required this.railHeightAndFit,
    required this.entrapmentRiskAssessed,
    required this.patientMobility,
    required this.cognitiveImpairment,
    required this.agitationRestlessness,
    required this.riskOfFallingOutOfBed,
    required this.riskOfEntrapment,
    required this.alternativeMeasuresConsidered,
    required this.familyConsentObtained,
    required this.staffTrainedInBedRailUse,
    required this.railRegularlyChecked,
    this.lastCheckDate,
    this.nextCheckDate,
    this.actionPlan,
    this.reviewDate,
    required this.assessorName,
    this.assessorSignature,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BedRailingAssessment.fromMap(Map<String, dynamic> map) {
    return BedRailingAssessment(
      id: map['id'],
      serviceUserId: map['service_user_id'],
      assessmentDate: map['assessment_date'] is DateTime 
          ? map['assessment_date'] 
          : DateTime.parse(map['assessment_date']),
      bedType: map['bed_type'],
      bedRailsType: map['bed_rails_type'],
      railCondition: map['rail_condition'],
      manufacturerInstructionsAvailable: map['manufacturer_instructions_available'],
      railHeightAndFit: map['rail_height_and_fit'],
      entrapmentRiskAssessed: map['entrapment_risk_assessed'],
      patientMobility: map['patient_mobility'],
      cognitiveImpairment: map['cognitive_impairment'],
      agitationRestlessness: map['agitation_restlessness'],
      riskOfFallingOutOfBed: map['risk_of_falling_out_of_bed'],
      riskOfEntrapment: map['risk_of_entrapment'],
      alternativeMeasuresConsidered: map['alternative_measures_considered'],
      familyConsentObtained: map['family_consent_obtained'],
      staffTrainedInBedRailUse: map['staff_trained_in_bed_rail_use'],
      railRegularlyChecked: map['rail_regularly_checked'],
      lastCheckDate: map['last_check_date'] != null 
          ? map['last_check_date'] is DateTime 
              ? map['last_check_date'] 
              : DateTime.parse(map['last_check_date'])
          : null,
      nextCheckDate: map['next_check_date'] != null 
          ? map['next_check_date'] is DateTime 
              ? map['next_check_date'] 
              : DateTime.parse(map['next_check_date'])
          : null,
      actionPlan: map['action_plan'],
      reviewDate: map['review_date'] != null 
          ? map['review_date'] is DateTime 
              ? map['review_date'] 
              : DateTime.parse(map['review_date'])
          : null,
      assessorName: map['assessor_name'],
      assessorSignature: map['assessor_signature'],
      createdAt: map['created_at'] is DateTime 
          ? map['created_at'] 
          : DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] is DateTime 
          ? map['updated_at'] 
          : DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_user_id': serviceUserId,
      'assessment_date': assessmentDate.toIso8601String(),
      'bed_type': bedType,
      'bed_rails_type': bedRailsType,
      'rail_condition': railCondition,
      'manufacturer_instructions_available': manufacturerInstructionsAvailable,
      'rail_height_and_fit': railHeightAndFit,
      'entrapment_risk_assessed': entrapmentRiskAssessed,
      'patient_mobility': patientMobility,
      'cognitive_impairment': cognitiveImpairment,
      'agitation_restlessness': agitationRestlessness,
      'risk_of_falling_out_of_bed': riskOfFallingOutOfBed,
      'risk_of_entrapment': riskOfEntrapment,
      'alternative_measures_considered': alternativeMeasuresConsidered,
      'family_consent_obtained': familyConsentObtained,
      'staff_trained_in_bed_rail_use': staffTrainedInBedRailUse,
      'rail_regularly_checked': railRegularlyChecked,
      'last_check_date': lastCheckDate?.toIso8601String(),
      'next_check_date': nextCheckDate?.toIso8601String(),
      'action_plan': actionPlan,
      'review_date': reviewDate?.toIso8601String(),
      'assessor_name': assessorName,
      'assessor_signature': assessorSignature,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Bed type display text
  String get bedTypeText {
    switch (bedType) {
      case 'standard': return 'Standard Bed';
      case 'profiling': return 'Profiling Bed';
      case 'hospital': return 'Hospital Bed';
      case 'other': return 'Other';
      default: return bedType;
    }
  }

  // Bed rails type display text
  String get bedRailsTypeText {
    switch (bedRailsType) {
      case 'full': return 'Full Bed Rails';
      case 'half': return 'Half Bed Rails';
      case 'mobile': return 'Mobile Bed Rails';
      case 'other': return 'Other';
      default: return bedRailsType;
    }
  }

  // Rail condition display text
  String get railConditionText {
    switch (railCondition) {
      case 'good': return 'Good Condition';
      case 'worn': return 'Worn Condition';
      case 'damaged': return 'Damaged Condition';
      default: return railCondition;
    }
  }

  // Rail height and fit display text
  String get railHeightAndFitText {
    switch (railHeightAndFit) {
      case 'correct': return 'Correct Height and Fit';
      case 'incorrect': return 'Incorrect Height and Fit';
      default: return railHeightAndFit;
    }
  }

  // Patient mobility display text
  String get patientMobilityText {
    switch (patientMobility) {
      case 'independent': return 'Independent';
      case 'assisted': return 'Requires Assistance';
      case 'bedbound': return 'Bedbound';
      default: return patientMobility;
    }
  }

  // Risk level display text and colors
  String get riskOfFallingText {
    switch (riskOfFallingOutOfBed) {
      case 'high': return 'High Risk';
      case 'medium': return 'Medium Risk';
      case 'low': return 'Low Risk';
      default: return riskOfFallingOutOfBed;
    }
  }

  String get riskOfEntrapmentText {
    switch (riskOfEntrapment) {
      case 'high': return 'High Risk';
      case 'medium': return 'Medium Risk';
      case 'low': return 'Low Risk';
      default: return riskOfEntrapment;
    }
  }

  // Risk level colors
  String get riskOfFallingColor {
    switch (riskOfFallingOutOfBed) {
      case 'high': return '🔴';
      case 'medium': return '🟡';
      case 'low': return '🟢';
      default: return '⚪';
    }
  }

  String get riskOfEntrapmentColor {
    switch (riskOfEntrapment) {
      case 'high': return '🔴';
      case 'medium': return '🟡';
      case 'low': return '🟢';
      default: return '⚪';
    }
  }

  // LOLER compliance status
  bool get isLOLERCompliant {
    return manufacturerInstructionsAvailable &&
           railCondition == 'good' &&
           railHeightAndFit == 'correct' &&
           entrapmentRiskAssessed &&
           staffTrainedInBedRailUse &&
           railRegularlyChecked;
  }

  String get lolComplianceStatus {
    return isLOLERCompliant ? 'LOLER Compliant' : 'LOLER Non-Compliant';
  }

  // High-risk indicators
  bool get isHighRisk {
    return riskOfFallingOutOfBed == 'high' || riskOfEntrapment == 'high';
  }

  // Check status
  bool get isDueForCheck {
    return nextCheckDate != null && nextCheckDate!.isBefore(DateTime.now());
  }

  String get checkStatus {
    if (nextCheckDate == null) return 'No check scheduled';
    if (isDueForCheck) return '⚠️ Due for check';
    return '✓ Next check due ${DateFormat('dd/MM/yyyy').format(nextCheckDate!)}';
  }

  // Alternative measures status
  String get alternativeMeasuresStatus {
    return alternativeMeasuresConsidered ? 'Considered' : 'Not considered';
  }

  // Family consent status
  String get familyConsentStatus {
    return familyConsentObtained ? 'Obtained' : 'Not obtained';
  }

  // Staff training status
  String get staffTrainingStatus {
    return staffTrainedInBedRailUse ? 'Trained' : 'Not trained';
  }

  // Rail condition status
  String get railConditionStatus {
    return railRegularlyChecked ? 'Regularly checked' : 'Not regularly checked';
  }

  // Assessment summary
  String get assessmentSummary {
    return '$bedTypeText with $bedRailsTypeText - $riskOfFallingText falling risk, $riskOfEntrapmentText entrapment risk';
  }

  // Last check display
  String get lastCheckText {
    if (lastCheckDate == null) return 'Never checked';
    return DateFormat('dd/MM/yyyy').format(lastCheckDate!);
  }

  // Next check display
  String get nextCheckText {
    if (nextCheckDate == null) return 'No check scheduled';
    return DateFormat('dd/MM/yyyy').format(nextCheckDate!);
  }

  // Review status
  String get reviewStatus {
    if (reviewDate == null) return 'No review scheduled';
    if (reviewDate!.isBefore(DateTime.now())) {
      return '⚠️ Review overdue';
    }
    return 'Next review due ${DateFormat('dd/MM/yyyy').format(reviewDate!)}';
  }

  // Risk factors summary
  String get riskFactorsSummary {
    List<String> factors = [];
    
    if (cognitiveImpairment) factors.add('Cognitive impairment');
    if (agitationRestlessness) factors.add('Agitation/restlessness');
    if (patientMobility == 'independent') factors.add('Independent mobility');
    if (railCondition != 'good') factors.add('Poor rail condition');
    if (railHeightAndFit != 'correct') factors.add('Incorrect fit');
    
    return factors.isEmpty ? 'No specific risk factors' : factors.join(', ');
  }

  // Safety measures summary
  String get safetyMeasuresSummary {
    List<String> measures = [];
    
    if (manufacturerInstructionsAvailable) measures.add('Manufacturer instructions available');
    if (entrapmentRiskAssessed) measures.add('Entrapment risk assessed');
    if (staffTrainedInBedRailUse) measures.add('Staff trained');
    if (railRegularlyChecked) measures.add('Regularly checked');
    if (alternativeMeasuresConsidered) measures.add('Alternative measures considered');
    if (familyConsentObtained) measures.add('Family consent obtained');
    
    return measures.isEmpty ? 'No safety measures implemented' : measures.join(', ');
  }

  // Action plan status
  String get actionPlanStatus {
    return actionPlan != null && actionPlan!.isNotEmpty 
        ? 'Action plan defined' 
        : 'No action plan';
  }

  // Assessment age in days
  int get assessmentAgeDays {
    return DateTime.now().difference(assessmentDate).inDays;
  }

  // Check frequency recommendation (based on risk level)
  String get recommendedCheckFrequency {
    if (riskOfFallingOutOfBed == 'high' || riskOfEntrapment == 'high') {
      return 'Weekly checks recommended';
    } else if (riskOfFallingOutOfBed == 'medium' || riskOfEntrapment == 'medium') {
      return 'Monthly checks recommended';
    } else {
      return 'Quarterly checks recommended';
    }
  }

  @override
  String toString() {
    return 'BedRailingAssessment(id: $id, serviceUserId: $serviceUserId, assessmentDate: $assessmentDate, bedType: $bedType, bedRailsType: $bedRailsType, railCondition: $railCondition, riskOfFallingOutOfBed: $riskOfFallingOutOfBed, riskOfEntrapment: $riskOfEntrapment)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is BedRailingAssessment &&
           other.id == id &&
           other.serviceUserId == serviceUserId &&
           other.assessmentDate == assessmentDate &&
           other.bedType == bedType &&
           other.bedRailsType == bedRailsType &&
           other.railCondition == railCondition &&
           other.manufacturerInstructionsAvailable == manufacturerInstructionsAvailable &&
           other.railHeightAndFit == railHeightAndFit &&
           other.entrapmentRiskAssessed == entrapmentRiskAssessed &&
           other.patientMobility == patientMobility &&
           other.cognitiveImpairment == cognitiveImpairment &&
           other.agitationRestlessness == agitationRestlessness &&
           other.riskOfFallingOutOfBed == riskOfFallingOutOfBed &&
           other.riskOfEntrapment == riskOfEntrapment &&
           other.alternativeMeasuresConsidered == alternativeMeasuresConsidered &&
           other.familyConsentObtained == familyConsentObtained &&
           other.staffTrainedInBedRailUse == staffTrainedInBedRailUse &&
           other.railRegularlyChecked == railRegularlyChecked &&
           other.lastCheckDate == lastCheckDate &&
           other.nextCheckDate == nextCheckDate &&
           other.actionPlan == actionPlan &&
           other.reviewDate == reviewDate &&
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
           bedType.hashCode ^
           bedRailsType.hashCode ^
           railCondition.hashCode ^
           manufacturerInstructionsAvailable.hashCode ^
           railHeightAndFit.hashCode ^
           entrapmentRiskAssessed.hashCode ^
           patientMobility.hashCode ^
           cognitiveImpairment.hashCode ^
           agitationRestlessness.hashCode ^
           riskOfFallingOutOfBed.hashCode ^
           riskOfEntrapment.hashCode ^
           alternativeMeasuresConsidered.hashCode ^
           familyConsentObtained.hashCode ^
           staffTrainedInBedRailUse.hashCode ^
           railRegularlyChecked.hashCode ^
           lastCheckDate.hashCode ^
           nextCheckDate.hashCode ^
           actionPlan.hashCode ^
           reviewDate.hashCode ^
           assessorName.hashCode ^
           assessorSignature.hashCode ^
           createdAt.hashCode ^
           updatedAt.hashCode;
  }
}