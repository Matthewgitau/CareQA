import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class FallsRiskAssessment {
  final String id;
  final String serviceUserId;
  final String serviceUserName;
  final String assessorName;
  final DateTime dateOfBirth;
  final DateTime assessmentDate;
  
  // Scoring Categories
  final int? ageScore;
  final int? fallHistoryScore;
  final int? eliminationScore;
  final int? medicationScore;
  final int? equipmentScore;
  final int? mobilityScore;
  final int? cognitionScore;
  
  // Mobility Test & Grip Strength
  final bool? mobilityTestCompleted;
  final DateTime? mobilityTestDate;
  final bool? mobilityChanged;
  final double? gripStrengthKg;
  final String? gripStrengthRisk;
  final bool? mobilityRiskTriggered;
  
  // Calculated grip strength score
  int get gripStrengthScore {
    if (gripStrengthKg == null) return 0;
    if (gripStrengthKg! < 16) return 3;
    if (gripStrengthKg! < 20) return 2;
    return 0;
  }
  
  // Calculated properties
  int get totalScore {
    return (ageScore ?? 0) + 
           (fallHistoryScore ?? 0) + 
           (eliminationScore ?? 0) + 
           (medicationScore ?? 0) + 
           (equipmentScore ?? 0) + 
           (mobilityScore ?? 0) + 
           (cognitionScore ?? 0) +
           gripStrengthScore;
  }

  String get riskLevel {
    final score = totalScore;
    if (score >= 6 && score <= 8) return 'Low';
    if (score >= 9 && score <= 12) return 'Moderate';
    if (score >= 13) return 'High';
    return 'Not Calculated';
  }

  String get riskLevelDescription {
    switch (riskLevel) {
      case 'Low':
        return 'Low Risk: 6-8 points';
      case 'Moderate':
        return 'Moderate Risk: 9-12 points';
      case 'High':
        return 'High Risk: 13+ points';
      default:
        return 'Not Calculated';
    }
  }

  String get riskColor {
    switch (riskLevel) {
      case 'Low':
        return '#4caf50'; // Green
      case 'Moderate':
        return '#ff9800'; // Orange
      case 'High':
        return '#f44336'; // Red
      default:
        return '#9e9e9e'; // Grey
    }
  }

  // Verification
  final String? verifiedBy;
  final String? signatureData;
  final DateTime? verificationDate;
  
  // Status
  final String status;
  final DateTime createdAt;
  final String? createdBy;
  final DateTime updatedAt;

  // Action Plans
  final List<FallsActionPlan> actionPlans;

  FallsRiskAssessment({
    required this.id,
    required this.serviceUserId,
    required this.serviceUserName,
    required this.assessorName,
    required this.dateOfBirth,
    required this.assessmentDate,
    this.ageScore,
    this.fallHistoryScore,
    this.eliminationScore,
    this.medicationScore,
    this.equipmentScore,
    this.mobilityScore,
    this.cognitionScore,
    this.mobilityTestCompleted,
    this.mobilityTestDate,
    this.mobilityChanged,
    this.gripStrengthKg,
    this.gripStrengthRisk,
    this.mobilityRiskTriggered,
    this.verifiedBy,
    this.signatureData,
    this.verificationDate,
    required this.status,
    required this.createdAt,
    this.createdBy,
    required this.updatedAt,
    required this.actionPlans,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_user_id': serviceUserId,
      'service_user_name': serviceUserName,
      'assessor_name': assessorName,
      'date_of_birth': dateOfBirth,
      'assessment_date': assessmentDate,
      'age_score': ageScore,
      'fall_history_score': fallHistoryScore,
      'elimination_score': eliminationScore,
      'medication_score': medicationScore,
      'equipment_score': equipmentScore,
      'mobility_score': mobilityScore,
      'cognition_score': cognitionScore,
      'mobility_test_completed': mobilityTestCompleted,
      'mobility_test_date': mobilityTestDate,
      'mobility_changed': mobilityChanged,
      'grip_strength_kg': gripStrengthKg,
      'grip_strength_risk': gripStrengthRisk,
      'mobility_risk_triggered': mobilityRiskTriggered,
      'verified_by': verifiedBy,
      'signature_data': signatureData,
      'verification_date': verificationDate,
      'status': status,
      'created_at': createdAt,
      'created_by': createdBy,
      'updated_at': updatedAt,
    };
  }

  factory FallsRiskAssessment.fromMap(Map<String, dynamic> map) {
    return FallsRiskAssessment(
      id: map['id'] ?? '',
      serviceUserId: map['service_user_id'] ?? '',
      serviceUserName: map['service_user_name'] ?? '',
      assessorName: map['assessor_name'] ?? '',
      dateOfBirth: (map['date_of_birth'] as DateTime?) ?? DateTime.now(),
      assessmentDate: (map['assessment_date'] as DateTime?) ?? DateTime.now(),
      ageScore: map['age_score'],
      fallHistoryScore: map['fall_history_score'],
      eliminationScore: map['elimination_score'],
      medicationScore: map['medication_score'],
      equipmentScore: map['equipment_score'],
      mobilityScore: map['mobility_score'],
      cognitionScore: map['cognition_score'],
      mobilityTestCompleted: map['mobility_test_completed'] as bool?,
      mobilityTestDate: map['mobility_test_date'] as DateTime?,
      mobilityChanged: map['mobility_changed'] as bool?,
      gripStrengthKg: (map['grip_strength_kg'] as num?)?.toDouble(),
      gripStrengthRisk: map['grip_strength_risk'] as String?,
      mobilityRiskTriggered: map['mobility_risk_triggered'] as bool?,
      verifiedBy: map['verified_by'],
      signatureData: map['signature_data'],
      verificationDate: map['verification_date'] as DateTime?,
      status: map['status'] ?? 'draft',
      createdAt: (map['created_at'] as DateTime?) ?? DateTime.now(),
      createdBy: map['created_by'],
      updatedAt: (map['updated_at'] as DateTime?) ?? DateTime.now(),
      actionPlans: [],
    );
  }

  // Factory for creating from assessment with action plans
  factory FallsRiskAssessment.fromAssessmentWithActionPlans(Map<String, dynamic> assessmentData, List<Map<String, dynamic>> actionPlansData) {
    final assessment = FallsRiskAssessment.fromMap(assessmentData);
    
    // Convert action plans data to list
    final actionPlans = actionPlansData.map((ap) => FallsActionPlan.fromMap(ap)).toList();
    
    return FallsRiskAssessment(
      id: assessment.id,
      serviceUserId: assessment.serviceUserId,
      serviceUserName: assessment.serviceUserName,
      assessorName: assessment.assessorName,
      dateOfBirth: assessment.dateOfBirth,
      assessmentDate: assessment.assessmentDate,
      ageScore: assessment.ageScore,
      fallHistoryScore: assessment.fallHistoryScore,
      eliminationScore: assessment.eliminationScore,
      medicationScore: assessment.medicationScore,
      equipmentScore: assessment.equipmentScore,
      mobilityScore: assessment.mobilityScore,
      cognitionScore: assessment.cognitionScore,
      mobilityTestCompleted: assessment.mobilityTestCompleted,
      mobilityTestDate: assessment.mobilityTestDate,
      mobilityChanged: assessment.mobilityChanged,
      gripStrengthKg: assessment.gripStrengthKg,
      gripStrengthRisk: assessment.gripStrengthRisk,
      mobilityRiskTriggered: assessment.mobilityRiskTriggered,
      verifiedBy: assessment.verifiedBy,
      signatureData: assessment.signatureData,
      verificationDate: assessment.verificationDate,
      status: assessment.status,
      createdAt: assessment.createdAt,
      createdBy: assessment.createdBy,
      updatedAt: assessment.updatedAt,
      actionPlans: actionPlans,
    );
  }
}

