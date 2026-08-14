import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/falls_risk_assessment.dart';

class FallsRiskService {
  final SupabaseClient _client;

  FallsRiskService(this._client);

  // Create new assessment
  Future<String> createAssessment({
    required String serviceUserId,
    required String serviceUserName,
    required String assessorName,
    required DateTime dateOfBirth,
    required DateTime assessmentDate,
  }) async {
    try {
      final data = await _client.from('falls_risk_assessments').insert({
        'service_user_id': serviceUserId,
        'service_user_name': serviceUserName,
        'assessor_name': assessorName,
        'date_of_birth': dateOfBirth.toIso8601String(),
        'assessment_date': assessmentDate.toIso8601String(),
        'created_by': _client.auth.currentUser?.id,
        'status': 'draft',
      }).select().single();
      
      return data['id'] as String;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Update assessment scores
  Future<void> updateAssessmentScores({
    required String assessmentId,
    required int? ageScore,
    required int? fallHistoryScore,
    required int? eliminationScore,
    required int? medicationScore,
    required int? equipmentScore,
    required int? mobilityScore,
    required int? cognitionScore,
  }) async {
    try {
      await _client.from('falls_risk_assessments').update({
        'age_score': ageScore,
        'fall_history_score': fallHistoryScore,
        'elimination_score': eliminationScore,
        'medication_score': medicationScore,
        'equipment_score': equipmentScore,
        'mobility_score': mobilityScore,
        'cognition_score': cognitionScore,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', assessmentId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Add action plan
  Future<void> addActionPlan({
    required String assessmentId,
    required String action,
    String? outcome,
  }) async {
    try {
      await _client.from('falls_action_plans').insert({
        'falls_assessment_id': assessmentId,
        'action': action,
        'outcome': outcome,
      });
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Update action plan
  Future<void> updateActionPlan({
    required String actionPlanId,
    required String action,
    String? outcome,
    bool? completed,
  }) async {
    final updateData = {
      'action': action,
      'outcome': outcome,
    };
    
    if (completed != null) {
      updateData['completed'] = completed;
      if (completed) {
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }
    }
    
    try {
      await _client.from('falls_action_plans').update(updateData)
          .eq('id', actionPlanId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Delete action plan
  Future<void> deleteActionPlan(String actionPlanId) async {
    try {
      await _client.from('falls_action_plans').delete()
          .eq('id', actionPlanId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Complete assessment with verification
  Future<void> completeAssessment({
    required String assessmentId,
    required String verifiedByName,
    required String signatureData,
  }) async {
    try {
      await _client.from('falls_risk_assessments').update({
        'verified_by': verifiedByName,
        'signature_data': signatureData,
        'verification_date': DateTime.now().toIso8601String(),
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', assessmentId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get assessment with action plans
  Future<FallsRiskAssessment> getAssessmentWithActionPlans(String assessmentId) async {
    try {
      final data = await _client.rpc('get_falls_assessment_with_action_plans', params: {
        'assessment_id': assessmentId,
      });
      
      final assessmentData = data['assessment_data'] as Map<String, dynamic>;
      final actionPlansData = data['action_plans_data'] as List<dynamic>;
      
      return FallsRiskAssessment.fromAssessmentWithActionPlans(
        assessmentData,
        actionPlansData.cast<Map<String, dynamic>>(),
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get assessment summary
  Future<FallsRiskSummary?> getAssessmentSummary(String assessmentId) async {
    try {
      final data = await _client.rpc('get_falls_risk_summary', params: {
        'assessment_id': assessmentId,
      });
      
      if (data == null) {
        return null;
      }
      
      return FallsRiskSummary.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      print('Error fetching assessment summary: ${e.message}');
      return null;
    }
  }

  // Validate assessment completeness
  Future<FallsRiskValidation> validateAssessmentCompleteness(String assessmentId) async {
    try {
      final data = await _client.rpc('validate_falls_risk_completeness', params: {
        'assessment_id': assessmentId,
      });
      
      return FallsRiskValidation.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Submit assessment
  Future<bool> submitAssessment(String assessmentId, String verifiedByName, String signatureData) async {
    try {
      final data = await _client.rpc('submit_falls_risk_assessment', params: {
        'assessment_id': assessmentId,
        'verified_by_name': verifiedByName,
        'signature_data': signatureData,
      });
      
      return data as bool;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get assessments for service user
  Future<List<FallsRiskHistoryItem>> getAssessmentsForServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('falls_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => FallsRiskHistoryItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<FallsRiskHistoryItem>> getAssessmentsForServiceUserOnce(String serviceUserId) async {
    try {
      final data = await _client
          .from('falls_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => FallsRiskHistoryItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get latest assessment for service user
  Future<FallsRiskAssessment?> getLatestAssessment(String serviceUserId) async {
    try {
      final data = await _client
          .from('falls_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false)
          .limit(1)
          .single();
      
      return getAssessmentWithActionPlans(data['id'] as String);
    } on PostgrestException catch (_) {
      return null;
    }
  }

  // Search assessments
  Future<List<FallsRiskHistoryItem>> searchAssessments({
    String? serviceUserName,
    String? assessorName,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? riskLevel,
    String? status,
  }) async {
    var query = _client.from('falls_risk_assessments').select();

    if (serviceUserName != null && serviceUserName.isNotEmpty) {
      query = query.ilike('service_user_name', '%$serviceUserName%');
    }

    if (assessorName != null && assessorName.isNotEmpty) {
      query = query.ilike('assessor_name', '%$assessorName%');
    }

    if (riskLevel != null) {
      query = query.eq('risk_level', riskLevel);
    }

    if (status != null) {
      query = query.eq('status', status);
    }

    if (dateFrom != null) {
      query = query.gte('assessment_date', dateFrom.toIso8601String());
    }

    if (dateTo != null) {
      query = query.lte('assessment_date', dateTo.toIso8601String());
    }

    try {
      final data = await query.order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => FallsRiskHistoryItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Delete assessment
  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _client
          .from('falls_risk_assessments')
          .delete()
          .eq('id', assessmentId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Calculate age-based score
  int calculateAgeScore(DateTime dateOfBirth) {
    final age = DateTime.now().year - dateOfBirth.year;
    if (age >= 80) return 3;
    if (age >= 70) return 2;
    if (age >= 60) return 1;
    return 0;
  }

  // Get scoring options for each category
  List<AgeScoreOption> getAgeScoreOptions() {
    return [
      AgeScoreOption('60-69 years', 1, '1 point'),
      AgeScoreOption('70-79 years', 2, '2 points'),
      AgeScoreOption('80+ years', 3, '3 points'),
      AgeScoreOption('Under 60 years', 0, '0 points'),
    ];
  }

  List<FallHistoryScoreOption> getFallHistoryScoreOptions() {
    return [
      FallHistoryScoreOption('One fall in 6 months', 5, '5 points'),
      FallHistoryScoreOption('No falls in 6 months', 0, '0 points'),
    ];
  }

  List<EliminationScoreOption> getEliminationScoreOptions() {
    return [
      EliminationScoreOption('Incontinence', 2, '2 points'),
      EliminationScoreOption('Urgency', 2, '2 points'),
      EliminationScoreOption('Both incontinence and urgency', 4, '4 points'),
      EliminationScoreOption('No elimination issues', 0, '0 points'),
    ];
  }

  List<MedicationScoreOption> getMedicationScoreOptions() {
    return [
      MedicationScoreOption('1 high-risk drug', 3, '3 points'),
      MedicationScoreOption('2+ high-risk drugs', 5, '5 points'),
      MedicationScoreOption('Sedation', 7, '7 points'),
      MedicationScoreOption('No high-risk medications', 0, '0 points'),
    ];
  }

  List<EquipmentScoreOption> getEquipmentScoreOptions() {
    return [
      EquipmentScoreOption('1 item of patient care equipment', 1, '1 point'),
      EquipmentScoreOption('2 items of patient care equipment', 2, '2 points'),
      EquipmentScoreOption('3+ items of patient care equipment', 3, '3 points'),
      EquipmentScoreOption('No patient care equipment', 0, '0 points'),
    ];
  }

  List<MobilityScoreOption> getMobilityScoreOptions() {
    return [
      MobilityScoreOption('Requires assistance to mobilize', 2, '2 points'),
      MobilityScoreOption('Unsteady gait', 2, '2 points'),
      MobilityScoreOption('Visual impairment', 2, '2 points'),
      MobilityScoreOption('Requires equipment to mobilize', 3, '3 points'),
      MobilityScoreOption('Bed care only', 7, '7 points'),
      MobilityScoreOption('No mobility issues', 0, '0 points'),
    ];
  }

  List<CognitionScoreOption> getCognitionScoreOptions() {
    return [
      CognitionScoreOption('Altered awareness', 1, '1 point'),
      CognitionScoreOption('Impulsive behavior', 2, '2 points'),
      CognitionScoreOption('Lack of understanding of own safety', 4, '4 points'),
      CognitionScoreOption('No cognitive issues', 0, '0 points'),
    ];
  }
}