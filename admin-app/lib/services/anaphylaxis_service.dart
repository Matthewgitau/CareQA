import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase/supabase.dart';
import '../models/anaphylaxis_assessment.dart';

class AnaphylaxisService {
  final SupabaseClient _client;

  AnaphylaxisService(this._client);

  // Create a new anaphylaxis assessment
  Future<String> createAssessment(AnaphylaxisAssessment assessment) async {
    try {
      final data = assessment.toJson();
      data.remove('id'); // Remove ID for insert, it will be auto-generated
      data.remove('created_at'); // Remove created_at for insert, it will be auto-generated
      data.remove('updated_at'); // Remove updated_at for insert, it will be auto-generated
      data.remove('reviewed_at'); // Remove reviewed_at for insert
      data.remove('reviewed_by'); // Remove reviewed_by for insert
      
      final response = await _client
          .from('anaphylaxis_risk_assessments')
          .insert(data)
          .select()
          .single();
      
      return response['id'] as String;
    } on PostgrestException catch (e) {
      throw Exception('Failed to create anaphylaxis assessment: ${e.message}');
    }
  }

  // Update an existing anaphylaxis assessment
  Future<void> updateAssessment(AnaphylaxisAssessment assessment) async {
    try {
      final data = assessment.toJson();
      data.remove('id'); // Remove ID from update data
      data.remove('created_at'); // Remove created_at from update data
      data.remove('reviewed_at'); // Remove reviewed_at from update data
      data.remove('reviewed_by'); // Remove reviewed_by from update data
      
      await _client
          .from('anaphylaxis_risk_assessments')
          .update(data)
          .eq('id', assessment.id!);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update anaphylaxis assessment: ${e.message}');
    }
  }

  // Get a specific anaphylaxis assessment by ID
  Future<AnaphylaxisAssessment?> getAssessmentById(String assessmentId) async {
    try {
      final response = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .eq('id', assessmentId)
          .single();

      return AnaphylaxisAssessment.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get anaphylaxis assessment: ${e.message}');
    }
  }

