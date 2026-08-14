import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/pre_admission.dart';

class PreAdmissionService {
  final SupabaseClient _client;

  PreAdmissionService(this._client);

  // ADL Categories
  Future<List<ADLCategory>> getADLCategories() async {
    try {
      final data = await _client
          .from('adl_categories')
          .select()
          .order('display_order', ascending: true);
      return (data as List)
          .map((category) => ADLCategory.fromMap(category as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching ADL categories: ${e.message}');
    }
  }

  Future<List<ADLCategory>> getADLCategoriesOnce() async {
    try {
      final data = await _client
          .from('adl_categories')
          .select()
          .order('display_order', ascending: true);
      
      return (data as List)
          .map((category) => ADLCategory.fromMap(category as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching ADL categories: ${e.message}');
    }
  }

  // Pre-Admissions
  Future<List<PreAdmission>> getPreAdmissionsByServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('pre_admissions')
          .select('*, profiles(full_name)')
          .eq('service_user_id', serviceUserId)
          .order('created_at', ascending: false);
      return (data as List)
          .map((admission) => PreAdmission.fromMap(admission as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching pre-admissions: ${e.message}');
    }
  }

  Future<List<PreAdmission>> getPreAdmissionsByStatus(String status) async {
    try {
      final data = await _client
          .from('pre_admissions')
          .select('*, profiles(full_name)')
          .eq('status', status)
          .order('created_at', ascending: false);
      return (data as List)
          .map((admission) => PreAdmission.fromMap(admission as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching pre-admissions: ${e.message}');
    }
  }

  Future<PreAdmission> createPreAdmission(Map<String, dynamic> preAdmissionData) async {
    try {
      final data = await _client
          .from('pre_admissions')
          .insert(preAdmissionData)
          .select()
          .single();
      
      return PreAdmission.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Error creating pre-admission: ${e.message}');
    }
  }

  Future<PreAdmission> updatePreAdmission(String preAdmissionId, Map<String, dynamic> updates) async {
    try {
      final data = await _client
          .from('pre_admissions')
          .update(updates)
          .eq('id', preAdmissionId)
          .select()
          .single();
      
      return PreAdmission.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Error updating pre-admission: ${e.message}');
    }
  }

  Future<void> deletePreAdmission(String preAdmissionId) async {
    try {
      await _client
          .from('pre_admissions')
          .delete()
          .eq('id', preAdmissionId);
    } on PostgrestException catch (e) {
      throw Exception('Error deleting pre-admission: ${e.message}');
    }
  }

  // Pre-Admission Summary
  Future<PreAdmissionSummary?> getPreAdmissionSummary(String preAdmissionId) async {
    try {
      final data = await _client.rpc('get_pre_admission_summary', params: {
        'pre_admission_id': preAdmissionId,
      });
      
      if (data == null) {
        return null;
      }
      
      return PreAdmissionSummary.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      print('Error fetching pre-admission summary: ${e.message}');
      return null;
    }
  }

  // Pre-Admission Validation
  Future<PreAdmissionValidation> validatePreAdmissionCompleteness(String preAdmissionId) async {
    try {
      final data = await _client.rpc('validate_pre_admission_completeness', params: {
        'pre_admission_id': preAdmissionId,
      });
      
      return PreAdmissionValidation.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Error validating pre-admission: ${e.message}');
    }
  }

  // Submit Pre-Admission
  Future<bool> submitPreAdmission(String preAdmissionId, String submittedById) async {
    try {
      final data = await _client.rpc('submit_pre_admission', params: {
        'pre_admission_id': preAdmissionId,
        'submitted_by_id': submittedById,
      });
      
      return data as bool;
    } on PostgrestException catch (e) {
      throw Exception('Error submitting pre-admission: ${e.message}');
    }
  }

  // Helper methods for form data
  Future<PreAdmission> getPreAdmissionById(String preAdmissionId) async {
    try {
      final data = await _client
          .from('pre_admissions')
          .select()
          .eq('id', preAdmissionId)
          .single();
      
      return PreAdmission.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Error fetching pre-admission: ${e.message}');
    }
  }

  // Get latest pre-admission for a service user
  Future<PreAdmission?> getLatestPreAdmission(String serviceUserId) async {
    try {
      final data = await _client
          .from('pre_admissions')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('created_at', ascending: false)
          .limit(1)
          .single();
      return PreAdmission.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (_) {
      return null;
    }
  }

  // Get all pre-admissions for a service user (for history)
  Future<List<PreAdmission>> getPreAdmissionHistory(String serviceUserId) async {
    try {
      final data = await _client
          .from('pre_admissions')
          .select('*, profiles(full_name)')
          .eq('service_user_id', serviceUserId)
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((admission) => PreAdmission.fromMap(admission as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching pre-admission history: ${e.message}');
    }
  }

  // Create a complete pre-admission with all sections
  Future<PreAdmission> createCompletePreAdmission({
    required String serviceUserId,
    required String createdBy,
    required Map<String, dynamic> personalDetails,
    required Map<String, dynamic> medicalInfo,
    required Map<String, dynamic> adlAssessments,
    required String fundingSource,
  }) async {
    final preAdmissionData = {
      ...personalDetails,
      ...medicalInfo,
      'adl_assessments': adlAssessments,
      'funding_source': fundingSource,
      'service_user_id': serviceUserId,
      'created_by': createdBy,
      'status': 'draft',
    };

    return await createPreAdmission(preAdmissionData);
  }

  // Update specific sections
  Future<PreAdmission> updatePersonalDetails(String preAdmissionId, Map<String, dynamic> personalDetails) async {
    return await updatePreAdmission(preAdmissionId, personalDetails);
  }

  Future<PreAdmission> updateMedicalInfo(String preAdmissionId, Map<String, dynamic> medicalInfo) async {
    return await updatePreAdmission(preAdmissionId, medicalInfo);
  }

  Future<PreAdmission> updateADLAssessments(String preAdmissionId, List<Map<String, dynamic>> adlAssessments) async {
    return await updatePreAdmission(preAdmissionId, {'adl_assessments': adlAssessments});
  }

  Future<PreAdmission> updateBackgroundInfo(String preAdmissionId, Map<String, dynamic> backgroundInfo) async {
    return await updatePreAdmission(preAdmissionId, backgroundInfo);
  }

  // Search pre-admissions
  Future<List<PreAdmission>> searchPreAdmissions({
    String? familyName,
    String? firstName,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    var query = _client.from('pre_admissions').select('*, profiles(full_name)');

    if (familyName != null && familyName.isNotEmpty) {
      query = query.ilike('family_name', '%$familyName%');
    }

    if (firstName != null && firstName.isNotEmpty) {
      query = query.ilike('first_name', '%$firstName%');
    }

    if (status != null) {
      query = query.eq('status', status);
    }

    if (dateFrom != null) {
      query = query.gte('created_at', dateFrom);
    }

    if (dateTo != null) {
      query = query.lte('created_at', dateTo);
    }

    try {
      final data = await query.order('created_at', ascending: false);

      return (data as List)
          .map((admission) => PreAdmission.fromMap(admission as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error searching pre-admissions: ${e.message}');
    }
  }
}