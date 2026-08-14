import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/epilepsy_assessment.dart';
import 'package:supabase/supabase.dart';

class EpilepsyService {
  final SupabaseClient _client;

  EpilepsyService(this._client);

  // Create new epilepsy assessment
  Future<String> createAssessment(EpilepsyAssessment assessment) async {
    try {
      final data = assessment.toMap();
      data.remove('id'); // Remove ID for insert, it will be auto-generated
      data.remove('created_at'); // Remove created_at for insert, it will be auto-generated
      data.remove('updated_at'); // Remove updated_at for insert, it will be auto-generated
      
      final response = await _client
          .from('epilepsy_risk_assessments')
          .insert(data)
          .select()
          .single();
      
      return response['id'] as String;
    } on PostgrestException catch (e) {
      throw Exception('Failed to create epilepsy assessment: ${e.message}');
    }
  }

  // Update existing epilepsy assessment
  Future<void> updateAssessment(EpilepsyAssessment assessment) async {
    try {
      final data = assessment.toMap();
      data.remove('id'); // Remove ID from update data
      data.remove('created_at'); // Remove created_at from update data
      
      await _client
          .from('epilepsy_risk_assessments')
          .update(data)
          .eq('id', assessment.id!);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update epilepsy assessment: ${e.message}');
    }
  }

