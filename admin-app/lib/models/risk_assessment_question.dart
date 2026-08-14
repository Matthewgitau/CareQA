import 'package:supabase_flutter/supabase_flutter.dart';

class RiskAssessmentQuestion {
  final int id;
  final String questionText;
  final String? category;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  RiskAssessmentQuestion({
    required this.id,
    required this.questionText,
    this.category,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_text': questionText,
      'category': category,
      'display_order': displayOrder,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory RiskAssessmentQuestion.fromMap(Map<String, dynamic> map) {
    return RiskAssessmentQuestion(
      id: map['id'] as int,
      questionText: map['question_text'] as String,
      category: map['category'] as String?,
      displayOrder: map['display_order'] as int,
      isActive: map['is_active'] as bool,
      createdAt: (map['created_at'] as DateTime?) ?? DateTime.now(),
      updatedAt: (map['updated_at'] as DateTime?) ?? DateTime.now(),
    );
  }
}