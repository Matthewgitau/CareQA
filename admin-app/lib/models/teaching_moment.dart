import 'package:supabase_flutter/supabase_flutter.dart';

class TeachingMoment {
  final String id;
  final String userId;
  final String triggerRuleId;
  final String title;
  final String content;
  final String? videoUrl;
  final String? policyUrl;
  final bool quizRequired;
  final bool? quizPassed;
  final DateTime? viewedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  TeachingMoment({
    required this.id,
    required this.userId,
    required this.triggerRuleId,
    required this.title,
    required this.content,
    this.videoUrl,
    this.policyUrl,
    required this.quizRequired,
    this.quizPassed,
    this.viewedAt,
    this.completedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'trigger_rule_id': triggerRuleId,
      'title': title,
      'content': content,
      'video_url': videoUrl,
      'policy_url': policyUrl,
      'quiz_required': quizRequired,
      'quiz_passed': quizPassed,
      'viewed_at': viewedAt,
      'completed_at': completedAt,
      'created_at': createdAt,
    };
  }

  factory TeachingMoment.fromMap(Map<String, dynamic> map) {
    return TeachingMoment(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      triggerRuleId: map['trigger_rule_id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      videoUrl: map['video_url'],
      policyUrl: map['policy_url'],
      quizRequired: map['quiz_required'] ?? false,
      quizPassed: map['quiz_passed'] as bool?,
      viewedAt: map['viewed_at'] as DateTime?,
      completedAt: map['completed_at'] as DateTime?,
      createdAt: (map['created_at'] as DateTime?) ?? DateTime.now(),
    );
  }
}