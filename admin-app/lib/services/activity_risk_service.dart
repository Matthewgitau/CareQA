import 'package:supabase/supabase.dart';
import 'package:admin_app/models/activity_risk_assessment.dart';

class ActivityRiskService {
  final SupabaseClient _client;

  ActivityRiskService(this._client);

  Future<ActivityRiskAssessment> createAssessment(ActivityRiskAssessment assessment) async {
    final response = await _client
        .from('activity_risk_assessments')
        .insert(assessment.toMap())
        .select()
        .single();

    return ActivityRiskAssessment.fromMap(response);
  }

  Future<ActivityRiskAssessment> getAssessment(String id) async {
    final response = await _client
        .from('activity_risk_assessments')
        .select()
        .eq('id', id)
        .single();

    return ActivityRiskAssessment.fromMap(response);
  }

  Future<List<ActivityRiskAssessment>> getAssessmentsByServiceUser(String serviceUserId) async {
    final response = await _client
        .from('activity_risk_assessments')
        .select()
        .eq('service_user_id', serviceUserId)
        .order('created_at', ascending: false);

    return response.map((map) => ActivityRiskAssessment.fromMap(map)).toList();
  }

  Future<List<ActivityRiskAssessment>> getAssessmentsByAssessor(String assessorId) async {
    final response = await _client
        .from('activity_risk_assessments')
        .select()
        .eq('assessor_id', assessorId)
        .order('created_at', ascending: false);

    return response.map((map) => ActivityRiskAssessment.fromMap(map)).toList();
  }

  Future<List<ActivityRiskAssessment>> getAllAssessments() async {
    final response = await _client
        .from('activity_risk_assessments')
        .select()
        .order('created_at', ascending: false);

    return response.map((map) => ActivityRiskAssessment.fromMap(map)).toList();
  }

  Future<List<ActivityRiskAssessment>> getAssessmentsByStatus(String status) async {
    final response = await _client
        .from('activity_risk_assessments')
        .select()
        .eq('status', status)
        .order('created_at', ascending: false);

    return response.map((map) => ActivityRiskAssessment.fromMap(map)).toList();
  }

  Future<List<ActivityRiskAssessment>> getAssessmentsByRiskLevel(String riskLevel) async {
    final response = await _client
        .from('activity_risk_assessments')
        .select()
        .eq('risk_level', riskLevel)
        .order('created_at', ascending: false);

    return response.map((map) => ActivityRiskAssessment.fromMap(map)).toList();
  }

  Future<List<ActivityRiskAssessment>> getAssessmentsByActivityType(ActivityType activityType) async {
    final response = await _client
        .from('activity_risk_assessments')
        .select()
        .eq('activity_type', _activityTypeToString(activityType))
        .order('created_at', ascending: false);

    return response.map((map) => ActivityRiskAssessment.fromMap(map)).toList();
  }

  Future<List<ActivityRiskAssessment>> getAssessmentsNeedingReview() async {
    final response = await _client
        .from('activity_risk_assessments')
        .select()
        .lte('review_date', DateTime.now().toUtc())
        .order('review_date', ascending: true);

    return response.map((map) => ActivityRiskAssessment.fromMap(map)).toList();
  }

  Future<List<ActivityRiskAssessment>> getAssessmentsNeedingEscalation() async {
    final response = await _client
        .from('activity_risk_assessments')
        .select()
        .eq('status', 'pending')
        .or('risk_level.eq.high,risk_level.eq.extreme');

    return response.map((map) => ActivityRiskAssessment.fromMap(map)).toList();
  }

  Future<ActivityRiskAssessment> updateAssessment(String id, ActivityRiskAssessment assessment) async {
    final response = await _client
        .from('activity_risk_assessments')
        .update(assessment.toMap())
        .eq('id', id)
        .select()
        .single();

    return ActivityRiskAssessment.fromMap(response);
  }

  Future<void> deleteAssessment(String id) async {
    await _client
        .from('activity_risk_assessments')
        .delete()
        .eq('id', id);
  }

