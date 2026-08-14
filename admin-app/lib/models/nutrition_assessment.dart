import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';

class NutritionAssessment {
  final String? id;
  final String? serviceUserId;
  final String? serviceUserName;
  final String? assessorId;
  final DateTime assessmentDate;
  final double heightCm;
  final double currentWeightKg;
  final double? weight3_6MonthsAgoKg;
  final double? bmi;
  final int bmiScore;
  final double? weightLossPercentage;
  final int weightLossScore;
  final int acuteDiseaseEffectScore;
  final int mustTotalScore;
  final String riskCategory;
  final String? appetite;
  final List<String>? eatingDifficulties;
  final String? dietaryRequirements;
  final String? foodPreferencesAllergies;
  final bool swallowingDifficulties;
  final bool requiresFoodMonitoring;
  final String? monitoringFrequency;
  final DateTime? nextMonitoringDate;
  final bool referredToDietitian;
  final bool gpReferral;
  final bool supplementationRequired;
  final String? supplementsDetails;
  final String? actionPlan;
  final DateTime? reviewDate;
  final DateTime? nextWeightCheckDate;
  final String? reassessmentFrequency;
  final String assessorName;
  final String? assessorSignature;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  NutritionAssessment({
    this.id,
    this.serviceUserId,
    this.serviceUserName,
    this.assessorId,
    required this.assessmentDate,
    required this.heightCm,
    required this.currentWeightKg,
    this.weight3_6MonthsAgoKg,
    this.bmi,
    required this.bmiScore,
    this.weightLossPercentage,
    required this.weightLossScore,
    required this.acuteDiseaseEffectScore,
    required this.mustTotalScore,
    required this.riskCategory,
    this.appetite,
    this.eatingDifficulties,
    this.dietaryRequirements,
    this.foodPreferencesAllergies,
    required this.swallowingDifficulties,
    this.requiresFoodMonitoring = false,
    this.monitoringFrequency,
    this.nextMonitoringDate,
    required this.referredToDietitian,
    this.gpReferral = false,
    required this.supplementationRequired,
    this.supplementsDetails,
    this.actionPlan,
    this.reviewDate,
    this.nextWeightCheckDate,
    this.reassessmentFrequency,
    required this.assessorName,
    this.assessorSignature,
    this.status = 'draft',
    required this.createdAt,
    required this.updatedAt,
  });

  factory NutritionAssessment.fromMap(Map<String, dynamic> map) {
    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value.toLocal();
      return DateTime.parse(value).toLocal();
    }

