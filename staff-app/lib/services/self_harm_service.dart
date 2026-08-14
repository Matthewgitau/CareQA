import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase/supabase.dart';
import '../models/self_harm_assessment.dart';

class SelfHarmService {
  final SupabaseClient _client;

  SelfHarmService(this._client);

  // Create a new self-harm assessment
  Future<String> createAssessment(SelfHarmAssessment assessment) async {
    try {
      final data = assessment.toJson();
      data.remove('id'); // Remove ID for insert, it will be auto-generated
      data.remove('created_at'); // Remove created_at for insert, it will be auto-generated
      data.remove('updated_at'); // Remove updated_at for insert, it will be auto-generated
      
      final response = await _client
          .from('self_harm_risk_assessments')
          .insert(data)
          .select()
          .single();
      
      return response['id'] as String;
    } on PostgrestException catch (e) {
      throw Exception('Failed to create self-harm assessment: ${e.message}');
    }
  }

  // Update an existing self-harm assessment
  Future<void> updateAssessment(SelfHarmAssessment assessment) async {
    try {
      final data = assessment.toJson();
      data.remove('id'); // Remove ID from update data
      data.remove('created_at'); // Remove created_at from update data
      
      await _client
          .from('self_harm_risk_assessments')
          .update(data)
          .eq('id', assessment.id!);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update self-harm assessment: ${e.message}');
    }
  }

  // Get a specific self-harm assessment by ID
  Future<SelfHarmAssessment?> getAssessmentById(String assessmentId) async {
    try {
      final response = await _client
          .from('self_harm_risk_assessments')
          .select()
          .eq('id', assessmentId)
          .single();

      return SelfHarmAssessment.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get self-harm assessment: ${e.message}');
    }
  }

