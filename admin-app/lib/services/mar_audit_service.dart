import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/mar_audit.dart';
import 'package:supabase/supabase.dart';

class MarAuditService {
  final SupabaseClient _client;

  MarAuditService(this._client);

  // Get all audit questions
  Future<List<MarAuditQuestion>> getQuestions() async {
    try {
      final data = await _client
          .from('mar_audit_questions')
          .select('*')
          .eq('is_active', true)
          .order('display_order');
      
      return (data as List)
          .map((q) => MarAuditQuestion.fromMap(q as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get questions as raw map data (for database operations)
  Future<List<Map<String, dynamic>>> getQuestionsRaw() async {
    try {
      final data = await _client
          .from('mar_audit_questions')
          .select('*')
          .order('display_order');
      
      return List<Map<String, dynamic>>.from(data as List);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get questions by category
  Future<List<MarAuditCategory>> getQuestionsByCategory() async {
    try {
      final data = await _client.rpc('get_mar_audit_questions_by_category', params: {});
      
      return (data as List)
          .map((c) => MarAuditCategory.fromMap(c as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Create new audit
  Future<String> createAudit({
    required String serviceUserId,
    required String serviceUserName,
    required String assessorName,
    required DateTime auditDate,
  }) async {
    try {
      final data = await _client.from('mar_audits').insert({
        'service_user_id': serviceUserId,
        'service_user_name': serviceUserName,
        'assessor_name': assessorName,
        'audit_date': auditDate.toIso8601String(),
        'created_by': _client.auth.currentUser?.id,
        'status': 'draft',
      }).select().single();
      
      return data['id'] as String;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Save answers
  Future<void> saveAnswers({
    required String auditId,
    required Map<int, MarAuditAnswer> answers,
  }) async {
    // Delete existing answers
    try {
      await _client
          .from('mar_audit_answers')
          .delete()
          .eq('audit_id', auditId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
    
    // Insert new answers
    if (answers.isNotEmpty) {
      final answerEntries = answers.entries.map((e) => {
        'audit_id': auditId,
        'question_id': e.key,
        'answer': e.value.answer,
        'comment': e.value.comment,
        'deadline_date': e.value.deadlineDate?.toIso8601String(),
        'notification_sent': e.value.notificationSent,
      }).toList();
      
      try {
        await _client.from('mar_audit_answers').insert(answerEntries);
      } on PostgrestException catch (e) {
        throw Exception(e.message);
      }
    }
  }

  // Complete audit
  Future<void> completeAudit(String auditId) async {
    try {
      await _client
          .from('mar_audits')
          .update({
            'status': 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', auditId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Search audits
  Future<List<MarAuditSearchResult>> searchAudits({
    String serviceUserName = '',
    String assessorName = '',
    DateTime? dateFrom,
    DateTime? dateTo,
    String status = '',
  }) async {
    try {
      final data = await _client.rpc('search_mar_audits', params: {
        'service_user_name': serviceUserName,
        'assessor_name': assessorName,
        'date_from': dateFrom?.toIso8601String(),
        'date_to': dateTo?.toIso8601String(),
        'status': status,
      });
      
      return (data as List)
          .map((item) => MarAuditSearchResult.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get audit with answers
  Future<MarAudit> getAuditWithAnswers(String auditId) async {
    try {
      final data = await _client.rpc('get_mar_audit_with_answers', params: {
        'audit_id': auditId,
      });
      
      final auditData = data['audit_data'] as Map<String, dynamic>;
      final answersData = data['answers_data'] as List<dynamic>;
      
      return MarAudit.fromAuditWithAnswers(
        auditData,
        answersData.cast<Map<String, dynamic>>(),
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get audit summary
  Future<MarAuditSummary?> getAuditSummary(String auditId) async {
    try {
      final data = await _client.rpc('get_mar_audit_summary', params: {
        'audit_id': auditId,
      });
      
      if (data == null) {
        return null;
      }
      
      return MarAuditSummary.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      print('Error fetching MAR audit summary: ${e.message}');
      return null;
    }
  }

  // Validate audit completeness
  Future<MarAuditValidation> validateAuditCompleteness(String auditId) async {
    try {
      final data = await _client.rpc('validate_mar_audit_completeness', params: {
        'audit_id': auditId,
      });
      
      return MarAuditValidation.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Submit audit
  Future<bool> submitAudit(String auditId) async {
    try {
      final data = await _client.rpc('submit_mar_audit', params: {
        'audit_id': auditId,
      });
      
      return data as bool;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get audits for service user
  Future<List<MarAuditSearchResult>> getAuditsForServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('mar_audits')
          .select('id, service_user_name, audit_date, assessor_name, status, created_at')
          .eq('service_user_id', serviceUserId)
          .order('audit_date', ascending: false);
      
      return (data as List)
          .map((item) => MarAuditSearchResult.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      print('Error fetching MAR audits: ${e.message}');
      return [];
    }
  }

  // Get latest audit for service user
  Future<MarAudit?> getLatestAudit(String serviceUserId) async {
    try {
      final data = await _client
          .from('mar_audits')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('audit_date', ascending: false)
          .limit(1)
          .single();
      
      return getAuditWithAnswers(data['id'] as String);
    } on PostgrestException catch (_) {
      return null;
    }
  }

  // Delete audit
  Future<void> deleteAudit(String auditId) async {
    try {
      await _client
          .from('mar_audits')
          .delete()
          .eq('id', auditId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get questions with default answers for new audit
  Future<Map<int, MarAuditAnswer>> getInitialAnswers(List<MarAuditQuestion> questions, String auditId) async {
    final answers = <int, MarAuditAnswer>{};
    
    for (final question in questions) {
      answers[question.id] = MarAuditAnswer(
        id: '',
        auditId: auditId,
        questionId: question.id,
        answer: 'na', // Default to N/A
        comment: '',
        deadlineDate: null,
        notificationSent: false,
      );
    }
    
    return answers;
  }

  // Update single answer
  Future<void> updateAnswer(MarAuditAnswer answer) async {
    try {
      await _client.from('mar_audit_answers').upsert({
        'audit_id': answer.auditId,
        'question_id': answer.questionId,
        'answer': answer.answer,
        'comment': answer.comment,
        'deadline_date': answer.deadlineDate?.toIso8601String(),
        'notification_sent': answer.notificationSent,
      }, onConflict: 'audit_id, question_id');
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get audits with approaching deadlines
  Future<List<MarAuditSearchResult>> getAuditsWithApproachingDeadlines() async {
    try {
      final data = await _client
          .from('mar_audit_answers')
          .select('mar_audits(id, service_user_name, audit_date, assessor_name, status, created_at)')
          .not('deadline_date', 'is', null)
          .lte('deadline_date', DateTime.now().add(Duration(days: 7)).toIso8601String())
          .order('deadline_date', ascending: true);
      
      // Extract audit data from nested structure
      final audits = <MarAuditSearchResult>[];
      for (final item in data as List) {
        final auditData = (item as Map<String, dynamic>)['mar_audits'];
        if (auditData != null) {
          audits.add(MarAuditSearchResult.fromMap(auditData as Map<String, dynamic>));
        }
      }
      
      return audits;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}