  // Get epilepsy assessment by ID
  Future<EpilepsyAssessment?> getAssessmentById(String id) async {
    try {
      final response = await _client
          .from('epilepsy_risk_assessments')
          .select()
          .eq('id', id)
          .single();
      
      return EpilepsyAssessment.fromMap(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch epilepsy assessment: ${e.message}');
    }
  }

  // Get all epilepsy assessments for a service user
  Future<List<EpilepsyAssessment>> getAssessmentsByServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('epilepsy_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => EpilepsyAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch epilepsy assessments: ${e.message}');
    }
  }

  // Submit epilepsy assessment
  Future<void> submitAssessment(String assessmentId, String signature) async {
    try {
      await _client.rpc('submit_epilepsy_assessment', params: {
        'assessment_id': assessmentId,
        'signature_data': signature,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to submit epilepsy assessment: ${e.message}');
    }
  }

  // Delete epilepsy assessment
  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _client
          .from('epilepsy_risk_assessments')
          .delete()
          .eq('id', assessmentId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete epilepsy assessment: ${e.message}');
    }
  }

  // Get epilepsy assessment summary
  Future<Map<String, dynamic>> getAssessmentSummary(String serviceUserId) async {
    try {
      final data = await _client.rpc('get_epilepsy_assessment_summary', params: {
        'p_service_user_id': serviceUserId,
      });
      
      return data as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get epilepsy assessment summary: ${e.message}');
    }
  }

  // Validate assessment completeness
  Future<Map<String, dynamic>> validateCompleteness(String assessmentId) async {
    try {
      final data = await _client.rpc('validate_epilepsy_assessment_completeness', params: {
        'p_assessment_id': assessmentId,
      });
      
      return data as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      throw Exception('Failed to validate epilepsy assessment: ${e.message}');
    }
  }

  // Get high-risk epilepsy assessments
  Future<List<Map<String, dynamic>>> getHighRiskAssessments() async {
    try {
      final data = await _client.rpc('flag_high_risk_epilepsy_assessments');
      
      return (data as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get high-risk epilepsy assessments: ${e.message}');
    }
  }

  // Get assessments by seizure frequency
  Future<List<EpilepsyAssessment>> getAssessmentsByFrequency(String serviceUserId, String frequency) async {
    try {
      final data = await _client
          .from('epilepsy_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .eq('seizure_frequency', frequency)
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => EpilepsyAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch assessments by frequency: ${e.message}');
    }
  }

  // Get assessments by seizure type
  Future<List<EpilepsyAssessment>> getAssessmentsByType(String serviceUserId, String seizureType) async {
    try {
      final data = await _client
          .from('epilepsy_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .eq('seizure_type', seizureType)
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => EpilepsyAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch assessments by seizure type: ${e.message}');
    }
  }

  // Get assessments with medication compliance issues
  Future<List<EpilepsyAssessment>> getNonCompliantAssessments(String serviceUserId) async {
    try {
      final data = await _client
          .from('epilepsy_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .eq('medication_compliance', false)
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => EpilepsyAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch non-compliant assessments: ${e.message}');
    }
  }

  // Get assessments with safeguarding concerns
  Future<List<EpilepsyAssessment>> getSafeguardingConcernsAssessments(String serviceUserId) async {
    try {
      final data = await _client
          .from('epilepsy_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .eq('safeguarding_concerns', true)
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => EpilepsyAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch safeguarding concerns assessments: ${e.message}');
    }
  }

  // Get assessments requiring review
  Future<List<EpilepsyAssessment>> getReviewRequiredAssessments(String serviceUserId) async {
    try {
      final data = await _client
          .from('epilepsy_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .lt('next_review_date', DateTime.now().toIso8601String())
          .order('next_review_date', ascending: true);
      
      return (data as List)
          .map((item) => EpilepsyAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch review required assessments: ${e.message}');
    }
  }

  // Get assessments with rescue medication
  Future<List<EpilepsyAssessment>> getRescueMedicationAssessments(String serviceUserId) async {
    try {
      final data = await _client
          .from('epilepsy_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .not('rescue_medication_name', 'is', null)
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => EpilepsyAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch rescue medication assessments: ${e.message}');
    }
  }

  // Get latest assessment for a service user
  Future<EpilepsyAssessment?> getLatestAssessment(String serviceUserId) async {
    try {
      final data = await _client
          .from('epilepsy_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('created_at', ascending: false)
          .limit(1);
      
      if (data.isEmpty) {
        return null;
      }
      
      return EpilepsyAssessment.fromMap(data.first as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch latest assessment: ${e.message}');
    }
  }

  // Get assessments by risk level
  Future<List<EpilepsyAssessment>> getAssessmentsByRiskLevel(String serviceUserId, String riskLevel) async {
    try {
      final data = await _client
          .from('epilepsy_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .eq('overall_risk_level', riskLevel)
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => EpilepsyAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch assessments by risk level: ${e.message}');
    }
  }

  // Get assessments by date range
  Future<List<EpilepsyAssessment>> getAssessmentsByDateRange(
    String serviceUserId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final data = await _client
          .from('epilepsy_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => EpilepsyAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch assessments by date range: ${e.message}');
    }
  }

  // Get assessments with specific triggers
  Future<List<EpilepsyAssessment>> getAssessmentsByTriggers(String serviceUserId, List<String> triggers) async {
    try {
      final data = await _client
          .from('epilepsy_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .contains('seizure_triggers', triggers)
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => EpilepsyAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch assessments by triggers: ${e.message}');
    }
  }

  // Get assessments with specific injury risk factors
  Future<List<EpilepsyAssessment>> getAssessmentsByInjuryRisks(String serviceUserId, List<String> injuryRisks) async {
    try {
      final data = await _client
          .from('epilepsy_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .contains('injury_risk_factors', injuryRisks)
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => EpilepsyAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch assessments by injury risks: ${e.message}');
    }
  }

  // Calculate risk level for an assessment
  Future<String> calculateRiskLevel({
    required String seizureFrequency,
    required List<String>? seizureTriggers,
    required bool medicationCompliance,
    required List<String>? injuryRiskFactors,
    required bool safeguardingConcerns,
  }) async {
    try {
      final data = await _client.rpc('calculate_epilepsy_risk_level', params: {
        'p_seizure_frequency': seizureFrequency,
        'p_seizure_triggers': seizureTriggers,
        'p_medication_compliance': medicationCompliance,
        'p_injury_risk_factors': injuryRiskFactors,
        'p_safeguarding_concerns': safeguardingConcerns,
      });
      
      return data as String;
    } on PostgrestException catch (e) {
      throw Exception('Failed to calculate risk level: ${e.message}');
    }
  }

  // Get assessments with unwitnessed seizure locations
  Future<List<EpilepsyAssessment>> getUnwitnessedSeizureAssessments(String serviceUserId) async {
    try {
      final data = await _client
          .from('epilepsy_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .not('unwitnessed_seizure_locations', 'is', null)
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => EpilepsyAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch unwitnessed seizure assessments: ${e.message}');
    }
  }
}