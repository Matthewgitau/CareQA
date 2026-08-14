import 'package:supabase_flutter/supabase_flutter.dart';

class RiskAssessment {
  final String id;
  final String serviceUserId;
  final DateTime assessmentDate;
  final String? completedBy;
  final bool statementConfirmed;
  final String? pdfUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  RiskAssessment({
    required this.id,
    required this.serviceUserId,
    required this.assessmentDate,
    this.completedBy,
    required this.statementConfirmed,
    this.pdfUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_user_id': serviceUserId,
      'assessment_date': assessmentDate,
      'completed_by': completedBy,
      'statement_confirmed': statementConfirmed,
      'pdf_url': pdfUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory RiskAssessment.fromMap(Map<String, dynamic> map) {
    return RiskAssessment(
      id: map['id'] ?? '',
      serviceUserId: map['service_user_id'] ?? '',
      assessmentDate: (map['assessment_date'] as DateTime?) ?? DateTime.now(),
      completedBy: map['completed_by'],
      statementConfirmed: map['statement_confirmed'] ?? false,
      pdfUrl: map['pdf_url'],
      createdAt: (map['created_at'] as DateTime?) ?? DateTime.now(),
      updatedAt: (map['updated_at'] as DateTime?) ?? DateTime.now(),
    );
  }
}

class RiskAssessmentAnswer {
  final String id;
  final String assessmentId;
  final int questionId;
  final bool riskIdentified;
  final bool ifRiskIdentified;
  final bool actionRequired;
  final String? actionText;
  final DateTime createdAt;
  final DateTime updatedAt;

  RiskAssessmentAnswer({
    required this.id,
    required this.assessmentId,
    required this.questionId,
    required this.riskIdentified,
    required this.ifRiskIdentified,
    required this.actionRequired,
    this.actionText,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assessment_id': assessmentId,
      'question_id': questionId,
      'risk_identified': riskIdentified,
      'if_risk_identified': ifRiskIdentified,
      'action_required': actionRequired,
      'action_text': actionText,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory RiskAssessmentAnswer.fromMap(Map<String, dynamic> map) {
    return RiskAssessmentAnswer(
      id: map['id'] ?? '',
      assessmentId: map['assessment_id'] ?? '',
      questionId: map['question_id'] as int,
      riskIdentified: map['risk_identified'] ?? false,
      ifRiskIdentified: map['if_risk_identified'] ?? false,
      actionRequired: map['action_required'] ?? false,
      actionText: map['action_text'],
      createdAt: (map['created_at'] as DateTime?) ?? DateTime.now(),
      updatedAt: (map['updated_at'] as DateTime?) ?? DateTime.now(),
    );
  }
}

class RiskAssessmentSummary {
  final int totalQuestions;
  final int risksIdentified;
  final int actionsRequired;
  final DateTime? lastAssessmentDate;
  final bool statementConfirmed;

  RiskAssessmentSummary({
    required this.totalQuestions,
    required this.risksIdentified,
    required this.actionsRequired,
    this.lastAssessmentDate,
    required this.statementConfirmed,
  });

  factory RiskAssessmentSummary.fromMap(Map<String, dynamic> map) {
    return RiskAssessmentSummary(
      totalQuestions: map['total_questions'] as int,
      risksIdentified: map['risks_identified'] as int,
      actionsRequired: map['actions_required'] as int,
      lastAssessmentDate: map['last_assessment_date'] as DateTime?,
      statementConfirmed: map['statement_confirmed'] as bool,
    );
  }
}