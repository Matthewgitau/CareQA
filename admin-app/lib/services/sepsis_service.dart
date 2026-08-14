import 'package:supabase/supabase.dart';
import 'package:admin_app/models/sepsis_assessment.dart';

class SepsisService {
  final SupabaseClient _client;

  SepsisService(this._client);

  Future<SepsisAssessment> createAssessment(SepsisAssessment assessment) async {
    final response = await _client
        .from('sepsis_risk_assessments')
        .insert(assessment.toMap())
        .select()
        .single();

    return SepsisAssessment.fromMap(response);
  }

  Future<SepsisAssessment> getAssessment(String id) async {
    final response = await _client
        .from('sepsis_risk_assessments')
        .select()
        .eq('id', id)
        .single();

    return SepsisAssessment.fromMap(response);
  }

  Future<List<SepsisAssessment>> getAssessmentsByServiceUser(String serviceUserId) async {
    final response = await _client
        .from('sepsis_risk_assessments')
        .select()
        .eq('service_user_id', serviceUserId)
        .order('assessment_date', ascending: false)
        .order('assessment_time', ascending: false);

    return response.map((map) => SepsisAssessment.fromMap(map)).toList();
  }

  Future<List<SepsisAssessment>> getAssessmentsByAssessor(String assessorId) async {
    final response = await _client
        .from('sepsis_risk_assessments')
        .select()
        .eq('assessor_id', assessorId)
        .order('assessment_date', ascending: false)
        .order('assessment_time', ascending: false);

    return response.map((map) => SepsisAssessment.fromMap(map)).toList();
  }

  Future<List<SepsisAssessment>> getAllAssessments() async {
    final response = await _client
        .from('sepsis_risk_assessments')
        .select()
        .order('assessment_date', ascending: false)
        .order('assessment_time', ascending: false);

    return response.map((map) => SepsisAssessment.fromMap(map)).toList();
  }

  Future<List<SepsisAssessment>> getAssessmentsByRiskLevel(SepsisRiskLevel riskLevel) async {
    final response = await _client
        .from('sepsis_risk_assessments')
        .select()
        .eq('sepsis_risk_level', _riskLevelToString(riskLevel))
        .order('assessment_date', ascending: false)
        .order('assessment_time', ascending: false);

    return response.map((map) => SepsisAssessment.fromMap(map)).toList();
  }

  Future<List<SepsisAssessment>> getAssessmentsByAction(ActionTaken action) async {
    final response = await _client
        .from('sepsis_risk_assessments')
        .select()
        .eq('action_taken', _actionTakenToString(action))
        .order('assessment_date', ascending: false)
        .order('assessment_time', ascending: false);

    return response.map((map) => SepsisAssessment.fromMap(map)).toList();
  }

  Future<List<SepsisAssessment>> getUrgentAssessments() async {
    final response = await _client
        .from('sepsis_risk_assessments')
        .select()
        .gte('news2_score', 5)
        .order('news2_score', ascending: false)
        .order('assessment_date', ascending: false);

    return response.map((map) => SepsisAssessment.fromMap(map)).toList();
  }

  Future<List<SepsisAssessment>> getCriticalAssessments() async {
    final response = await _client
        .from('sepsis_risk_assessments')
        .select()
        .gte('news2_score', 7)
        .order('news2_score', ascending: false)
        .order('assessment_date', ascending: false);

    return response.map((map) => SepsisAssessment.fromMap(map)).toList();
  }

  Future<List<SepsisAssessment>> getAssessmentsNeedingReview() async {
    final response = await _client
        .from('sepsis_risk_assessments')
        .select()
        .lte('review_time', DateTime.now().toUtc())
        .order('review_time', ascending: true);

    return response.map((map) => SepsisAssessment.fromMap(map)).toList();
  }

  Future<SepsisAssessment> updateAssessment(String id, SepsisAssessment assessment) async {
    final response = await _client
        .from('sepsis_risk_assessments')
        .update(assessment.toMap())
        .eq('id', id)
        .select()
        .single();

    return SepsisAssessment.fromMap(response);
  }

  Future<void> deleteAssessment(String id) async {
    await _client
        .from('sepsis_risk_assessments')
        .delete()
        .eq('id', id);
  }

