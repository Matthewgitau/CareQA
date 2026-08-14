import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/catheter_care_assessment.dart';
import 'package:supabase/supabase.dart';

class CatheterCareService {
  final SupabaseClient _client;

  CatheterCareService(this._client);

  // Create new catheter care assessment
  Future<String> createAssessment(CatheterCareAssessment assessment) async {
    try {
      final data = assessment.toMap();
      data.remove('id'); // Remove ID for insert, it will be auto-generated
      data.remove('created_at'); // Remove created_at for insert, it will be auto-generated
      data.remove('updated_at'); // Remove updated_at for insert, it will be auto-generated
      
      final response = await _client
          .from('catheter_care_risk_assessments')
          .insert(data)
          .select()
          .single();
      
      return response['id'] as String;
    } on PostgrestException catch (e) {
      throw Exception('Failed to create catheter care assessment: ${e.message}');
    }
  }

  // Update existing catheter care assessment
  Future<void> updateAssessment(CatheterCareAssessment assessment) async {
    try {
      final data = assessment.toMap();
      data.remove('id'); // Remove ID from update data
      data.remove('created_at'); // Remove created_at from update data
      
      await _client
          .from('catheter_care_risk_assessments')
          .update(data)
          .eq('id', assessment.id!);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update catheter care assessment: ${e.message}');
    }
  }

  // Get catheter care assessment by ID
  Future<CatheterCareAssessment?> getAssessmentById(String id) async {
    try {
      final response = await _client
          .from('catheter_care_risk_assessments')
          .select()
          .eq('id', id)
          .single();
      
      return CatheterCareAssessment.fromMap(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch catheter care assessment: ${e.message}');
    }
  }

  // Get all catheter care assessments for a service user
  Future<List<CatheterCareAssessment>> getAssessmentsByServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('catheter_care_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => CatheterCareAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch catheter care assessments: ${e.message}');
    }
  }

  // Submit catheter care assessment
  Future<void> submitAssessment(String assessmentId, String signature) async {
    try {
      await _client.rpc('submit_catheter_care_assessment', params: {
        'assessment_id': assessmentId,
        'signature_data': signature,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to submit catheter care assessment: ${e.message}');
    }
  }

  // Delete catheter care assessment
  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _client
          .from('catheter_care_risk_assessments')
          .delete()
          .eq('id', assessmentId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete catheter care assessment: ${e.message}');
    }
  }

  // Get catheter care assessment summary
  Future<Map<String, dynamic>> getAssessmentSummary(String serviceUserId) async {
    try {
      final data = await _client.rpc('get_catheter_care_assessment_summary', params: {
        'service_user_id_param': serviceUserId,
      });
      
      return data as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get catheter care assessment summary: ${e.message}');
    }
  }

  // Validate assessment completeness
  Future<Map<String, dynamic>> validateCompleteness(String assessmentId) async {
    try {
      final data = await _client.rpc('validate_catheter_care_assessment_completeness', params: {
        'assessment_id': assessmentId,
      });
      
      return data as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      throw Exception('Failed to validate catheter care assessment: ${e.message}');
    }
  }

  // Get assessments with infection risk
  Future<List<CatheterCareAssessment>> getInfectionRiskAssessments(String serviceUserId) async {
    try {
      final data = await _client
          .from('catheter_care_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .eq('infection_risk', true)
          .order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => CatheterCareAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch infection risk assessments: ${e.message}');
    }
  }

  // Get assessments with high risk levels for a specific service user
  Future<List<CatheterCareAssessment>> getHighRiskAssessmentsForUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('catheter_care_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .eq('overall_risk_level', 'high')
          .order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => CatheterCareAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch high risk assessments: ${e.message}');
    }
  }

  // Get assessments due for catheter change
  Future<List<CatheterCareAssessment>> getDueForChangeAssessments(String serviceUserId) async {
    try {
      final data = await _client
          .from('catheter_care_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .lte('next_change_date', DateTime.now().add(Duration(days: 7)).toIso8601String())
          .order('next_change_date', ascending: true);
      
      return (data as List)
          .map((item) => CatheterCareAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch assessments due for change: ${e.message}');
    }
  }

  // Get assessments requiring actions
  Future<List<CatheterCareAssessment>> getActionRequiredAssessments(String serviceUserId) async {
    try {
      final data = await _client
          .from('catheter_care_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .eq('actions_required', true)
          .order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => CatheterCareAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch action required assessments: ${e.message}');
    }
  }

  // Get latest assessment for a service user
  Future<CatheterCareAssessment?> getLatestAssessment(String serviceUserId) async {
    try {
      final data = await _client
          .from('catheter_care_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false)
          .limit(1);
      
      if (data.isEmpty) {
        return null;
      }
      
      return CatheterCareAssessment.fromMap(data.first as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch latest assessment: ${e.message}');
    }
  }

  // Get assessments by catheter type
  Future<List<CatheterCareAssessment>> getAssessmentsByCatheterType(String serviceUserId, String catheterType) async {
    try {
      final data = await _client
          .from('catheter_care_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .eq('catheter_type', catheterType)
          .order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => CatheterCareAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch assessments by catheter type: ${e.message}');
    }
  }

  // Get assessments by risk level
  Future<List<CatheterCareAssessment>> getAssessmentsByRiskLevel(String serviceUserId, String riskLevel) async {
    try {
      final data = await _client
          .from('catheter_care_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .eq('overall_risk_level', riskLevel)
          .order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => CatheterCareAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch assessments by risk level: ${e.message}');
    }
  }

  // Get assessments with specific infection signs
  Future<List<CatheterCareAssessment>> getAssessmentsWithInfectionSigns(String serviceUserId) async {
    try {
      final data = await _client
          .from('catheter_care_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .or('fever_present.eq.true,pain_present.eq.true,urine_odour_present.eq.true')
          .order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => CatheterCareAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch assessments with infection signs: ${e.message}');
    }
  }

  // Get upcoming catheter changes (across all service users)
  Future<List<Map<String, dynamic>>> getUpcomingChanges({int daysAhead = 7}) async {
    try {
      final data = await _client.rpc('get_upcoming_catheter_changes', params: {
        'days_ahead': daysAhead,
      });
      
      return (data as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get upcoming changes: ${e.message}');
    }
  }

  // Get high-risk assessments (across all service users)
  Future<List<Map<String, dynamic>>> getHighRiskAssessments() async {
    try {
      final data = await _client.rpc('flag_high_risk_catheter_assessments');
      
      return (data as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get high-risk assessments: ${e.message}');
    }
  }

  // Get assessments by monitoring frequency
  Future<List<CatheterCareAssessment>> getAssessmentsByMonitoringFrequency(String serviceUserId, String frequency) async {
    try {
      final data = await _client
          .from('catheter_care_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .eq('monitoring_frequency', frequency)
          .order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => CatheterCareAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch assessments by monitoring frequency: ${e.message}');
    }
  }

  // Get assessments by date range
  Future<List<CatheterCareAssessment>> getAssessmentsByDateRange(
    String serviceUserId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final data = await _client
          .from('catheter_care_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .gte('assessment_date', startDate.toIso8601String())
          .lte('assessment_date', endDate.toIso8601String())
          .order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => CatheterCareAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch assessments by date range: ${e.message}');
    }
  }
}