  Future<ActivityRiskAssessment> submitAssessment(String id, String submittedById) async {
    final response = await _client
        .from('activity_risk_assessments')
        .update({
          'status': 'submitted',
          'submitted_at': DateTime.now().toUtc(),
          'submitted_by': submittedById,
        })
        .eq('id', id)
        .select()
        .single();

    return ActivityRiskAssessment.fromMap(response);
  }

  Future<ActivityRiskAssessment> escalateAssessment(String id, String escalatedById) async {
    final response = await _client
        .from('activity_risk_assessments')
        .update({
          'status': 'escalated',
          'escalated_at': DateTime.now().toUtc(),
          'escalated_by': escalatedById,
        })
        .eq('id', id)
        .select()
        .single();

    return ActivityRiskAssessment.fromMap(response);
  }

  Future<ActivityRiskAssessment> completeAssessment(String id, String completedById) async {
    final response = await _client
        .from('activity_risk_assessments')
        .update({
          'status': 'completed',
          'completed_at': DateTime.now().toUtc(),
          'completed_by': completedById,
        })
        .eq('id', id)
        .select()
        .single();

    return ActivityRiskAssessment.fromMap(response);
  }

  Future<Map<String, dynamic>> getAssessmentStats() async {
    // Get all assessments to calculate stats
    final allAssessments = await _client
        .from('activity_risk_assessments')
        .select('*');

    // Get assessments needing review
    final needingReview = await _client
        .from('activity_risk_assessments')
        .select('id')
        .lte('review_date', DateTime.now().toUtc());

    // Get assessments needing escalation
    final needingEscalation = await _client
        .from('activity_risk_assessments')
        .select('id')
        .eq('status', 'pending')
        .or('risk_level.eq.high,risk_level.eq.extreme');

    // Calculate counts
    final statusCounts = <String, int>{};
    final riskCounts = <String, int>{};
    final activityCounts = <String, int>{};

    for (final assessment in allAssessments) {
      final status = assessment['status'] as String;
      final riskLevel = assessment['risk_level'] as String;
      final activityType = assessment['activity_type'] as String;

      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      riskCounts[riskLevel] = (riskCounts[riskLevel] ?? 0) + 1;
      activityCounts[activityType] = (activityCounts[activityType] ?? 0) + 1;
    }

    return {
      'status_counts': statusCounts,
      'risk_counts': riskCounts,
      'activity_counts': activityCounts,
      'needing_review': needingReview.length,
      'needing_escalation': needingEscalation.length,
      'total_assessments': allAssessments.length,
    };
  }

  Future<List<Map<String, dynamic>>> getActivityTypeStats() async {
    final response = await _client.rpc('get_activity_risk_stats', params: {});
    return response;
  }

  Future<List<Map<String, dynamic>>> getRiskLevelStats() async {
    final response = await _client.rpc('get_risk_level_stats', params: {});
    return response;
  }

  // Helper methods
  String _activityTypeToString(ActivityType type) {
    switch (type) {
      case ActivityType.bathing: return 'bathing';
      case ActivityType.dressing: return 'dressing';
      case ActivityType.toileting: return 'toileting';
      case ActivityType.mobility: return 'mobility';
      case ActivityType.eating: return 'eating';
      case ActivityType.drinking: return 'drinking';
      case ActivityType.cooking: return 'cooking';
      case ActivityType.cleaning: return 'cleaning';
      case ActivityType.shopping: return 'shopping';
      case ActivityType.appointments: return 'appointments';
      case ActivityType.visits: return 'visits';
      case ActivityType.outings: return 'outings';
      case ActivityType.hobbies: return 'hobbies';
      case ActivityType.exercise: return 'exercise';
      case ActivityType.personalCare: return 'personal_care';
    }
  }

  ActivityType _stringToActivityType(String value) {
    return ActivityType.values.firstWhere(
      (type) => _activityTypeToString(type) == value,
      orElse: () => ActivityType.personalCare,
    );
  }
}