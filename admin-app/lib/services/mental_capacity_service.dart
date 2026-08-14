import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/mental_capacity_assessment.dart';

class MentalCapacityService {
  final SupabaseClient _client;

  MentalCapacityService(this._client);

  // Mental Capacity Assessments
  Future<List<MentalCapacityAssessment>> getMentalCapacityAssessmentsByServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('mental_capacity_assessments')
          .select('*, profiles(full_name)')
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false);
      return (data as List).map((a) => MentalCapacityAssessment.fromMap(a as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<MentalCapacityAssessment> createMentalCapacityAssessment(
    String serviceUserId,
    String assessorId,
    DateTime assessmentDate,
    Map<String, dynamic> functionalTest,
    Map<String, dynamic> twoStageTest,
    Map<String, dynamic> bestInterests,
    Map<String, dynamic> imcaReferral,
    String? signature,
  ) async {
    final capacityLevel = _determineCapacityLevel(functionalTest, twoStageTest);

    try {
      final data = await _client
          .from('mental_capacity_assessments')
          .insert({
            'service_user_id': serviceUserId,
            'assessor_id': assessorId,
            'assessment_date': assessmentDate,
            'functional_test': functionalTest,
            'two_stage_test': twoStageTest,
            'best_interests': bestInterests,
            'imca_referral': imcaReferral,
            'signature': signature,
            'status': 'completed',
            'capacity_level': capacityLevel,
          })
          .select()
          .single();
      
      return MentalCapacityAssessment.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Error creating mental capacity assessment: ${e.message}');
    }
  }

  Future<void> updateMentalCapacityAssessment(
    String assessmentId,
    Map<String, dynamic> functionalTest,
    Map<String, dynamic> twoStageTest,
    Map<String, dynamic> bestInterests,
    Map<String, dynamic> imcaReferral,
    String? signature,
  ) async {
    final capacityLevel = _determineCapacityLevel(functionalTest, twoStageTest);

    try {
      await _client
          .from('mental_capacity_assessments')
          .update({
            'functional_test': functionalTest,
            'two_stage_test': twoStageTest,
            'best_interests': bestInterests,
            'imca_referral': imcaReferral,
            'signature': signature,
            'status': 'completed',
            'capacity_level': capacityLevel,
            'updated_at': DateTime.now(),
          })
          .eq('id', assessmentId);
    } on PostgrestException catch (e) {
      throw Exception('Error updating mental capacity assessment: ${e.message}');
    }
  }

  Future<MentalCapacityAssessment> getMentalCapacityAssessment(String assessmentId) async {
    try {
      final data = await _client
          .from('mental_capacity_assessments')
          .select()
          .eq('id', assessmentId)
          .single();
      
      return MentalCapacityAssessment.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Error fetching mental capacity assessment: ${e.message}');
    }
  }

  Future<void> generateMentalCapacityPdf(String assessmentId) async {
    try {
      await _client.rpc('generate_mental_capacity_pdf_url', params: {
        'assessment_id': assessmentId,
      });
    } on PostgrestException catch (e) {
      throw Exception('Error generating PDF: ${e.message}');
    }
  }

  // Mental Capacity Summary
  Future<MentalCapacitySummary?> getMentalCapacitySummary(String serviceUserId) async {
    try {
      final data = await _client.rpc('get_mental_capacity_summary', params: {
        'service_user_id_param': serviceUserId,
      });
      
      if (data == null) {
        return null;
      }
      
      return MentalCapacitySummary.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      print('Error fetching mental capacity summary: ${e.message}');
      return null;
    }
  }

  // Helper methods
  String _determineCapacityLevel(Map<String, dynamic> functionalTest, Map<String, dynamic> twoStageTest) {
    bool hasCapacity = true;
    
    // Check if person can understand, retain, use/weigh, and communicate
    if (functionalTest['understand'] == false || 
        functionalTest['retain'] == false || 
        functionalTest['weigh'] == false || 
        functionalTest['communicate'] == false) {
      hasCapacity = false;
    }
    
    // Check two-stage test
    if (twoStageTest['impairment'] == true && twoStageTest['inability'] == true) {
      hasCapacity = false;
    }
    
    return hasCapacity ? 'Has Capacity' : 'Lacks Capacity';
  }

  Future<MentalCapacityAssessment?> getLatestMentalCapacityAssessment(String serviceUserId) async {
    try {
      final data = await _client
          .from('mental_capacity_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false)
          .limit(1)
          .single();
      return MentalCapacityAssessment.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (_) {
      return null;
    }
  }

  Future<List<MentalCapacityAssessment>> getMentalCapacityAssessmentHistory(String serviceUserId) async {
    try {
      final data = await _client
          .from('mental_capacity_assessments')
          .select('*, profiles(full_name)')
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false);
      
      return (data as List)
          .map((assessment) => MentalCapacityAssessment.fromMap(assessment as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching mental capacity assessment history: ${e.message}');
    }
  }

  // IMCA Referral Management
  Future<void> updateImcaReferral(String assessmentId, String imcaDetails) async {
    try {
      await _client
          .from('mental_capacity_assessments')
          .update({
            'imca_details': imcaDetails,
            'updated_at': DateTime.now(),
          })
          .eq('id', assessmentId);
    } on PostgrestException catch (e) {
      throw Exception('Error updating IMCA referral: ${e.message}');
    }
  }
}