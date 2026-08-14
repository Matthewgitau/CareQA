import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/infection_control_audit.dart';

class InfectionControlService {
  final SupabaseClient _client;

  InfectionControlService(this._client);

  // Create new infection control audit
  Future<String> create(InfectionControlAudit audit) async {
    final response = await _client
        .from('infection_control_audits')
        .insert(audit.toJson())
        .select()
        .single();
    return response['id'];
  }

  // Get single audit by ID
  Future<InfectionControlAudit> get(String id) async {
    final response = await _client
        .from('infection_control_audits')
        .select()
        .eq('id', id)
        .single();
    return InfectionControlAudit.fromJson(response);
  }

  // Get all audits for a service user
  Future<List<InfectionControlAudit>> getForServiceUser(String serviceUserId) async {
    final response = await _client
        .from('infection_control_audits')
        .select()
        .eq('service_user_id', serviceUserId)
        .order('assessment_date', ascending: false);
    return (response as List)
        .map((a) => InfectionControlAudit.fromJson(a))
        .toList();
  }

  // Update existing audit
  Future<void> update(String id, Map<String, dynamic> updates) async {
    await _client
        .from('infection_control_audits')
        .update(updates)
        .eq('id', id);
  }

  // Delete audit
  Future<void> delete(String id) async {
    await _client
        .from('infection_control_audits')
        .delete()
        .eq('id', id);
  }

  // Generate PDF (placeholder - implement later)
  Future<String> generatePdf(String id) async {
    // This will be implemented when PDF generation is ready
    return '';
  }
}