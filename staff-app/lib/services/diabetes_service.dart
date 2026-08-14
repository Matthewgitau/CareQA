import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/diabetes_assessment.dart';

class DiabetesService {
  final SupabaseClient _client;

  DiabetesService(this._client);

  // Create a new diabetes assessment
  Future<String> createAssessment(DiabetesAssessment assessment) async {
    try {
      final response = await _client
          .from('diabetes_risk_assessments')
          .insert(assessment.toJson())
          .select('id')
          .single();

      return response['id'];
    } catch (e) {
      throw Exception('Failed to create diabetes assessment: $e');
    }
  }

  // Update an existing diabetes assessment
  Future<void> updateAssessment(DiabetesAssessment assessment) async {
    try {
      await _client
          .from('diabetes_risk_assessments')
          .eq('id', assessment.id)
          .update(assessment.toJson());
    } catch (e) {
      throw Exception('Failed to update diabetes assessment: $e');
    }
  }

  // Get a specific diabetes assessment by ID
  Future<DiabetesAssessment?> getAssessmentById(String assessmentId) async {
    try {
      final response = await _client
          .from('diabetes_risk_assessments')
          .select('*')
          .eq('id', assessmentId)
          .single();

      return DiabetesAssessment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get diabetes assessment: $e');
    }
  }

