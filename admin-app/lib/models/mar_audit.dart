import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class MarAuditQuestion {
  final int id;
  final String questionText;
  final String? category;
  final int displayOrder;
  final bool isActive;
  final bool requiresDeadline;
  final bool requiresComment;

  MarAuditQuestion({
    required this.id,
    required this.questionText,
    this.category,
    required this.displayOrder,
    this.isActive = true,
    this.requiresDeadline = false,
    this.requiresComment = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_text': questionText,
      'category': category,
      'display_order': displayOrder,
      'is_active': isActive,
      'requires_deadline': requiresDeadline,
      'requires_comment': requiresComment,
    };
  }

  factory MarAuditQuestion.fromMap(Map<String, dynamic> map) {
    return MarAuditQuestion(
      id: map['id'] as int,
      questionText: map['question_text'] as String,
      category: map['category'],
      displayOrder: map['display_order'] as int,
      isActive: map['is_active'] as bool,
      requiresDeadline: map['requires_deadline'] as bool,
      requiresComment: map['requires_comment'] as bool,
    );
  }
}

class MarAuditAnswer {
  final String id;
  final String auditId;
  final int questionId;
  String answer; // 'yes', 'no', 'na'
  String? comment;
  DateTime? deadlineDate;
  bool notificationSent;

  MarAuditAnswer({
    required this.id,
    required this.auditId,
    required this.questionId,
    required this.answer,
    this.comment,
    this.deadlineDate,
    this.notificationSent = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'audit_id': auditId,
      'question_id': questionId,
      'answer': answer,
      'comment': comment,
      'deadline_date': deadlineDate?.toIso8601String(),
      'notification_sent': notificationSent,
    };
  }

  factory MarAuditAnswer.fromMap(Map<String, dynamic> map) {
    return MarAuditAnswer(
      id: map['id'] ?? '',
      auditId: map['audit_id'] ?? '',
      questionId: map['question_id'] as int,
      answer: map['answer'] as String,
      comment: map['comment'],
      deadlineDate: map['deadline_date'] as DateTime?,
      notificationSent: map['notification_sent'] as bool? ?? false,
    );
  }
}

class MarAudit {
  final String id;
  final String serviceUserId;
  final String serviceUserName;
  final String assessorName;
  final DateTime auditDate;
  final String status;
  final DateTime createdAt;
  final String? createdBy;
  final DateTime updatedAt;

  // Calculated metrics
  int get totalQuestions => answers.length;
  int get answeredQuestions => answers.values.where((a) => a.answer != 'na').length;
  int get yesAnswers => answers.values.where((a) => a.answer == 'yes').length;
  int get noAnswers => answers.values.where((a) => a.answer == 'no').length;
  int get naAnswers => answers.values.where((a) => a.answer == 'na').length;
  int get pendingDeadlines => answers.values.where((a) => 
    a.deadlineDate != null && a.deadlineDate!.isAfter(DateTime.now())
  ).length;

  // Answers map (questionId -> answer)
  final Map<int, MarAuditAnswer> answers;

