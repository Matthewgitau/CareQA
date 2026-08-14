import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supervision_record.dart';

class SupervisionService {
  final SupabaseClient _client;

  SupervisionService(this._client);

  // Create new supervision record
  Future<String> create(SupervisionRecord record) async {
    final response = await _client
        .from('supervision_records')
        .insert(record.toJson())
        .select()
        .single();
    return response['id'];
  }

  // Get single record by ID
  Future<SupervisionRecord> get(String id) async {
    final response = await _client
        .from('supervision_records')
        .select()
        .eq('id', id)
        .single();
    return SupervisionRecord.fromJson(response);
  }

  // Get all records for a service user
  Future<List<SupervisionRecord>> getForServiceUser(String serviceUserId) async {
    final response = await _client
        .from('supervision_records')
        .select()
        .eq('service_user_id', serviceUserId)
        .order('assessment_date', ascending: false);
    return (response as List)
        .map((a) => SupervisionRecord.fromJson(a))
        .toList();
  }

  // Update existing record
  Future<void> update(String id, Map<String, dynamic> updates) async {
    await _client
        .from('supervision_records')
        .update(updates)
        .eq('id', id);
  }

  // Delete record
  Future<void> delete(String id) async {
    await _client
        .from('supervision_records')
        .delete()
        .eq('id', id);
  }

  // Generate PDF (placeholder - implement later)
  Future<String> generatePdf(String id) async {
    // This will be implemented when PDF generation is ready
    return '';
  }
}