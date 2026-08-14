import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/skin_integrity_assessment.dart';

class SkinIntegrityService {
  final SupabaseClient _client;

  SkinIntegrityService(this._client);

  // Create new skin integrity assessment
  Future<String> create(SkinIntegrityAssessment assessment) async {
    final response = await _client
        .from('skin_integrity_assessments')
        .insert(assessment.toJson())
        .select()
        .single();
    return response['id'];
  }

  // Get single assessment by ID
  Future<SkinIntegrityAssessment> get(String id) async {
    final response = await _client
        .from('skin_integrity_assessments')
        .select()
        .eq('id', id)
        .single();
    return SkinIntegrityAssessment.fromJson(response);
  }

  // Get all assessments for a service user
  Future<List<SkinIntegrityAssessment>> getForServiceUser(String serviceUserId) async {
    final response = await _client
        .from('skin_integrity_assessments')
        .select()
        .eq('service_user_id', serviceUserId)
        .order('assessment_date', ascending: false);
    return (response as List)
        .map((a) => SkinIntegrityAssessment.fromJson(a))
        .toList();
  }

  // Update existing assessment
  Future<void> update(String id, Map<String, dynamic> updates) async {
    await _client
        .from('skin_integrity_assessments')
        .update(updates)
        .eq('id', id);
  }

  // Delete assessment
  Future<void> delete(String id) async {
    await _client
        .from('skin_integrity_assessments')
        .delete()
        .eq('id', id);
  }

  // Generate PDF (placeholder - implement later)
  Future<String> generatePdf(String id) async {
    // This will be implemented when PDF generation is ready
    return '';
  }
}