  MarAudit({
    required this.id,
    required this.serviceUserId,
    required this.serviceUserName,
    required this.assessorName,
    required this.auditDate,
    required this.status,
    required this.createdAt,
    this.createdBy,
    required this.updatedAt,
    required this.answers,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_user_id': serviceUserId,
      'service_user_name': serviceUserName,
      'assessor_name': assessorName,
      'audit_date': auditDate.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MarAudit.fromMap(Map<String, dynamic> map) {
    return MarAudit(
      id: map['id'] ?? '',
      serviceUserId: map['service_user_id'] ?? '',
      serviceUserName: map['service_user_name'] ?? '',
      assessorName: map['assessor_name'] ?? '',
      auditDate: (map['audit_date'] as DateTime?) ?? DateTime.now(),
      status: map['status'] ?? 'draft',
      createdAt: (map['created_at'] as DateTime?) ?? DateTime.now(),
      createdBy: map['created_by'],
      updatedAt: (map['updated_at'] as DateTime?) ?? DateTime.now(),
      answers: {},
    );
  }

  // Factory for creating from audit with answers
  factory MarAudit.fromAuditWithAnswers(Map<String, dynamic> auditData, List<Map<String, dynamic>> answersData) {
    final audit = MarAudit.fromMap(auditData);
    
    // Convert answers data to map
    final answers = <int, MarAuditAnswer>{};
    for (final answerData in answersData) {
      final answer = MarAuditAnswer.fromMap(answerData);
      answers[answer.questionId] = answer;
    }
    
    return MarAudit(
      id: audit.id,
      serviceUserId: audit.serviceUserId,
      serviceUserName: audit.serviceUserName,
      assessorName: audit.assessorName,
      auditDate: audit.auditDate,
      status: audit.status,
      createdAt: audit.createdAt,
      createdBy: audit.createdBy,
      updatedAt: audit.updatedAt,
      answers: answers,
    );
  }
}

class MarAuditSummary {
  final int totalQuestions;
  final int answeredQuestions;
  final int yesAnswers;
  final int noAnswers;
  final int naAnswers;
  final int pendingDeadlines;
  final DateTime auditDate;
  final String assessorName;
  final String serviceUserName;
  final String status;

  MarAuditSummary({
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.yesAnswers,
    required this.noAnswers,
    required this.naAnswers,
    required this.pendingDeadlines,
    required this.auditDate,
    required this.assessorName,
    required this.serviceUserName,
    required this.status,
  });

  factory MarAuditSummary.fromMap(Map<String, dynamic> map) {
    return MarAuditSummary(
      totalQuestions: map['total_questions'] as int,
      answeredQuestions: map['answered_questions'] as int,
      yesAnswers: map['yes_answers'] as int,
      noAnswers: map['no_answers'] as int,
      naAnswers: map['na_answers'] as int,
      pendingDeadlines: map['pending_deadlines'] as int,
      auditDate: (map['audit_date'] as DateTime?) ?? DateTime.now(),
      assessorName: map['assessor_name'] as String,
      serviceUserName: map['service_user_name'] as String,
      status: map['status'] as String,
    );
  }
}

class MarAuditValidation {
  final bool isComplete;
  final int missingAnswers;
  final List<String> warnings;

  MarAuditValidation({
    required this.isComplete,
    required this.missingAnswers,
    required this.warnings,
  });

  factory MarAuditValidation.fromMap(Map<String, dynamic> map) {
    return MarAuditValidation(
      isComplete: map['is_complete'] as bool,
      missingAnswers: map['missing_answers'] as int,
      warnings: List<String>.from(map['warnings'] ?? []),
    );
  }
}

class MarAuditSearchResult {
  final String auditId;
  final String serviceUserName;
  final DateTime auditDate;
  final String assessorName;
  final String status;
  final DateTime createdAt;

  MarAuditSearchResult({
    required this.auditId,
    required this.serviceUserName,
    required this.auditDate,
    required this.assessorName,
    required this.status,
    required this.createdAt,
  });

  factory MarAuditSearchResult.fromMap(Map<String, dynamic> map) {
    return MarAuditSearchResult(
      auditId: map['audit_id'] ?? '',
      serviceUserName: map['service_user_name'] ?? '',
      auditDate: (map['audit_date'] as DateTime?) ?? DateTime.now(),
      assessorName: map['assessor_name'] as String,
      status: map['status'] as String,
      createdAt: (map['created_at'] as DateTime?) ?? DateTime.now(),
    );
  }
}

class MarAuditCategory {
  final String category;
  final List<MarAuditQuestion> questions;

  MarAuditCategory({
    required this.category,
    required this.questions,
  });

  factory MarAuditCategory.fromMap(Map<String, dynamic> map) {
    final questionsData = map['questions'] as List<dynamic>;
    final questions = questionsData.map((q) => MarAuditQuestion.fromMap(q)).toList();
    
    return MarAuditCategory(
      category: map['category'] as String,
      questions: questions,
    );
  }
}

// Helper classes for answer options
class MarAuditAnswerOption {
  final String value;
  final String label;
  final Color color;

  MarAuditAnswerOption(this.value, this.label, this.color);

  @override
  String toString() => label;
}

// Constants for answer options
class MarAuditConstants {
  static final List<MarAuditAnswerOption> answerOptions = [
    MarAuditAnswerOption('yes', 'Yes', Colors.green),
    MarAuditAnswerOption('no', 'No', Colors.red),
    MarAuditAnswerOption('na', 'N/A', Colors.grey),
  ];

  static final List<String> categories = [
    'Legibility',
    'Documentation', 
    'Details',
    'Dosages',
    'Administration',
    'Codes',
    'Coverage',
    'Signatures',
    'Accuracy',
    'Completion',
    'Storage',
    'Warfarin',
    'Clarity',
    'PRN',
    'Omissions',
    'Directions',
    'Care Plans',
  ];
}