    return NutritionAssessment(
      id: map['id'],
      serviceUserId: map['service_user_id'],
      serviceUserName: map['service_user_name'],
      assessorId: map['assessor_id'],
      assessmentDate: _parseDate(map['assessment_date']),
      heightCm: (map['height_cm'] as num?)?.toDouble() ?? 0.0,
      currentWeightKg: (map['current_weight_kg'] as num?)?.toDouble() ?? 0.0,
      weight3_6MonthsAgoKg: map['weight_3_6_months_ago_kg'] != null 
          ? (map['weight_3_6_months_ago_kg'] as num).toDouble() 
          : null,
      bmi: map['bmi'] != null ? (map['bmi'] as num).toDouble() : null,
      bmiScore: map['bmi_score'] as int? ?? 0,
      weightLossPercentage: map['weight_loss_percentage'] != null 
          ? (map['weight_loss_percentage'] as num).toDouble() 
          : null,
      weightLossScore: map['weight_loss_score'] as int? ?? 0,
      acuteDiseaseEffectScore: map['acute_disease_effect_score'] as int? ?? 0,
      mustTotalScore: map['must_total_score'] as int? ?? 0,
      riskCategory: map['risk_category'] as String? ?? 'low',
      appetite: map['appetite'],
      eatingDifficulties: map['eating_difficulties'] != null 
          ? List<String>.from(map['eating_difficulties']) 
          : null,
      dietaryRequirements: map['dietary_requirements'],
      foodPreferencesAllergies: map['food_preferences_allergies'],
      swallowingDifficulties: map['swallowing_difficulties'] as bool? ?? false,
      requiresFoodMonitoring: map['requires_food_monitoring'] as bool? ?? false,
      monitoringFrequency: map['monitoring_frequency'],
      nextMonitoringDate: map['next_monitoring_date'] != null ? _parseDate(map['next_monitoring_date']) : null,
      referredToDietitian: map['referred_to_dietitian'] as bool? ?? false,
      gpReferral: map['gp_referral'] as bool? ?? false,
      supplementationRequired: map['supplementation_required'] as bool? ?? false,
      supplementsDetails: map['supplements_details'],
      actionPlan: map['action_plan'],
      reviewDate: map['review_date'] != null ? _parseDate(map['review_date']) : null,
      nextWeightCheckDate: map['next_weight_check_date'] != null ? _parseDate(map['next_weight_check_date']) : null,
      reassessmentFrequency: map['reassessment_frequency'],
      assessorName: map['assessor_name'] as String? ?? '',
      assessorSignature: map['assessor_signature'],
      status: map['status'] as String? ?? 'draft',
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'service_user_id': serviceUserId,
      'service_user_name': serviceUserName,
      'assessor_id': assessorId,
      'assessment_date': assessmentDate.toIso8601String().split('T').first,
      'height_cm': heightCm,
      'current_weight_kg': currentWeightKg,
      'weight_3_6_months_ago_kg': weight3_6MonthsAgoKg,
      'bmi': bmi,
      'bmi_score': bmiScore,
      'weight_loss_percentage': weightLossPercentage,
      'weight_loss_score': weightLossScore,
      'acute_disease_effect_score': acuteDiseaseEffectScore,
      'must_total_score': mustTotalScore,
      'risk_category': riskCategory,
      'appetite': appetite,
      'eating_difficulties': eatingDifficulties,
      'dietary_requirements': dietaryRequirements,
      'food_preferences_allergies': foodPreferencesAllergies,
      'swallowing_difficulties': swallowingDifficulties,
      'requires_food_monitoring': requiresFoodMonitoring,
      'monitoring_frequency': monitoringFrequency,
      'next_monitoring_date': nextMonitoringDate?.toIso8601String().split('T').first,
      'referred_to_dietitian': referredToDietitian,
      'gp_referral': gpReferral,
      'supplementation_required': supplementationRequired,
      'supplements_details': supplementsDetails,
      'action_plan': actionPlan,
      'review_date': reviewDate?.toIso8601String().split('T').first,
      'next_weight_check_date': nextWeightCheckDate?.toIso8601String().split('T').first,
      'reassessment_frequency': reassessmentFrequency,
      'assessor_name': assessorName,
      'assessor_signature': assessorSignature,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Calculate BMI
  double calculateBMI() {
    if (heightCm > 0) {
      return currentWeightKg / (heightCm / 100 * heightCm / 100);
    }
    return 0.0;
  }

  // Calculate weight loss percentage
  double? calculateWeightLossPercentage() {
    if (weight3_6MonthsAgoKg != null && weight3_6MonthsAgoKg! > 0) {
      return ((weight3_6MonthsAgoKg! - currentWeightKg) / weight3_6MonthsAgoKg!) * 100;
    }
    return null;
  }

  // Calculate BMI score based on MUST criteria
  int calculateBmiScore() {
    final bmi = calculateBMI();
    if (bmi > 20) return 0;
    if (bmi >= 18.5) return 1;
    return 2;
  }

  // Calculate weight loss score based on MUST criteria
  int calculateWeightLossScore() {
    final weightLoss = calculateWeightLossPercentage();
    if (weightLoss == null) return 0;
    if (weightLoss < 5) return 0;
    if (weightLoss <= 10) return 1;
    return 2;
  }

  // Calculate MUST total score
  int calculateMustTotalScore() {
    return calculateBmiScore() + calculateWeightLossScore() + acuteDiseaseEffectScore;
  }

  // Get risk category from MUST score
  String getRiskCategory() {
    final score = calculateMustTotalScore();
    if (score == 0) return 'low';
    if (score == 1) return 'medium';
    return 'high';
  }

  String get riskLevelText {
    switch (riskCategory) {
      case 'low': return 'Low Risk (Score: 0)';
      case 'medium': return 'Medium Risk (Score: 1)';
      case 'high': return 'High Risk (Score: 2+)';
      default: return 'Unknown';
    }
  }

  String get bmiCategory {
    final bmi = calculateBMI();
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  String get weightLossCategory {
    final weightLoss = calculateWeightLossPercentage();
    if (weightLoss == null) return 'Not specified';
    if (weightLoss < 5) return 'Minimal (< 5%)';
    if (weightLoss <= 10) return 'Moderate (5-10%)';
    return 'Severe (> 10%)';
  }

  bool get isReviewDue {
    if (reviewDate == null) return false;
    return reviewDate!.isBefore(DateTime.now());
  }

  bool get isWeightCheckDue {
    if (nextWeightCheckDate == null) return false;
    return nextWeightCheckDate!.isBefore(DateTime.now());
  }

  @override
  String toString() {
    return 'NutritionAssessment(id: $id, serviceUserId: $serviceUserId, mustTotalScore: $mustTotalScore, riskCategory: $riskCategory)';
  }
}