  Future<SepsisAssessment> updateSepsisSix(String id, List<bool> sepsisSixCompleted, Map<String, dynamic> sepsisSixDetails) async {
    final response = await _client
        .from('sepsis_risk_assessments')
        .update({
          'sepsis_six_completed': sepsisSixCompleted,
          'sepsis_six_details': sepsisSixDetails,
          'updated_at': DateTime.now().toUtc(),
        })
        .eq('id', id)
        .select()
        .single();

    return SepsisAssessment.fromMap(response);
  }

  Future<SepsisAssessment> updateReferral(String id, bool referralToHospital, DateTime? referralTime, String? hospitalOutcome) async {
    final response = await _client
        .from('sepsis_risk_assessments')
        .update({
          'referral_to_hospital': referralToHospital,
          'referral_time': referralTime?.toUtc(),
          'hospital_outcome': hospitalOutcome,
          'updated_at': DateTime.now().toUtc(),
        })
        .eq('id', id)
        .select()
        .single();

    return SepsisAssessment.fromMap(response);
  }

  Future<SepsisAssessment> updateReviewTime(String id, DateTime reviewTime) async {
    final response = await _client
        .from('sepsis_risk_assessments')
        .update({
          'review_time': reviewTime.toUtc(),
          'updated_at': DateTime.now().toUtc(),
        })
        .eq('id', id)
        .select()
        .single();

    return SepsisAssessment.fromMap(response);
  }

  Future<Map<String, dynamic>> getAssessmentStats() async {
    // Get all assessments to calculate stats
    final allAssessments = await _client
        .from('sepsis_risk_assessments')
        .select('*');

    // Get urgent assessments
    final urgentAssessments = await _client
        .from('sepsis_risk_assessments')
        .select('id')
        .gte('news2_score', 5);

    // Get critical assessments
    final criticalAssessments = await _client
        .from('sepsis_risk_assessments')
        .select('id')
        .gte('news2_score', 7);

    // Get assessments needing review
    final needingReview = await _client
        .from('sepsis_risk_assessments')
        .select('id')
        .lte('review_time', DateTime.now().toUtc());

    // Calculate counts
    final riskCounts = <String, int>{};
    final actionCounts = <String, int>{};
    final infectionSourceCounts = <String, int>{};

    for (final assessment in allAssessments) {
      final riskLevel = assessment['sepsis_risk_level'] as String;
      final actionTaken = assessment['action_taken'] as String;
      final infectionSource = assessment['infection_source'] as String?;

      riskCounts[riskLevel] = (riskCounts[riskLevel] ?? 0) + 1;
      actionCounts[actionTaken] = (actionCounts[actionTaken] ?? 0) + 1;
      
      if (infectionSource != null && infectionSource.isNotEmpty) {
        infectionSourceCounts[infectionSource] = (infectionSourceCounts[infectionSource] ?? 0) + 1;
      }
    }

    return {
      'risk_counts': riskCounts,
      'action_counts': actionCounts,
      'infection_source_counts': infectionSourceCounts,
      'urgent_assessments': urgentAssessments.length,
      'critical_assessments': criticalAssessments.length,
      'needing_review': needingReview.length,
      'total_assessments': allAssessments.length,
    };
  }

  Future<List<Map<String, dynamic>>> getUrgentAssessmentsList() async {
    final response = await _client.rpc('get_urgent_sepsis_assessments', params: {});
    return response;
  }

  Future<List<Map<String, dynamic>>> getRiskStats() async {
    final response = await _client.rpc('get_sepsis_risk_stats', params: {});
    return response;
  }

  // Helper methods
  String _riskLevelToString(SepsisRiskLevel level) {
    switch (level) {
      case SepsisRiskLevel.low: return 'low';
      case SepsisRiskLevel.medium: return 'medium';
      case SepsisRiskLevel.high: return 'high';
      case SepsisRiskLevel.critical: return 'critical';
    }
  }

  String _actionTakenToString(ActionTaken action) {
    switch (action) {
      case ActionTaken.monitor: return 'monitor';
      case ActionTaken.escalate: return 'escalate';
      case ActionTaken.call999: return '999';
    }
  }

  SepsisRiskLevel _stringToRiskLevel(String value) {
    return SepsisRiskLevel.values.firstWhere(
      (level) => _riskLevelToString(level) == value,
      orElse: () => SepsisRiskLevel.low,
    );
  }

  ActionTaken _stringToActionTaken(String value) {
    return ActionTaken.values.firstWhere(
      (action) => _actionTakenToString(action) == value,
      orElse: () => ActionTaken.monitor,
    );
  }
}