class FallsActionPlan {
  final String id;
  final String action;
  final String? outcome;
  final bool completed;
  final DateTime? completedAt;
  final DateTime createdAt;

  FallsActionPlan({
    required this.id,
    required this.action,
    this.outcome,
    this.completed = false,
    this.completedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'outcome': outcome,
      'completed': completed,
      'completed_at': completedAt,
      'created_at': createdAt,
    };
  }

  factory FallsActionPlan.fromMap(Map<String, dynamic> map) {
    return FallsActionPlan(
      id: map['id'] ?? '',
      action: map['action'] ?? '',
      outcome: map['outcome'],
      completed: map['completed'] as bool? ?? false,
      completedAt: map['completed_at'] as DateTime?,
      createdAt: (map['created_at'] as DateTime?) ?? DateTime.now(),
    );
  }
}

class FallsRiskSummary {
  final int totalScore;
  final String riskLevel;
  final String riskColor;
  final DateTime assessmentDate;
  final String assessorName;
  final String serviceUserName;
  final String status;
  final int ageScore;
  final int fallHistoryScore;
  final int eliminationScore;
  final int medicationScore;
  final int equipmentScore;
  final int mobilityScore;
  final int cognitionScore;

  FallsRiskSummary({
    required this.totalScore,
    required this.riskLevel,
    required this.riskColor,
    required this.assessmentDate,
    required this.assessorName,
    required this.serviceUserName,
    required this.status,
    required this.ageScore,
    required this.fallHistoryScore,
    required this.eliminationScore,
    required this.medicationScore,
    required this.equipmentScore,
    required this.mobilityScore,
    required this.cognitionScore,
  });

