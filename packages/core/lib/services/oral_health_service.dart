import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/oral_health_assessment.dart';

class OralHealthService {
  final SupabaseClient _client;

  OralHealthService(this._client);

  // Create new oral health assessment
  Future<String> create(OralHealthAssessment assessment) async {
    final response = await _client
        .from('oral_health_assessments')
        .insert(assessment.toJson())
        .select()
        .single();
    return response['id'];
  }

  // Get single assessment by ID
  Future<OralHealthAssessment> get(String id) async {
    final response = await _client
        .from('oral_health_assessments')
        .select()
        .eq('id', id)
        .single();
    return OralHealthAssessment.fromJson(response);
  }

  // Get all assessments for a service user
  Future<List<OralHealthAssessment>> getForServiceUser(String serviceUserId) async {
    final response = await _client
        .from('oral_health_assessments')
        .select()
        .eq('service_user_id', serviceUserId)
        .order('assessment_date', ascending: false);
    return (response as List)
        .map((a) => OralHealthAssessment.fromJson(a))
        .toList();
  }

  // Update existing assessment
  Future<void> update(String id, Map<String, dynamic> updates) async {
    await _client
        .from('oral_health_assessments')
        .update(updates)
        .eq('id', id);
  }

  // Delete assessment
  Future<void> delete(String id) async {
    await _client
        .from('oral_health_assessments')
        .delete()
        .eq('id', id);
  }

  // Generate PDF (placeholder - implement later)
  Future<String> generatePdf(String id) async {
    // This will be implemented when PDF generation is ready
    return '';
  }
}