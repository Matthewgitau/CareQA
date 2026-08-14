import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class ChokingRiskFactor {
  final int id;
  final String factorText;
  final String? category;
  final int displayOrder;
  final bool isActive;

  ChokingRiskFactor({
    required this.id,
    required this.factorText,
    this.category,
    required this.displayOrder,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'factor_text': factorText,
      'category': category,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }

  factory ChokingRiskFactor.fromMap(Map<String, dynamic> map) {
    return ChokingRiskFactor(
      id: map['id'] as int,
      factorText: map['factor_text'] as String,
      category: map['category'],
      displayOrder: map['display_order'] as int,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}

class ChokingRiskScore {
  final String id;
  final String assessmentId;
  final int riskFactorId;
  final int score;
  final String? notes;

  ChokingRiskScore({
    required this.id,
    required this.assessmentId,
    required this.riskFactorId,
    required this.score,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assessment_id': assessmentId,
      'risk_factor_id': riskFactorId,
      'score': score,
      'notes': notes,
    };
  }

  factory ChokingRiskScore.fromMap(Map<String, dynamic> map) {
    return ChokingRiskScore(
      id: map['id'] ?? '',
      assessmentId: map['assessment_id'] ?? '',
      riskFactorId: map['risk_factor_id'] as int,
      score: map['score'] as int,
      notes: map['notes'],
    );
  }
}

/// All 36 choking risk factor keys organized by category
class ChokingRiskFactorKeys {
  // Physical Conditions (6)
  static const String weakCough = 'weak_cough';
  static const String chestInfections = 'chest_infections';
  static const String breathingDifficulties = 'breathing_difficulties';
  static const String knownToAspirate = 'known_to_aspirate';
  static const String historyOfChoking = 'history_of_choking';
  static const String gurglyWetVoice = 'gurgly_wet_voice';

  // Neurological Conditions (6)
  static const String epilepsy = 'epilepsy';
  static const String cerebralPalsy = 'cerebral_palsy';
  static const String dementiaConfusion = 'dementia_confusion';
  static const String mentalHealthHistory = 'mental_health_history';
  static const String neurologicalConditions = 'neurological_conditions';
  static const String learningDisabilities = 'learning_disabilities';

  // Physical Limitations (6)
  static const String posturalProblems = 'postural_problems';
  static const String poorHeadControl = 'poor_head_control';
  static const String tongueThrust = 'tongue_thrust';
  static const String chewingDifficulties = 'chewing_difficulties';
  static const String slurredSpeech = 'slurred_speech';
  static const String neckThroatInjury = 'neck_throat_injury';

  // Behavioral Factors (8)
  static const String eatsRapidly = 'eats_rapidly';
  static const String drinksRapidly = 'drinks_rapidly';
  static const String continuesEatingWhileCoughing = 'continues_eating_while_coughing';
  static const String continuesDrinkingWhileCoughing = 'continues_drinking_while_coughing';
  static const String crammingFood = 'cramming_food';
  static const String pocketingFood = 'pocketing_food';
  static const String swallowingWithoutChewing = 'swallowing_without_chewing';
  static const String takesFoodFromOthers = 'takes_food_from_others';

  // Eating/Drinking Independence (2)
  static const String drinksIndependently = 'drinks_independently';
  static const String eatsIndependently = 'eats_independently';

  // Dental/Oral Health (1)
  static const String dentalIssues = 'dental_issues';

  // Physical/Mental State (6 - includes non-food items)
  static const String fatigueAtMeals = 'fatigue_at_meals';
  static const String needsFoodPrepared = 'needs_food_prepared';
  static const String modifiedConsistencyDiet = 'modified_consistency_diet';
  static const String requiresThickenedFluids = 'requires_thickened_fluids';
  static const String requiresSpecialistAids = 'requires_specialist_aids';
  static const String putsNonFoodItemsInMouth = 'puts_non_food_items_in_mouth';

  // Medication (1)
  static const String medicationAffectsSwallowing = 'medication_affects_swallowing';

  /// All 36 keys in order
  static List<String> get allKeys => [
    weakCough, chestInfections, breathingDifficulties, knownToAspirate, historyOfChoking, gurglyWetVoice,
    epilepsy, cerebralPalsy, dementiaConfusion, mentalHealthHistory, neurologicalConditions, learningDisabilities,
    posturalProblems, poorHeadControl, tongueThrust, chewingDifficulties, slurredSpeech, neckThroatInjury,
    eatsRapidly, drinksRapidly, continuesEatingWhileCoughing, continuesDrinkingWhileCoughing, crammingFood, pocketingFood, swallowingWithoutChewing, takesFoodFromOthers,
    drinksIndependently, eatsIndependently,
    dentalIssues,
    fatigueAtMeals, needsFoodPrepared, modifiedConsistencyDiet, requiresThickenedFluids, requiresSpecialistAids, putsNonFoodItemsInMouth,
    medicationAffectsSwallowing,
  ];
}

class ChokingRiskAssessment {
  final String id;
  final String serviceUserId;
  final String serviceUserName;
  final String assessorName;
  final DateTime assessmentDate;
  final TimeOfDay assessmentTime;
  final String? sfarrSignature;
  final String status;
  final DateTime createdAt;
  final String? createdBy;
  final DateTime updatedAt;
  
  // Extended fields from migration 057
  final int? totalScoreField;
  final String? riskCategory;
  final DateTime? reviewDate;
  final bool? sltReviewRequired;
  final bool? dietModificationRequired;
  final bool? fluidModificationRequired;
  final bool? feedingAidRequired;
  final String? supervisionLevel;
  final Map<String, dynamic>? extendedQuestions;

  // New: 36 risk factors stored as JSONB
  final Map<String, int> riskFactors;
  final int? totalScore; // Computed from DB or local
  final String? riskLevel; // Computed from DB or local

  // Calculated properties
  int get computedTotalScore {
    if (totalScore != null) return totalScore!;
    if (totalScoreField != null && totalScoreField! > 0) return totalScoreField!;
    if (riskFactors.isNotEmpty) {
      return riskFactors.values.fold(0, (sum, score) => sum + score);
    }
    return scores.values.fold(0, (sum, score) => sum + score);
  }

  String get computedRiskLevel {
    final score = computedTotalScore;
    if (score <= 24) return 'Low';
    if (score <= 49) return 'Medium';
    return 'High';
  }

  String get riskLevelDisplay {
    final level = riskLevel ?? computedRiskLevel;
    switch (level) {
      case 'Low':
        return 'Low Risk: 0-24';
      case 'Medium':
        return 'Medium Risk: 25-49';
      case 'High':
        return 'High Risk: 50+';
      default:
        return 'Unknown';
    }
  }

  Color get riskColor {
    final level = riskLevel ?? computedRiskLevel;
    switch (level) {
      case 'Low':
        return const Color(0xFF4CAF50); // Green
      case 'Medium':
        return const Color(0xFFFF9800); // Orange
      case 'High':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  // Scores and notes (legacy)
  final Map<int, int> scores;
  final Map<int, String> notes;

  ChokingRiskAssessment({
    required this.id,
    required this.serviceUserId,
    required this.serviceUserName,
    required this.assessorName,
    required this.assessmentDate,
    required this.assessmentTime,
    this.sfarrSignature,
    required this.status,
    required this.createdAt,
    this.createdBy,
    required this.updatedAt,
    required this.scores,
    required this.notes,
    this.totalScoreField,
    this.riskCategory,
    this.reviewDate,
    this.sltReviewRequired,
    this.dietModificationRequired,
    this.fluidModificationRequired,
    this.feedingAidRequired,
    this.supervisionLevel,
    this.extendedQuestions,
    this.riskFactors = const {},
    this.totalScore,
    this.riskLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_user_id': serviceUserId,
      'service_user_name': serviceUserName,
      'assessor_name': assessorName,
      'assessment_date': assessmentDate,
      'assessment_time': assessmentTime,
      'sfarr_signature': sfarrSignature,
      'status': status,
      'created_at': createdAt,
      'created_by': createdBy,
      'updated_at': updatedAt,
      'total_score': totalScoreField,
      'risk_category': riskCategory,
      'review_date': reviewDate,
      'slt_review_required': sltReviewRequired,
      'diet_modification_required': dietModificationRequired,
      'fluid_modification_required': fluidModificationRequired,
      'feeding_aid_required': feedingAidRequired,
      'supervision_level': supervisionLevel,
      'extended_questions': extendedQuestions,
      'risk_factors': riskFactors.isNotEmpty ? riskFactors : null,
    };
  }

  factory ChokingRiskAssessment.fromMap(Map<String, dynamic> map) {
    // Parse risk_factors JSONB
    Map<String, int> parsedRiskFactors = {};
    if (map['risk_factors'] != null) {
      final rf = map['risk_factors'];
      if (rf is Map) {
        parsedRiskFactors = rf.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      }
    }

    return ChokingRiskAssessment(
      id: map['id'] ?? '',
      serviceUserId: map['service_user_id'] ?? '',
      serviceUserName: map['service_user_name'] ?? '',
      assessorName: map['assessor_name'] ?? '',
      assessmentDate: (map['assessment_date'] as DateTime?) ?? DateTime.now(),
      assessmentTime: TimeOfDay(
        hour: int.parse((map['assessment_time'] as String?)?.split(':').first ?? '0'),
        minute: int.parse((map['assessment_time'] as String?)?.split(':').last ?? '0'),
      ),
      sfarrSignature: map['sfarr_signature'],
      status: map['status'] ?? 'draft',
      createdAt: (map['created_at'] as DateTime?) ?? DateTime.now(),
      createdBy: map['created_by'],
      updatedAt: (map['updated_at'] as DateTime?) ?? DateTime.now(),
      scores: {},
      notes: {},
      totalScoreField: map['total_score'] as int?,
      riskCategory: map['risk_category'] as String?,
      reviewDate: map['review_date'] as DateTime?,
      sltReviewRequired: map['slt_review_required'] as bool?,
      dietModificationRequired: map['diet_modification_required'] as bool?,
      fluidModificationRequired: map['fluid_modification_required'] as bool?,
      feedingAidRequired: map['feeding_aid_required'] as bool?,
      supervisionLevel: map['supervision_level'] as String?,
      extendedQuestions: map['extended_questions'] as Map<String, dynamic>?,
      riskFactors: parsedRiskFactors,
      totalScore: (map['total_score'] as num?)?.toInt(),
      riskLevel: map['risk_level'] as String?,
    );
  }

  // Factory for creating from assessment with scores
  factory ChokingRiskAssessment.fromAssessmentWithScores(Map<String, dynamic> assessmentData, List<Map<String, dynamic>> scoresData) {
    final assessment = ChokingRiskAssessment.fromMap(assessmentData);
    
    // Convert scores data to maps
    final scores = <int, int>{};
    final notes = <int, String>{};
    
    for (final scoreData in scoresData) {
      final riskFactorId = scoreData['risk_factor_id'] as int;
      final score = scoreData['score'] as int;
      final note = scoreData['notes'] as String? ?? '';
      
      scores[riskFactorId] = score;
      notes[riskFactorId] = note;
    }
    
    return ChokingRiskAssessment(
      id: assessment.id,
      serviceUserId: assessment.serviceUserId,
      serviceUserName: assessment.serviceUserName,
      assessorName: assessment.assessorName,
      assessmentDate: assessment.assessmentDate,
      assessmentTime: assessment.assessmentTime,
      sfarrSignature: assessment.sfarrSignature,
      status: assessment.status,
      createdAt: assessment.createdAt,
      createdBy: assessment.createdBy,
      updatedAt: assessment.updatedAt,
      scores: scores,
      notes: notes,
      totalScoreField: assessment.totalScoreField,
      riskCategory: assessment.riskCategory,
      reviewDate: assessment.reviewDate,
      sltReviewRequired: assessment.sltReviewRequired,
      dietModificationRequired: assessment.dietModificationRequired,
      fluidModificationRequired: assessment.fluidModificationRequired,
      feedingAidRequired: assessment.feedingAidRequired,
      supervisionLevel: assessment.supervisionLevel,
      extendedQuestions: assessment.extendedQuestions,
      riskFactors: assessment.riskFactors,
      totalScore: assessment.totalScore,
      riskLevel: assessment.riskLevel,
    );
  }
}

class ChokingRiskSummary {
  final int totalScore;
  final String riskLevel;
  final Color riskColor;
  final DateTime assessmentDate;
  final String assessorName;
  final String serviceUserName;
  final String status;

  ChokingRiskSummary({
    required this.totalScore,
    required this.riskLevel,
    required this.riskColor,
    required this.assessmentDate,
    required this.assessorName,
    required this.serviceUserName,
    required this.status,
  });

  factory ChokingRiskSummary.fromMap(Map<String, dynamic> map) {
    final score = map['total_score'] is int ? map['total_score'] as int : int.tryParse(map['total_score']?.toString() ?? '0') ?? 0;
    final level = map['risk_level'] as String? ?? 'Low';
    Color color;
    switch (level) {
      case 'Low':
        color = const Color(0xFF4CAF50);
        break;
      case 'Medium':
        color = const Color(0xFFFF9800);
        break;
      case 'High':
        color = const Color(0xFFF44336);
        break;
      default:
        color = const Color(0xFF9E9E9E);
    }
    return ChokingRiskSummary(
      totalScore: score,
      riskLevel: level,
      riskColor: color,
      assessmentDate: (map['assessment_date'] as DateTime?) ?? DateTime.now(),
      assessorName: map['assessor_name'] as String,
      serviceUserName: map['service_user_name'] as String,
      status: map['status'] as String,
    );
  }
}

class ChokingRiskValidation {
  final bool isComplete;
  final int missingScores;
  final int totalPossibleScores;
  final List<String> warnings;

  ChokingRiskValidation({
    required this.isComplete,
    required this.missingScores,
    required this.totalPossibleScores,
    required this.warnings,
  });

  factory ChokingRiskValidation.fromMap(Map<String, dynamic> map) {
    return ChokingRiskValidation(
      isComplete: map['is_complete'] as bool,
      missingScores: map['missing_scores'] as int,
      totalPossibleScores: map['total_possible_scores'] as int,
      warnings: List<String>.from(map['warnings'] ?? []),
    );
  }
}

class ChokingRiskHistoryItem {
  final String assessmentId;
  final String serviceUserName;
  final DateTime assessmentDate;
  final TimeOfDay assessmentTime;
  final String assessorName;
  final int totalScore;
  final String riskLevel;
  final String status;
  final DateTime createdAt;

  ChokingRiskHistoryItem({
    required this.assessmentId,
    required this.serviceUserName,
    required this.assessmentDate,
    required this.assessmentTime,
    required this.assessorName,
    required this.totalScore,
    required this.riskLevel,
    required this.status,
    required this.createdAt,
  });

  factory ChokingRiskHistoryItem.fromMap(Map<String, dynamic> map) {
    return ChokingRiskHistoryItem(
      assessmentId: map['assessment_id'] ?? map['id'] ?? '',
      serviceUserName: map['service_user_name'] ?? '',
      assessmentDate: (map['assessment_date'] as DateTime?) ?? DateTime.now(),
      assessmentTime: TimeOfDay(
        hour: int.parse((map['assessment_time'] as String?)?.split(':').first ?? '0'),
        minute: int.parse((map['assessment_time'] as String?)?.split(':').last ?? '0'),
      ),
      assessorName: map['assessor_name'] as String? ?? '',
      totalScore: (map['total_score'] as num?)?.toInt() ?? 0,
      riskLevel: map['risk_level'] as String? ?? 'Low',
      status: map['status'] as String? ?? 'draft',
      createdAt: (map['created_at'] as DateTime?) ?? DateTime.now(),
    );
  }
}