import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/mca_assessment.dart';

class McaService {
  final SupabaseClient _client;

  McaService(this._client);

  Future<List<McaAssessment>> getAssessmentsForServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('mca_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false);
      return (data as List)
          .map((e) => McaAssessment.fromMap(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<McaAssessment>> getAllAssessments() async {
    try {
      final data = await _client
          .from('mca_assessments')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      return (data as List)
          .map((e) => McaAssessment.fromMap(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<McaAssessment?> getLatestByDecisionType(
      String serviceUserId, String decisionType) async {
    try {
      final data = await _client
          .from('mca_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .eq('decision_type', decisionType)
          .order('assessment_date', ascending: false)
          .limit(1)
          .single();
      return McaAssessment.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (_) {
      return null;
    }
  }

  Future<String> createAssessment(McaAssessment assessment) async {
    try {
      final data = await _client
          .from('mca_assessments')
          .insert({
            ...assessment.toMap(),
            'created_by': _client.auth.currentUser?.id,
          })
          .select()
          .single();
      return (data as Map<String, dynamic>)['id'] as String;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> updateAssessment(String id, McaAssessment assessment) async {
    try {
      await _client
          .from('mca_assessments')
          .update({
            ...assessment.toMap(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> deleteAssessment(String id) async {
    try {
      await _client.from('mca_assessments').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}