  factory FallsRiskSummary.fromMap(Map<String, dynamic> map) {
    return FallsRiskSummary(
      totalScore: map['total_score'] as int,
      riskLevel: map['risk_level'] as String,
      riskColor: map['risk_color'] as String,
      assessmentDate: (map['assessment_date'] as DateTime?) ?? DateTime.now(),
      assessorName: map['assessor_name'] as String,
      serviceUserName: map['service_user_name'] as String,
      status: map['status'] as String,
      ageScore: map['age_score'] as int,
      fallHistoryScore: map['fall_history_score'] as int,
      eliminationScore: map['elimination_score'] as int,
      medicationScore: map['medication_score'] as int,
      equipmentScore: map['equipment_score'] as int,
      mobilityScore: map['mobility_score'] as int,
      cognitionScore: map['cognition_score'] as int,
    );
  }
}

class FallsRiskValidation {
  final bool isComplete;
  final List<String> missingScores;
  final List<String> warnings;

  FallsRiskValidation({
    required this.isComplete,
    required this.missingScores,
    required this.warnings,
  });

  factory FallsRiskValidation.fromMap(Map<String, dynamic> map) {
    return FallsRiskValidation(
      isComplete: map['is_complete'] as bool,
      missingScores: List<String>.from(map['missing_scores'] ?? []),
      warnings: List<String>.from(map['warnings'] ?? []),
    );
  }
}

class FallsRiskHistoryItem {
  final String assessmentId;
  final String serviceUserName;
  final DateTime assessmentDate;
  final String assessorName;
  final int totalScore;
  final String riskLevel;
  final String status;
  final DateTime createdAt;

  FallsRiskHistoryItem({
    required this.assessmentId,
    required this.serviceUserName,
    required this.assessmentDate,
    required this.assessorName,
    required this.totalScore,
    required this.riskLevel,
    required this.status,
    required this.createdAt,
  });

  factory FallsRiskHistoryItem.fromMap(Map<String, dynamic> map) {
    return FallsRiskHistoryItem(
      assessmentId: map['assessment_id'] ?? '',
      serviceUserName: map['service_user_name'] ?? '',
      assessmentDate: (map['assessment_date'] as DateTime?) ?? DateTime.now(),
      assessorName: map['assessor_name'] as String,
      totalScore: map['total_score'] as int,
      riskLevel: map['risk_level'] as String,
      status: map['status'] as String,
      createdAt: (map['created_at'] as DateTime?) ?? DateTime.now(),
    );
  }
}

// Helper classes for scoring options
class AgeScoreOption {
  final String label;
  final int score;
  final String description;

  AgeScoreOption(this.label, this.score, this.description);

  @override
  String toString() => '$label ($score points)';
}

class FallHistoryScoreOption {
  final String label;
  final int score;
  final String description;

  FallHistoryScoreOption(this.label, this.score, this.description);

  @override
  String toString() => '$label ($score points)';
}

class EliminationScoreOption {
  final String label;
  final int score;
  final String description;

  EliminationScoreOption(this.label, this.score, this.description);

  @override
  String toString() => '$label ($score points)';
}

class MedicationScoreOption {
  final String label;
  final int score;
  final String description;

  MedicationScoreOption(this.label, this.score, this.description);

  @override
  String toString() => '$label ($score points)';
}

class EquipmentScoreOption {
  final String label;
  final int score;
  final String description;

  EquipmentScoreOption(this.label, this.score, this.description);

  @override
  String toString() => '$label ($score points)';
}

class MobilityScoreOption {
  final String label;
  final int score;
  final String description;

  MobilityScoreOption(this.label, this.score, this.description);

  @override
  String toString() => '$label ($score points)';
}

class CognitionScoreOption {
  final String label;
  final int score;
  final String description;

  CognitionScoreOption(this.label, this.score, this.description);

  @override
  String toString() => '$label ($score points)';
}