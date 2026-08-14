import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fire_safety_audit.dart';

class FireSafetyService {
  final SupabaseClient _client;

  FireSafetyService(this._client);

  // Create new fire safety audit
  Future<String> create(FireSafetyAudit audit) async {
    final response = await _client
        .from('fire_safety_audits')
        .insert(audit.toJson())
        .select()
        .single();
    return response['id'];
  }

  // Get single audit by ID
  Future<FireSafetyAudit> get(String id) async {
    final response = await _client
        .from('fire_safety_audits')
        .select()
        .eq('id', id)
        .single();
    return FireSafetyAudit.fromJson(response);
  }

  // Get all audits for a service user
  Future<List<FireSafetyAudit>> getForServiceUser(String serviceUserId) async {
    final response = await _client
        .from('fire_safety_audits')
        .select()
        .eq('service_user_id', serviceUserId)
        .order('assessment_date', ascending: false);
    return (response as List)
        .map((a) => FireSafetyAudit.fromJson(a))
        .toList();
  }

  // Update existing audit
  Future<void> update(String id, Map<String, dynamic> updates) async {
    await _client
        .from('fire_safety_audits')
        .update(updates)
        .eq('id', id);
  }

  // Delete audit
  Future<void> delete(String id) async {
    await _client
        .from('fire_safety_audits')
        .delete()
        .eq('id', id);
  }

  // Generate PDF (placeholder - implement later)
  Future<String> generatePdf(String id) async {
    // This will be implemented when PDF generation is ready
    return '';
  }
}