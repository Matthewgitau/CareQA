import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/waterlow_assessment.dart';

class WaterlowService {
  final SupabaseClient _client;

  WaterlowService(this._client);

  Future<List<WaterlowQuestion>> getWaterlowQuestions() async {
    try {
      final data = await _client
          .from('waterlow_questions')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);
      return (data as List).map((e) => WaterlowQuestion.fromMap(e as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<WaterlowAssessment>> getWaterlowAssessmentsByServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('waterlow_assessments')
          .select('*, profiles(full_name)')
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false);
      return (data as List).map((e) => WaterlowAssessment.fromMap(e as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<WaterlowAssessment> createWaterlowAssessment(
    String serviceUserId,
    String assessorId,
    DateTime assessmentDate,
    Map<String, dynamic> responses,
    List<Map<String, dynamic>> actionPlan,
    String? signature,
  ) async {
    final totalScore = responses.values.fold(0, (sum, value) => sum + (value is int ? value : 0));
    final riskLevel = _determineRiskLevel(totalScore);
    try {
      final data = await _client
          .from('waterlow_assessments')
          .insert({
            'service_user_id': serviceUserId,
            'assessor_id': assessorId,
            'assessment_date': assessmentDate.toIso8601String(),
            'responses': responses,
            'action_plan': actionPlan,
            'signature': signature,
            'status': 'completed',
            'total_score': totalScore,
            'risk_level': riskLevel,
          })
          .select()
          .single();
      return WaterlowAssessment.fromMap(data);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> updateWaterlowAssessment(
    String assessmentId,
    Map<String, dynamic> responses,
    List<Map<String, dynamic>> actionPlan,
    String? signature,
  ) async {
    final totalScore = responses.values.fold(0, (sum, value) => sum + (value is int ? value : 0));
    final riskLevel = _determineRiskLevel(totalScore);
    try {
      await _client
          .from('waterlow_assessments')
          .update({
            'responses': responses,
            'action_plan': actionPlan,
            'signature': signature,
            'status': 'completed',
            'total_score': totalScore,
            'risk_level': riskLevel,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assessmentId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<WaterlowAssessment> getWaterlowAssessment(String assessmentId) async {
    try {
      final data = await _client
          .from('waterlow_assessments')
          .select()
          .eq('id', assessmentId)
          .single();
      return WaterlowAssessment.fromMap(data);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> generateWaterlowPdf(String assessmentId) async {
    try {
      await _client.rpc('generate_waterlow_pdf_url',
          params: {'assessment_id': assessmentId});
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<WaterlowSummary?> getWaterlowSummary(String serviceUserId) async {
    try {
      final data = await _client.rpc('get_waterlow_summary',
          params: {'service_user_id_param': serviceUserId});
      if (data == null) return null;
      return WaterlowSummary.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (_) {
      return null;
    }
  }

  Future<WaterlowAssessment?> getLatestWaterlowAssessment(String serviceUserId) async {
    try {
      final data = await _client
          .from('waterlow_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false)
          .limit(1)
          .single();
      return WaterlowAssessment.fromMap(data);
    } on PostgrestException catch (_) {
      return null;
    }
  }

  Future<List<WaterlowAssessment>> getWaterlowAssessmentHistory(String serviceUserId) async {
    try {
      final data = await _client
          .from('waterlow_assessments')
          .select('*, profiles(full_name)')
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false);
      return (data as List).map((e) => WaterlowAssessment.fromMap(e as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  String _determineRiskLevel(int totalScore) {
    if (totalScore >= 15) return 'High';
    if (totalScore >= 10) return 'Moderate';
    return 'Low';
  }
}