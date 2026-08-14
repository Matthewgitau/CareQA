import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/catheter_care_risk_assessment.dart';

class CatheterCareRiskService {
  final SupabaseClient _client;

  CatheterCareRiskService(this._client);

  // Create a new catheter care risk assessment
  Future<String> createAssessment(CatheterCareRiskAssessment assessment) async {
    try {
      final response = await _client
          .from('catheter_care_risk_assessments')
          .insert(assessment.toJson())
          .select('id')
          .single();

      return response['id'];
    } catch (e) {
      throw Exception('Failed to create catheter care assessment: $e');
    }
  }

  // Update an existing catheter care risk assessment
  Future<void> updateAssessment(CatheterCareRiskAssessment assessment) async {
    try {
      if (assessment.id == null) {
        throw Exception('Assessment ID cannot be null for update');
      }
      await _client
          .from('catheter_care_risk_assessments')
          .update(assessment.toJson())
          .eq('id', assessment.id!);
    } catch (e) {
      throw Exception('Failed to update catheter care assessment: $e');
    }
  }

  // Get a specific catheter care risk assessment by ID
  Future<CatheterCareRiskAssessment?> getAssessmentById(String assessmentId) async {
    try {
      final response = await _client
          .from('catheter_care_risk_assessments')
          .select('*')
          .eq('id', assessmentId)
          .single();

      return CatheterCareRiskAssessment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get catheter care assessment: $e');
    }
  }

  // Get all catheter care risk assessments for a service user
  Future<List<CatheterCareRiskAssessment>> getAssessmentsByServiceUser(String serviceUserId) async {
    try {
      final response = await _client
          .from('catheter_care_risk_assessments')
          .select('*')
          .eq('service_user_id', serviceUserId)
          .order('created_at', ascending: false);

      return response.map((json) => CatheterCareRiskAssessment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get catheter care assessments: $e');
    }
  }

  // Get latest assessment for a service user
  Future<CatheterCareRiskAssessment?> getLatestAssessment(String serviceUserId) async {
    try {
      final response = await _client
          .from('catheter_care_risk_assessments')
          .select('*')
          .eq('service_user_id', serviceUserId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) return null;
      return CatheterCareRiskAssessment.fromJson(response.first);
    } catch (e) {
      throw Exception('Failed to get latest catheter care assessment: $e');
    }
  }

  // Get high-risk catheter care assessments
  Future<List<CatheterCareRiskAssessment>> getHighRiskAssessments() async {
    try {
      final response = await _client
          .from('catheter_care_risk_assessments')
          .select('*')
          .filter('overall_risk_level', 'in', '("high","critical")')
          .order('created_at', ascending: false);

      return response.map((json) => CatheterCareRiskAssessment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get high-risk catheter care assessments: $e');
    }
  }

  // Delete an assessment
  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _client
          .from('catheter_care_risk_assessments')
          .delete()
          .eq('id', assessmentId);
    } catch (e) {
      throw Exception('Failed to delete catheter care assessment: $e');
    }
  }

  // Get assessments by risk level
  Future<List<CatheterCareRiskAssessment>> getAssessmentsByRiskLevel(String riskLevel) async {
    try {
      final response = await _client
          .from('catheter_care_risk_assessments')
          .select('*')
          .eq('overall_risk_level', riskLevel)
          .order('created_at', ascending: false);

      return response.map((json) => CatheterCareRiskAssessment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get assessments by risk level: $e');
    }
  }

  // Get assessments due for review
  Future<List<CatheterCareRiskAssessment>> getAssessmentsDueForReview() async {
    try {
      final response = await _client
          .from('catheter_care_risk_assessments')
          .select('*')
          .lt('review_date', DateTime.now().toIso8601String())
          .order('review_date', ascending: true);

      return response.map((json) => CatheterCareRiskAssessment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get assessments due for review: $e');
    }
  }

  // Get assessments with infection signs
  Future<List<CatheterCareRiskAssessment>> getAssessmentsWithInfectionSigns() async {
    try {
      final response = await _client
          .from('catheter_care_risk_assessments')
          .select('*')
          .filter('fever_celsius', 'gt', 37.5)
          .order('created_at', ascending: false);

      return response.map((json) => CatheterCareRiskAssessment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get assessments with infection signs: $e');
    }
  }

  // Get assessments by assessor
  Future<List<CatheterCareRiskAssessment>> getAssessmentsByAssessor(String assessorId) async {
    try {
      final response = await _client
          .from('catheter_care_risk_assessments')
          .select('*')
          .eq('assessor_id', assessorId)
          .order('created_at', ascending: false);

      return response.map((json) => CatheterCareRiskAssessment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get assessments by assessor: $e');
    }
  }

  // Get assessments by date range
  Future<List<CatheterCareRiskAssessment>> getAssessmentsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client
          .from('catheter_care_risk_assessments')
          .select('*')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      return response.map((json) => CatheterCareRiskAssessment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get assessments by date range: $e');
    }
  }
}