  // Get all anaphylaxis assessments for a service user
  Future<List<AnaphylaxisAssessment>> getAssessmentsByServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get anaphylaxis assessments: ${e.message}');
    }
  }

  // Get latest assessment for a service user
  Future<AnaphylaxisAssessment?> getLatestAssessment(String serviceUserId) async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('created_at', ascending: false)
          .limit(1);

      if (data.isEmpty) return null;
      return AnaphylaxisAssessment.fromJson(data.first as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get latest anaphylaxis assessment: ${e.message}');
    }
  }

  // Get all anaphylaxis assessments for a care home
  Future<List<AnaphylaxisAssessment>> getAssessmentsByCareHome(String careHomeId) async {
    try {
      final data = await _client.rpc('get_anaphylaxis_assessments_by_carehome', params: {
        'p_carehome_id': careHomeId
      });

      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get anaphylaxis assessments by care home: ${e.message}');
    }
  }

  // Get high-risk anaphylaxis assessments
  Future<List<Map<String, dynamic>>> getHighRiskAssessments() async {
    try {
      final data = await _client.rpc('flag_high_risk_anaphylaxis_assessments');
      return (data as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get high-risk anaphylaxis assessments: ${e.message}');
    }
  }

  // Get anaphylaxis assessment summary for a service user
  Future<Map<String, dynamic>> getAssessmentSummary(String serviceUserId) async {
    try {
      final data = await _client.rpc('get_anaphylaxis_assessment_summary', params: {
        'p_service_user_id': serviceUserId
      });

      return data as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get anaphylaxis assessment summary: ${e.message}');
    }
  }

  // Validate assessment completeness
  Future<Map<String, dynamic>> validateAssessmentCompleteness(String assessmentId) async {
    try {
      final data = await _client.rpc('validate_anaphylaxis_assessment_completeness', params: {
        'p_assessment_id': assessmentId
      });

      return data as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      throw Exception('Failed to validate assessment completeness: ${e.message}');
    }
  }

  // Calculate risk level
  Future<String> calculateRiskLevel({
    required String previousSeverity,
    required bool autoinjectorPrescribed,
    required bool autoinjectorInDate,
    required bool emergencyPlan,
    required bool staffTrained,
    required bool allergyAlertVisible,
  }) async {
    try {
      final data = await _client.rpc('calculate_anaphylaxis_risk_level', params: {
        'p_previous_severity': previousSeverity,
        'p_autoinjector_prescribed': autoinjectorPrescribed,
        'p_autoinjector_in_date': autoinjectorInDate,
        'p_emergency_plan': emergencyPlan,
        'p_staff_trained': staffTrained,
        'p_allergy_alert_visible': allergyAlertVisible,
      });

      return data as String;
    } on PostgrestException catch (e) {
      throw Exception('Failed to calculate risk level: ${e.message}');
    }
  }

  // Submit assessment with digital signature and check for escalation
  Future<void> submitAssessment(String assessmentId, String signatureData) async {
    try {
      await _client.rpc('submit_anaphylaxis_assessment', params: {
        'p_assessment_id': assessmentId,
        'p_signature_data': signatureData,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to submit anaphylaxis assessment: ${e.message}');
    }
  }

  // Delete an assessment
  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _client
          .from('anaphylaxis_risk_assessments')
          .delete()
          .eq('id', assessmentId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete anaphylaxis assessment: ${e.message}');
    }
  }

  // Get assessments by status
  Future<List<AnaphylaxisAssessment>> getAssessmentsByStatus(String status) async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .eq('status', status)
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get anaphylaxis assessments by status: ${e.message}');
    }
  }

  // Get assessments due for review
  Future<List<AnaphylaxisAssessment>> getAssessmentsDueForReview() async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .lt('next_review_date', DateTime.now().toIso8601String())
          .order('next_review_date', ascending: true);

      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments due for review: ${e.message}');
    }
  }

  // Get assessments by risk level
  Future<List<AnaphylaxisAssessment>> getAssessmentsByRiskLevel(String riskLevel) async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .eq('risk_level', riskLevel)
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get anaphylaxis assessments by risk level: ${e.message}');
    }
  }

  // Get assessments with expired auto-injectors
  Future<List<AnaphylaxisAssessment>> getAssessmentsWithExpiredAutoinjectors() async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .eq('autoinjector_in_date', false)
          .eq('autoinjector_prescribed', true)
          .order('autoinjector_expiry_date', ascending: true);

      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with expired auto-injectors: ${e.message}');
    }
  }

  // Get assessments without emergency action plans
  Future<List<AnaphylaxisAssessment>> getAssessmentsWithoutActionPlans() async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .eq('emergency_action_plan', false)
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments without action plans: ${e.message}');
    }
  }

  // Get assessments with staff training expiring soon
  Future<List<AnaphylaxisAssessment>> getAssessmentsWithExpiringTraining() async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .lt('staff_training_expiry_date', DateTime.now().add(Duration(days: 30)).toIso8601String())
          .order('staff_training_expiry_date', ascending: true);

      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with expiring training: ${e.message}');
    }
  }

  // Get assessments with allergy specialist referrals
  Future<List<AnaphylaxisAssessment>> getAssessmentsWithSpecialistReferrals() async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .eq('allergy_specialist_referral', true)
          .order('last_appointment_date', ascending: false);

      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with specialist referrals: ${e.message}');
    }
  }

  // Get assessments by assessor
  Future<List<AnaphylaxisAssessment>> getAssessmentsByAssessor(String assessorId) async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .eq('assessor_id', assessorId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get anaphylaxis assessments by assessor: ${e.message}');
    }
  }

  // Get assessments by date range
  Future<List<AnaphylaxisAssessment>> getAssessmentsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get anaphylaxis assessments by date range: ${e.message}');
    }
  }

  // Get count of assessments by status
  Future<Map<String, int>> getAssessmentCountsByStatus() async {
    try {
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
        'extreme': 0
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessment counts by risk level: ${e.message}');
    }
  }

  // Get count of assessments by auto-injector status
  Future<Map<String, int>> getAssessmentCountsByAutoinjectorStatus() async {
    try {
      // For now, return a basic implementation
      return {
        'not_prescribed': 0,
        'current': 0,
        'expired': 0,
        'expiring_soon': 0
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessment counts by auto-injector status: ${e.message}');
    }
  }

  // Get count of assessments by emergency plan status
  Future<Map<String, int>> getAssessmentCountsByEmergencyPlanStatus() async {
    try {
      // For now, return a basic implementation
      return {
        'yes': 0,
        'no': 0
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessment counts by emergency plan status: ${e.message}');
    }
  }

  // Get dashboard view data
  Future<List<Map<String, dynamic>>> getDashboardData() async {
    try {
      final data = await _client
          .from('anaphylaxis_dashboard_view')
          .select();

      return (data as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get dashboard data: ${e.message}');
    }
  }
}