  // Get all self-harm assessments for a service user
  Future<List<SelfHarmAssessment>> getAssessmentsByServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('self_harm_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => SelfHarmAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get self-harm assessments: ${e.message}');
    }
  }

  // Get latest assessment for a service user
  Future<SelfHarmAssessment?> getLatestAssessment(String serviceUserId) async {
    try {
      final data = await _client
          .from('self_harm_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('created_at', ascending: false)
          .limit(1);

      if (data.isEmpty) return null;
      return SelfHarmAssessment.fromJson(data.first as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get latest self-harm assessment: ${e.message}');
    }
  }

  // Get all self-harm assessments for a care home
  Future<List<SelfHarmAssessment>> getAssessmentsByCareHome(String careHomeId) async {
    try {
      final data = await _client.rpc('get_self_harm_assessments_by_carehome', params: {
        'p_carehome_id': careHomeId
      });

      return (data as List)
          .map((item) => SelfHarmAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get self-harm assessments by care home: ${e.message}');
    }
  }

  // Get high-risk self-harm assessments
  Future<List<Map<String, dynamic>>> getHighRiskAssessments() async {
    try {
      final data = await _client.rpc('flag_high_risk_self_harm_assessments');
      return (data as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get high-risk self-harm assessments: ${e.message}');
    }
  }

  // Get self-harm assessment summary for a service user
  Future<Map<String, dynamic>> getAssessmentSummary(String serviceUserId) async {
    try {
      final data = await _client.rpc('get_self_harm_assessment_summary', params: {
        'p_service_user_id': serviceUserId
      });

      return data as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get self-harm assessment summary: ${e.message}');
    }
  }

  // Validate assessment completeness
  Future<Map<String, dynamic>> validateAssessmentCompleteness(String assessmentId) async {
    try {
      final data = await _client.rpc('validate_self_harm_assessment_completeness', params: {
        'p_assessment_id': assessmentId
      });

      return data as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      throw Exception('Failed to validate assessment completeness: ${e.message}');
    }
  }

  // Calculate risk level
  Future<String> calculateRiskLevel({
    required String currentIdeation,
    required bool methodPlanned,
    required bool givingAwayPossessions,
    required int previousAttempts,
    required bool accessToMeans,
  }) async {
    try {
      final data = await _client.rpc('calculate_self_harm_risk_level', params: {
        'p_current_ideation': currentIdeation,
        'p_method_planned': methodPlanned,
        'p_giving_away_possessions': givingAwayPossessions,
        'p_previous_attempts': previousAttempts,
        'p_access_to_means': accessToMeans,
      });

      return data as String;
    } on PostgrestException catch (e) {
      throw Exception('Failed to calculate risk level: ${e.message}');
    }
  }

  // Submit assessment with digital signature and check for escalation
  Future<void> submitAssessment(String assessmentId, String signatureData) async {
    try {
      await _client.rpc('submit_self_harm_assessment', params: {
        'p_assessment_id': assessmentId,
        'p_signature_data': signatureData,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to submit self-harm assessment: ${e.message}');
    }
  }

  // Delete an assessment
  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _client
          .from('self_harm_risk_assessments')
          .delete()
          .eq('id', assessmentId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete self-harm assessment: ${e.message}');
    }
  }

  // Get assessments by status
  Future<List<SelfHarmAssessment>> getAssessmentsByStatus(String status) async {
    try {
      final data = await _client
          .from('self_harm_risk_assessments')
          .select()
          .eq('status', status)
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => SelfHarmAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get self-harm assessments by status: ${e.message}');
    }
  }

  // Get assessments due for review
  Future<List<SelfHarmAssessment>> getAssessmentsDueForReview() async {
    try {
      final data = await _client
          .from('self_harm_risk_assessments')
          .select()
          .lt('next_review_date', DateTime.now().toIso8601String())
          .order('next_review_date', ascending: true);

      return (data as List)
          .map((item) => SelfHarmAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments due for review: ${e.message}');
    }
  }

  // Get assessments by risk level
  Future<List<SelfHarmAssessment>> getAssessmentsByRiskLevel(String riskLevel) async {
    try {
      final data = await _client
          .from('self_harm_risk_assessments')
          .select()
          .eq('overall_risk_level', riskLevel)
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => SelfHarmAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get self-harm assessments by risk level: ${e.message}');
    }
  }

  // Get assessments with immediate risk
  Future<List<SelfHarmAssessment>> getAssessmentsWithImmediateRisk() async {
    try {
      final data = await _client
          .from('self_harm_risk_assessments')
          .select()
          .eq('current_suicidal_ideation', 'constant')
          .or('method_planned.eq.true,giving_away_possessions.eq.true')
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => SelfHarmAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with immediate risk: ${e.message}');
    }
  }

  // Get assessments with previous self-harm attempts
  Future<List<SelfHarmAssessment>> getAssessmentsWithPreviousAttempts() async {
    try {
      final data = await _client
          .from('self_harm_risk_assessments')
          .select()
          .gt('previous_self_harm_attempts', 0)
          .order('previous_self_harm_attempts', ascending: false);

      return (data as List)
          .map((item) => SelfHarmAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with previous attempts: ${e.message}');
    }
  }

  // Get assessments with access to means
  Future<List<SelfHarmAssessment>> getAssessmentsWithAccessToMeans() async {
    try {
      final data = await _client
          .from('self_harm_risk_assessments')
          .select()
          .eq('access_to_means', true)
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => SelfHarmAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with access to means: ${e.message}');
    }
  }

  // Get assessments with substance use issues
  Future<List<SelfHarmAssessment>> getAssessmentsWithSubstanceUse() async {
    try {
      final data = await _client
          .from('self_harm_risk_assessments')
          .select()
          .filter('substance_use', 'in', '("regular","problematic")')
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => SelfHarmAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with substance use: ${e.message}');
    }
  }

  // Get assessments by assessor
  Future<List<SelfHarmAssessment>> getAssessmentsByAssessor(String assessorId) async {
    try {
      final data = await _client
          .from('self_harm_risk_assessments')
          .select()
          .eq('assessor_id', assessorId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => SelfHarmAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get self-harm assessments by assessor: ${e.message}');
    }
  }

  // Get assessments by date range
  Future<List<SelfHarmAssessment>> getAssessmentsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final data = await _client
          .from('self_harm_risk_assessments')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => SelfHarmAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get self-harm assessments by date range: ${e.message}');
    }
  }

  // Get count of assessments by status
  Future<Map<String, int>> getAssessmentCountsByStatus() async {
    try {
      final data = await _client.rpc('get_self_harm_assessment_summary', params: {
        'p_service_user_id': 'all' // This would need a separate function for all users
      });
      
      // For now, return a basic implementation
      return {
        'draft': 0,
        'completed': 0,
        'reviewed': 0,
        'escalated': 0
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessment counts by status: ${e.message}');
    }
  }

  // Get count of assessments by risk level
  Future<Map<String, int>> getAssessmentCountsByRiskLevel() async {
    try {
      // For now, return a basic implementation
      return {
        'low': 0,
        'medium': 0,
        'high': 0,
        'immediate': 0
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessment counts by risk level: ${e.message}');
    }
  }

  // Get count of assessments by current suicidal ideation
  Future<Map<String, int>> getAssessmentCountsByIdeation() async {
    try {
      // For now, return a basic implementation
      return {
        'never': 0,
        'sometimes': 0,
        'frequently': 0,
        'constant': 0
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessment counts by ideation: ${e.message}');
    }
  }
}