  // Get all diabetes assessments for a service user
  Future<List<DiabetesAssessment>> getAssessmentsByServiceUser(String serviceUserId) async {
    try {
      final response = await _client
          .from('diabetes_risk_assessments')
          .select('*')
          .eq('service_user_id', serviceUserId)
          .order('created_at', ascending: false);

      return response.map((json) => DiabetesAssessment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get diabetes assessments: $e');
    }
  }

  // Get latest assessment for a service user
  Future<DiabetesAssessment?> getLatestAssessment(String serviceUserId) async {
    try {
      final response = await _client
          .from('diabetes_risk_assessments')
          .select('*')
          .eq('service_user_id', serviceUserId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) return null;
      return DiabetesAssessment.fromJson(response.first);
    } catch (e) {
      throw Exception('Failed to get latest diabetes assessment: $e');
    }
  }

  // Get all diabetes assessments for a care home
  Future<List<DiabetesAssessment>> getAssessmentsByCareHome(String careHomeId) async {
    try {
      final response = await _client.rpc('get_diabetes_assessments_by_carehome', params: {
        'p_carehome_id': careHomeId
      });

      return response.map((json) => DiabetesAssessment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get diabetes assessments by care home: $e');
    }
  }

  // Get high-risk diabetes assessments
  Future<List<Map<String, dynamic>>> getHighRiskAssessments() async {
    try {
      final response = await _client.rpc('flag_high_risk_diabetes_assessments');
      return response;
    } catch (e) {
      throw Exception('Failed to get high-risk diabetes assessments: $e');
    }
  }

  // Get diabetes assessment summary for a service user
  Future<Map<String, dynamic>> getAssessmentSummary(String serviceUserId) async {
    try {
      final response = await _client.rpc('get_diabetes_assessment_summary', params: {
        'p_service_user_id': serviceUserId
      });

      return response;
    } catch (e) {
      throw Exception('Failed to get diabetes assessment summary: $e');
    }
  }

  // Validate assessment completeness
  Future<Map<String, dynamic>> validateAssessmentCompleteness(String assessmentId) async {
    try {
      final response = await _client.rpc('validate_diabetes_assessment_completeness', params: {
        'p_assessment_id': assessmentId
      });

      return response;
    } catch (e) {
      throw Exception('Failed to validate assessment completeness: $e');
    }
  }

  // Calculate insulin dose (for Type 1 diabetes)
  Future<Map<String, dynamic>> calculateInsulinDose({
    required double totalDailyDose,
    required double carbRatio,
    required double correctionFactor,
    required double currentBg,
    required double targetBg,
    required double carbsToEat,
  }) async {
    try {
      final response = await _client.rpc('calculate_insulin_dose', params: {
        'p_total_daily_dose': totalDailyDose,
        'p_carb_ratio': carbRatio,
        'p_correction_factor': correctionFactor,
        'p_current_bg': currentBg,
        'p_target_bg': targetBg,
        'p_carbs_to_eat': carbsToEat,
      });

      return response;
    } catch (e) {
      throw Exception('Failed to calculate insulin dose: $e');
    }
  }

  // Submit assessment with digital signature
  Future<void> submitAssessment(String assessmentId, String signatureData) async {
    try {
      await _client.rpc('submit_diabetes_assessment', params: {
        'p_assessment_id': assessmentId,
        'p_signature_data': signatureData,
      });
    } catch (e) {
      throw Exception('Failed to submit diabetes assessment: $e');
    }
  }

  // Delete an assessment
  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _client
          .from('diabetes_risk_assessments')
          .eq('id', assessmentId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete diabetes assessment: $e');
    }
  }

  // Get assessments by status
  Future<List<DiabetesAssessment>> getAssessmentsByStatus(String status) async {
    try {
      final response = await _client
          .from('diabetes_risk_assessments')
          .select('*')
          .eq('status', status)
          .order('created_at', ascending: false);

      return response.map((json) => DiabetesAssessment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get diabetes assessments by status: $e');
    }
  }

  // Get assessments due for review
  Future<List<DiabetesAssessment>> getAssessmentsDueForReview() async {
    try {
      final response = await _client
          .from('diabetes_risk_assessments')
          .select('*')
          .lt('next_review_date', DateTime.now().toIso8601String())
          .order('next_review_date', ascending: true);

      return response.map((json) => DiabetesAssessment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get assessments due for review: $e');
    }
  }

  // Get assessments by risk level
  Future<List<DiabetesAssessment>> getAssessmentsByRiskLevel(String riskLevel) async {
    try {
      final response = await _client
          .from('diabetes_risk_assessments')
          .select('*')
          .eq('overall_risk_level', riskLevel)
          .order('created_at', ascending: false);

      return response.map((json) => DiabetesAssessment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get assessments by risk level: $e');
    }
  }

  // Get assessments by diabetes type
  Future<List<DiabetesAssessment>> getAssessmentsByDiabetesType(String diabetesType) async {
    try {
      final response = await _client
          .from('diabetes_risk_assessments')
          .select('*')
          .eq('diabetes_type', diabetesType)
          .order('created_at', ascending: false);

      return response.map((json) => DiabetesAssessment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get assessments by diabetes type: $e');
    }
  }

  // Get assessments with high HbA1c (>58)
  Future<List<DiabetesAssessment>> getAssessmentsWithHighHba1c() async {
    try {
      final response = await _client
          .from('diabetes_risk_assessments')
          .select('*')
          .gt('last_hba1c_value', 58.0)
          .order('last_hba1c_value', ascending: false);

      return response.map((json) => DiabetesAssessment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get assessments with high HbA1c: $e');
    }
  }

  // Get assessments with frequent hypoglycaemia
  Future<List<DiabetesAssessment>> getAssessmentsWithFrequentHypoglycaemia() async {
    try {
      final response = await _client
          .from('diabetes_risk_assessments')
          .select('*')
          .filter('hypoglycaemia_frequency', 'in', '("daily","multiple_daily")')
          .order('created_at', ascending: false);

      return response.map((json) => DiabetesAssessment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get assessments with frequent hypoglycaemia: $e');
    }
  }

  // Get assessments with foot complications
  Future<List<DiabetesAssessment>> getAssessmentsWithFootComplications() async {
    try {
      final response = await _client
          .from('diabetes_risk_assessments')
          .select('*')
          .filter('foot_care_assessment_result', 'in', '("reduced_sensation","ulceration","amputation")')
          .order('created_at', ascending: false);

      return response.map((json) => DiabetesAssessment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get assessments with foot complications: $e');
    }
  }

  // Get assessments with eye complications
  Future<List<DiabetesAssessment>> getAssessmentsWithEyeComplications() async {
    try {
      final response = await _client
          .from('diabetes_risk_assessments')
          .select('*')
          .filter('eye_screening_result', 'in', '("preproliferative","proliferative","maculopathy")')
          .order('created_at', ascending: false);

      return response.map((json) => DiabetesAssessment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get assessments with eye complications: $e');
    }
  }

  // Get assessments with frequent hospital admissions
  Future<List<DiabetesAssessment>> getAssessmentsWithFrequentHospitalAdmissions() async {
    try {
      final response = await _client
          .from('diabetes_risk_assessments')
          .select('*')
          .gt('hospital_admissions_last_year', 2)
          .order('hospital_admissions_last_year', ascending: false);

      return response.map((json) => DiabetesAssessment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get assessments with frequent hospital admissions: $e');
    }
  }

  // Get assessments by assessor
  Future<List<DiabetesAssessment>> getAssessmentsByAssessor(String assessorId) async {
    try {
      final response = await _client
          .from('diabetes_risk_assessments')
          .select('*')
          .eq('assessor_id', assessorId)
          .order('created_at', ascending: false);

      return response.map((json) => DiabetesAssessment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get assessments by assessor: $e');
    }
  }

  // Get assessments by date range
  Future<List<DiabetesAssessment>> getAssessmentsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client
          .from('diabetes_risk_assessments')
          .select('*')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      return response.map((json) => DiabetesAssessment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get assessments by date range: $e');
    }
  }

  // Get count of assessments by status
  Future<Map<String, int>> getAssessmentCountsByStatus() async {
    try {
      final response = await _client
          .from('diabetes_risk_assessments')
          .select('status', count: CountOption.exact)
          .group('status');

      final counts = <String, int>{};
      for (final row in response) {
        counts[row['status']] = row['count'];
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to get assessment counts by status: $e');
    }
  }

  // Get count of assessments by risk level
  Future<Map<String, int>> getAssessmentCountsByRiskLevel() async {
    try {
      final response = await _client
          .from('diabetes_risk_assessments')
          .select('overall_risk_level', count: CountOption.exact)
          .group('overall_risk_level');

      final counts = <String, int>{};
      for (final row in response) {
        counts[row['overall_risk_level']] = row['count'];
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to get assessment counts by risk level: $e');
    }
  }

  // Get count of assessments by diabetes type
  Future<Map<String, int>> getAssessmentCountsByDiabetesType() async {
    try {
      final response = await _client
          .from('diabetes_risk_assessments')
          .select('diabetes_type', count: CountOption.exact)
          .group('diabetes_type');

      final counts = <String, int>{};
      for (final row in response) {
        counts[row['diabetes_type']] = row['count'];
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to get assessment counts by diabetes type: $e');
    }
  }

  // Stream assessments for real-time updates
  Stream<List<DiabetesAssessment>> streamAssessmentsByServiceUser(String serviceUserId) {
    return _client
        .from('diabetes_risk_assessments')
        .select('*')
        .eq('service_user_id', serviceUserId)
        .order('created_at', ascending: false)
        .stream()
        .map((responses) => responses.map((json) => DiabetesAssessment.fromJson(json)).toList());
  }

  // Stream all assessments for a care home
  Stream<List<DiabetesAssessment>> streamAssessmentsByCareHome(String careHomeId) {
    return _client
        .rpc('get_diabetes_assessments_by_carehome', params: {
          'p_carehome_id': careHomeId
        })
        .stream()
        .map((responses) => responses.map((json) => DiabetesAssessment.fromJson(json)).toList());
  }
}