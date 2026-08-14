import 'package:supabase_flutter/supabase_flutter.dart';

class WaterlowAssessment {
  final String id;
  final String serviceUserId;
  final String assessorId;
  final DateTime assessmentDate;
  final Map<String, dynamic> responses;
  final List<Map<String, dynamic>> actionPlan;
  final String? signature;
  final String status;
  final int totalScore;
  final String riskLevel;

  WaterlowAssessment({
    required this.id,
    required this.serviceUserId,
    required this.assessorId,
    required this.assessmentDate,
    required this.responses,
    required this.actionPlan,
    this.signature,
    required this.status,
    required this.totalScore,
    required this.riskLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_user_id': serviceUserId,
      'assessor_id': assessorId,
      'assessment_date': assessmentDate,
      'responses': responses,
      'action_plan': actionPlan,
      'signature': signature,
      'status': status,
      'total_score': totalScore,
      'risk_level': riskLevel,
      'created_at': DateTime.now(),
      'updated_at': DateTime.now(),
    };
  }

  factory WaterlowAssessment.fromMap(Map<String, dynamic> map) {
    return WaterlowAssessment(
      id: map['id'] ?? '',
      serviceUserId: map['service_user_id'] ?? '',
      assessorId: map['assessor_id'] ?? '',
      assessmentDate: (map['assessment_date'] as DateTime?) ?? DateTime.now(),
      responses: map['responses'] ?? {},
      actionPlan: (map['action_plan'] as List?)?.map((item) => item as Map<String, dynamic>).toList() ?? [],
      signature: map['signature'],
      status: map['status'] ?? 'draft',
      totalScore: map['total_score'] as int? ?? 0,
      riskLevel: map['risk_level'] ?? 'Low',
    );
  }

  int calculateScore() {
    int score = 0;
    responses.forEach((key, value) {
      if (value is int) {
        score += value;
      }
    });
    return score;
  }

  String determineRiskLevel() {
    int score = calculateScore();
    if (score >= 15) return 'High';
    if (score >= 10) return 'Moderate';
    return 'Low';
  }
}

class WaterlowQuestion {
  final int id;
  final String questionText;
  final String category;
  final int displayOrder;
  final Map<String, int> options; // option text -> score value

  WaterlowQuestion({
    required this.id,
    required this.questionText,
    required this.category,
    required this.displayOrder,
    required this.options,
  });

  factory WaterlowQuestion.fromMap(Map<String, dynamic> map) {
    return WaterlowQuestion(
      id: map['id'] as int,
      questionText: map['question_text'] ?? '',
      category: map['category'] ?? '',
      displayOrder: map['display_order'] as int,
      options: Map<String, int>.from(map['options'] ?? {}),
    );
  }
}

class WaterlowSummary {
  final int totalQuestions;
  final int totalScore;
  final String riskLevel;
  final DateTime? lastAssessmentDate;
  final int actionItemsCount;

  WaterlowSummary({
    required this.totalQuestions,
    required this.totalScore,
    required this.riskLevel,
    this.lastAssessmentDate,
    required this.actionItemsCount,
  });

  factory WaterlowSummary.fromMap(Map<String, dynamic> map) {
    return WaterlowSummary(
      totalQuestions: map['total_questions'] as int,
      totalScore: map['total_score'] as int,
      riskLevel: map['risk_level'] ?? 'Low',
      lastAssessmentDate: map['last_assessment_date'] as DateTime?,
      actionItemsCount: map['action_items_count'] as int,
    );
  }
}