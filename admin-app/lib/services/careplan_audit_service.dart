import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/careplan_audit.dart';
import 'package:supabase/supabase.dart';

class CarePlanAuditService {
  final SupabaseClient _client;

  CarePlanAuditService(this._client);

  // Get all care plan audit items
  Future<List<CarePlanAuditItem>> getItems() async {
    try {
      final data = await _client
          .from('careplan_audit_items')
          .select('*')
          .eq('is_active', true)
          .order('display_order');
      
      return (data as List)
          .map((i) => CarePlanAuditItem.fromMap(i as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get items as raw map data (for database operations)
  Future<List<Map<String, dynamic>>> getItemsRaw() async {
    try {
      final data = await _client
          .from('careplan_audit_items')
          .select('*')
          .order('display_order');
      
      return List<Map<String, dynamic>>.from(data as List);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get items by category
  Future<List<CarePlanAuditCategory>> getItemsByCategory() async {
    try {
      final data = await _client.rpc('get_careplan_audit_items_by_category', params: {});
      
      return (data as List)
          .map((c) => CarePlanAuditCategory.fromMap(c as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Create new care plan audit
  Future<String> createCarePlanAudit({
    required String serviceUserId,
    required String serviceUserName,
    required String auditorId,
    required String auditorName,
    required DateTime auditDate,
    required String carePlanName,
  }) async {
    try {
      final data = await _client.from('careplan_audits').insert({
        'service_user_id': serviceUserId,
        'service_user_name': serviceUserName,
        'auditor_id': auditorId,
        'auditor_name': auditorName,
        'audit_date': auditDate.toIso8601String(),
        'care_plan_name': carePlanName,
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
    required Map<int, CarePlanAuditAnswer> answers,
  }) async {
    // Delete existing answers
    try {
      await _client
          .from('careplan_audit_answers')
          .delete()
          .eq('audit_id', auditId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
    
    // Insert new answers
    if (answers.isNotEmpty) {
      final answerEntries = answers.entries.map((e) => {
        'audit_id': auditId,
        'item_id': e.key,
        'present': e.value.present,
        'comment': e.value.comment,
        'action_needed': e.value.actionNeeded,
      }).toList();
      
      try {
        await _client.from('careplan_audit_answers').insert(answerEntries);
      } on PostgrestException catch (e) {
        throw Exception(e.message);
      }
    }
  }

  // Complete care plan audit
  Future<void> completeCarePlanAudit(String auditId) async {
    try {
      await _client
          .from('careplan_audits')
          .update({
            'status': 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', auditId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Search care plan audits
  Future<List<CarePlanAuditSearchResult>> searchCarePlanAudits({
    String serviceUserName = '',
    String auditorName = '',
    DateTime? dateFrom,
    DateTime? dateTo,
    String status = '',
    String carePlanName = '',
  }) async {
    try {
      final data = await _client.rpc('search_careplan_audits', params: {
        'service_user_name': serviceUserName,
        'auditor_name': auditorName,
        'date_from': dateFrom?.toIso8601String(),
        'date_to': dateTo?.toIso8601String(),
        'status': status,
        'care_plan_name': carePlanName,
      });
      
      return (data as List)
          .map((item) => CarePlanAuditSearchResult.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get care plan audit with answers
  Future<CarePlanAudit> getCarePlanAuditWithAnswers(String auditId) async {
    try {
      final data = await _client.rpc('get_careplan_audit_with_answers', params: {
        'audit_id': auditId,
      });
      
      final auditData = data['audit_data'] as Map<String, dynamic>;
      final answersData = data['answers_data'] as List<dynamic>;
      
      return CarePlanAudit.fromAuditWithAnswers(
        auditData,
        answersData.cast<Map<String, dynamic>>(),
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get care plan audit summary
  Future<CarePlanAuditSummary?> getCarePlanAuditSummary(String auditId) async {
    try {
      final data = await _client.rpc('get_careplan_audit_summary', params: {
        'audit_id': auditId,
      });
      
      if (data == null) {
        return null;
      }
      
      return CarePlanAuditSummary.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      print('Error fetching care plan audit summary: ${e.message}');
      return null;
    }
  }

  // Validate care plan audit completeness
  Future<CarePlanAuditValidation> validateCarePlanAuditCompleteness(String auditId) async {
    try {
      final data = await _client.rpc('validate_careplan_audit_completeness', params: {
        'audit_id': auditId,
      });
      
      return CarePlanAuditValidation.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Submit care plan audit
  Future<bool> submitCarePlanAudit(String auditId) async {
    try {
      final data = await _client.rpc('submit_careplan_audit', params: {
        'audit_id': auditId,
      });
      
      return data as bool;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get care plan audits for service user
  Future<List<CarePlanAuditSearchResult>> getCarePlanAuditsForServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('careplan_audits')
          .select('id, service_user_name, audit_date, auditor_name, care_plan_name, status, created_at')
          .eq('service_user_id', serviceUserId)
          .order('audit_date', ascending: false);
      
      return (data as List)
          .map((item) => CarePlanAuditSearchResult.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      print('Error fetching care plan audits: ${e.message}');
      return [];
    }
  }

  // Get latest care plan audit for service user
  Future<CarePlanAudit?> getLatestCarePlanAudit(String serviceUserId) async {
    try {
      final data = await _client
          .from('careplan_audits')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('audit_date', ascending: false)
          .limit(1)
          .single();
      
      return getCarePlanAuditWithAnswers(data['id'] as String);
    } on PostgrestException catch (_) {
      return null;
    }
  }

  // Delete care plan audit
  Future<void> deleteCarePlanAudit(String auditId) async {
    try {
      await _client
          .from('careplan_audits')
          .delete()
          .eq('id', auditId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get items with default answers for new care plan audit
  Future<Map<int, CarePlanAuditAnswer>> getInitialAnswers(List<CarePlanAuditItem> items, String auditId) async {
    final answers = <int, CarePlanAuditAnswer>{};
    
    for (final item in items) {
      answers[item.id] = CarePlanAuditAnswer(
        id: '',
        auditId: auditId,
        itemId: item.id,
        present: false, // Default to missing
        comment: '',
        actionNeeded: '',
      );
    }
    
    return answers;
  }

  // Update single answer
  Future<void> updateAnswer(CarePlanAuditAnswer answer) async {
    try {
      await _client.from('careplan_audit_answers').upsert({
        'audit_id': answer.auditId,
        'item_id': answer.itemId,
        'present': answer.present,
        'comment': answer.comment,
        'action_needed': answer.actionNeeded,
      }, onConflict: 'audit_id, item_id');
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get care plan audits with missing items
  Future<List<CarePlanAuditSearchResult>> getCarePlanAudiMissingItems() async {
    try {
      final data = await _client
          .from('careplan_audit_answers')
          .select('careplan_audits(id, service_user_name, audit_date, auditor_name, care_plan_name, status, created_at)')
          .eq('present', false)
          .order('created_at', ascending: false);
      
      // Extract audit data from nested structure
      final audits = <CarePlanAuditSearchResult>[];
      for (final item in data as List) {
        final auditData = (item as Map<String, dynamic>)['careplan_audits'];
        if (auditData != null) {
          audits.add(CarePlanAuditSearchResult.fromMap(auditData as Map<String, dynamic>));
        }
      }
      
      return audits;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}