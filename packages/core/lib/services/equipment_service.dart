import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/equipment_audit.dart';

class EquipmentService {
  final SupabaseClient _client;

  EquipmentService(this._client);

  // Create new equipment audit
  Future<String> create(EquipmentAudit audit) async {
    final response = await _client
        .from('equipment_audits')
        .insert(audit.toJson())
        .select()
        .single();
    return response['id'];
  }

  // Get single audit by ID
  Future<EquipmentAudit> get(String id) async {
    final response = await _client
        .from('equipment_audits')
        .select()
        .eq('id', id)
        .single();
    return EquipmentAudit.fromJson(response);
  }

  // Get all audits for a service user
  Future<List<EquipmentAudit>> getForServiceUser(String serviceUserId) async {
    final response = await _client
        .from('equipment_audits')
        .select()
        .eq('service_user_id', serviceUserId)
        .order('assessment_date', ascending: false);
    return (response as List)
        .map((a) => EquipmentAudit.fromJson(a))
        .toList();
  }

  // Update existing audit
  Future<void> update(String id, Map<String, dynamic> updates) async {
    await _client
        .from('equipment_audits')
        .update(updates)
        .eq('id', id);
  }

  // Delete audit
  Future<void> delete(String id) async {
    await _client
        .from('equipment_audits')
        .delete()
        .eq('id', id);
  }

  // Generate PDF (placeholder - implement later)
  Future<String> generatePdf(String id) async {
    // This will be implemented when PDF generation is ready
    return '';
  }
}