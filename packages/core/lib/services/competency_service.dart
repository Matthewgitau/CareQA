import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/competency_assessment.dart';

class CompetencyService {
  final SupabaseClient _client;

  CompetencyService(this._client);

  // Create new competency assessment
  Future<String> create(CompetencyAssessment assessment) async {
    final response = await _client
        .from('competency_assessments')
        .insert(assessment.toJson())
        .select()
        .single();
    return response['id'];
  }

  // Get single assessment by ID
  Future<CompetencyAssessment> get(String id) async {
    final response = await _client
        .from('competency_assessments')
        .select()
        .eq('id', id)
        .single();
    return CompetencyAssessment.fromJson(response);
  }

  // Get all assessments for a service user
  Future<List<CompetencyAssessment>> getForServiceUser(String serviceUserId) async {
    final response = await _client
        .from('competency_assessments')
        .select()
        .eq('service_user_id', serviceUserId)
        .order('assessment_date', ascending: false);
    return (response as List)
        .map((a) => CompetencyAssessment.fromJson(a))
        .toList();
  }

  // Update existing assessment
  Future<void> update(String id, Map<String, dynamic> updates) async {
    await _client
        .from('competency_assessments')
        .update(updates)
        .eq('id', id);
  }

  // Delete assessment
  Future<void> delete(String id) async {
    await _client
        .from('competency_assessments')
        .delete()
        .eq('id', id);
  }

  // Generate PDF (placeholder - implement later)
  Future<String> generatePdf(String id) async {
    // This will be implemented when PDF generation is ready
    return '';
  }
}