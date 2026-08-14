import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appraisal_form.dart';

class AppraisalService {
  final SupabaseClient _client;

  AppraisalService(this._client);

  // Create new appraisal form
  Future<String> create(AppraisalForm form) async {
    final response = await _client
        .from('appraisal_forms')
        .insert(form.toJson())
        .select()
        .single();
    return response['id'];
  }

  // Get single form by ID
  Future<AppraisalForm> get(String id) async {
    final response = await _client
        .from('appraisal_forms')
        .select()
        .eq('id', id)
        .single();
    return AppraisalForm.fromJson(response);
  }

  // Get all forms for a service user
  Future<List<AppraisalForm>> getForServiceUser(String serviceUserId) async {
    final response = await _client
        .from('appraisal_forms')
        .select()
        .eq('service_user_id', serviceUserId)
        .order('assessment_date', ascending: false);
    return (response as List)
        .map((a) => AppraisalForm.fromJson(a))
        .toList();
  }

  // Update existing form
  Future<void> update(String id, Map<String, dynamic> updates) async {
    await _client
        .from('appraisal_forms')
        .update(updates)
        .eq('id', id);
  }

  // Delete form
  Future<void> delete(String id) async {
    await _client
        .from('appraisal_forms')
        .delete()
        .eq('id', id);
  }

  // Generate PDF (placeholder - implement later)
  Future<String> generatePdf(String id) async {
    // This will be implemented when PDF generation is ready
    return '';
  }
}