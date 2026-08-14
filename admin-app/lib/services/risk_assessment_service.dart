import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/risk_assessment_question.dart';
import 'package:admin_app/models/risk_assessment.dart';

class RiskAssessmentService {
  final SupabaseClient _client;

  RiskAssessmentService(this._client);

  Future<List<RiskAssessmentQuestion>> getRiskAssessmentQuestions() async {
    try {
      final data = await _client
          .from('risk_assessment_questions')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);
      return (data as List).map((e) => RiskAssessmentQuestion.fromMap(e as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<RiskAssessment>> getRiskAssessmentsByServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('risk_assessments')
          .select('*, profiles(full_name)')
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false);
      return (data as List).map((e) => RiskAssessment.fromMap(e as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<RiskAssessment> createRiskAssessment(
    String serviceUserId,
    DateTime assessmentDate,
    String? completedBy,
  ) async {
    try {
      final data = await _client
          .from('risk_assessments')
          .insert({
            'service_user_id': serviceUserId,
            'assessment_date': assessmentDate.toIso8601String(),
            'completed_by': completedBy,
            'statement_confirmed': false,
          })
          .select()
          .single();
      return RiskAssessment.fromMap(data);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> updateRiskAssessmentStatement(
    String assessmentId,
    bool statementConfirmed,
  ) async {
    try {
      await _client
          .from('risk_assessments')
          .update({'statement_confirmed': statementConfirmed})
          .eq('id', assessmentId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> generateRiskAssessmentPdf(String assessmentId) async {
    try {
      await _client.rpc('generate_risk_assessment_pdf_url',
          params: {'assessment_id': assessmentId});
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<RiskAssessmentAnswer>> getRiskAssessmentAnswers(String assessmentId) async {
    try {
      final data = await _client
          .from('risk_assessment_answers')
          .select('*, risk_assessment_questions(question_text, display_order)')
          .eq('assessment_id', assessmentId)
          .order('risk_assessment_questions.display_order', ascending: true);
      return (data as List).map((e) => RiskAssessmentAnswer.fromMap(e as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> saveRiskAssessmentAnswers(
    String assessmentId,
    List<Map<String, dynamic>> answers,
  ) async {
    try {
      await _client
          .from('risk_assessment_answers')
          .delete()
          .eq('assessment_id', assessmentId);
      if (answers.isNotEmpty) {
        await _client.from('risk_assessment_answers').insert(answers);
      }
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> updateRiskAssessmentAnswer(
    String answerId,
    bool riskIdentified,
    bool ifRiskIdentified,
    bool actionRequired,
    String? actionText,
  ) async {
    try {
      await _client
          .from('risk_assessment_answers')
          .update({
            'risk_identified': riskIdentified,
            'if_risk_identified': ifRiskIdentified,
            'action_required': actionRequired,
            'action_text': actionText,
          })
          .eq('id', answerId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<RiskAssessmentSummary?> getRiskAssessmentSummary(String serviceUserId) async {
    try {
      final data = await _client.rpc('get_risk_assessment_summary',
          params: {'service_user_id_param': serviceUserId});
      if (data == null) return null;
      return RiskAssessmentSummary.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (_) {
      return null;
    }
  }

  Future<RiskAssessment> createCompleteRiskAssessment(
    String serviceUserId,
    DateTime assessmentDate,
    String? completedBy,
    List<Map<String, dynamic>> answers,
  ) async {
    final assessment = await createRiskAssessment(serviceUserId, assessmentDate, completedBy);
    await saveRiskAssessmentAnswers(assessment.id, answers);
    return assessment;
  }

  Future<RiskAssessment?> getLatestRiskAssessment(String serviceUserId) async {
    try {
      final data = await _client
          .from('risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false)
          .limit(1)
          .single();
      return RiskAssessment.fromMap(data);
    } on PostgrestException catch (_) {
      return null;
    }
  }

  Future<List<RiskAssessment>> getRiskAssessmentHistory(String serviceUserId) async {
    try {
      final data = await _client
          .from('risk_assessments')
          .select('*, profiles(full_name)')
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false);
      return (data as List).map((e) => RiskAssessment.fromMap(e as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}