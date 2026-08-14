import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/coshh_risk_assessment.dart';
import 'package:supabase/supabase.dart';

class CoshhRiskService {
  final SupabaseClient _client;

  CoshhRiskService(this._client);

  // Create new COSHH assessment
  Future<String> createAssessment(CoshhRiskAssessment assessment) async {
    try {
      final data = assessment.toMap();
      data.remove('id'); // Remove ID for insert, it will be auto-generated
      data.remove('created_at'); // Remove created_at for insert, it will be auto-generated
      data.remove('updated_at'); // Remove updated_at for insert, it will be auto-generated
      
      final response = await _client
          .from('coshh_risk_assessments')
          .insert(data)
          .select()
          .single();
      
      return response['id'] as String;
    } on PostgrestException catch (e) {
      throw Exception('Failed to create COSHH assessment: ${e.message}');
    }
  }

  // Update existing COSHH assessment
  Future<void> updateAssessment(CoshhRiskAssessment assessment) async {
    try {
      final data = assessment.toMap();
      data.remove('id'); // Remove ID from update data
      data.remove('created_at'); // Remove created_at from update data
      
      await _client
          .from('coshh_risk_assessments')
          .update(data)
          .eq('id', assessment.id!);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update COSHH assessment: ${e.message}');
    }
  }

  // Get COSHH assessment by ID
  Future<CoshhRiskAssessment?> getAssessmentById(String id) async {
    try {
      final response = await _client
          .from('coshh_risk_assessments')
          .select()
          .eq('id', id)
          .single();
      
      return CoshhRiskAssessment.fromMap(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch COSHH assessment: ${e.message}');
    }
  }

  // Get all COSHH assessments for a service user
  Future<List<CoshhRiskAssessment>> getAssessmentsByServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('coshh_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => CoshhRiskAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch COSHH assessments: ${e.message}');
    }
  }

  // Submit COSHH assessment (mark as completed)
  Future<void> submitAssessment(String id, String signature) async {
    try {
      await _client
          .from('coshh_risk_assessments')
          .update({
            'status': 'completed',
            'assessor_signature': signature,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (error) {
      throw Exception('Failed to submit COSHH assessment: $error');
    }
  }

  // Delete COSHH assessment
  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _client
          .from('coshh_risk_assessments')
          .delete()
          .eq('id', assessmentId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete COSHH assessment: ${e.message}');
    }
  }

  // Get COSHH assessment summary
  Future<Map<String, dynamic>> getAssessmentSummary(String serviceUserId) async {
    try {
      final data = await _client.rpc('get_coshh_assessment_summary', params: {
        'service_user_id_param': serviceUserId,
      });
      
      return data as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get COSHH assessment summary: ${e.message}');
    }
  }

  // Validate assessment completeness
  Future<Map<String, dynamic>> validateCompleteness(String assessmentId) async {
    try {
      final data = await _client.rpc('validate_coshh_assessment_completeness', params: {
        'assessment_id': assessmentId,
      });
      
      return data as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      throw Exception('Failed to validate COSHH assessment: ${e.message}');
    }
  }

  // Get assessments with high risk levels
  Future<List<CoshhRiskAssessment>> getHighRiskAssessments(String serviceUserId) async {
    try {
      final data = await _client
          .from('coshh_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .eq('risk_level', 'High')
          .order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => CoshhRiskAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch high risk COSHH assessments: ${e.message}');
    }
  }

  // Get assessments requiring training
  Future<List<CoshhRiskAssessment>> getTrainingRequiredAssessments(String serviceUserId) async {
    try {
      final data = await _client
          .from('coshh_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .eq('training_required', true)
          .order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => CoshhRiskAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch training required COSHH assessments: ${e.message}');
    }
  }

  // Get latest assessment for a service user
  Future<CoshhRiskAssessment?> getLatestAssessment(String serviceUserId) async {
    try {
      final data = await _client
          .from('coshh_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false)
          .limit(1);
      
      if (data.isEmpty) {
        return null;
      }
      
      return CoshhRiskAssessment.fromMap(data.first as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch latest COSHH assessment: ${e.message}');
    }
  }

  // Search assessments by substance name
  Future<List<CoshhRiskAssessment>> searchAssessmentsBySubstance(String serviceUserId, String substanceName) async {
    try {
      final data = await _client
          .from('coshh_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .ilike('substance_name', '%$substanceName%')
          .order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => CoshhRiskAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to search COSHH assessments: ${e.message}');
    }
  }

  // Get assessments by risk level
  Future<List<CoshhRiskAssessment>> getAssessmentsByRiskLevel(String serviceUserId, String riskLevel) async {
    try {
      final data = await _client
          .from('coshh_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .eq('risk_level', riskLevel)
          .order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => CoshhRiskAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch COSHH assessments by risk level: ${e.message}');
    }
  }

  // Get assessments that can be eliminated
  Future<List<CoshhRiskAssessment>> getEliminableAssessments(String serviceUserId) async {
    try {
      final data = await _client
          .from('coshh_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .eq('can_be_eliminated', true)
          .order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => CoshhRiskAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch eliminable COSHH assessments: ${e.message}');
    }
  }
}