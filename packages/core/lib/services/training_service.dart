import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/training_record.dart';

class TrainingService {
  final SupabaseClient _client;

  TrainingService(this._client);

  // Create new training record
  Future<String> create(TrainingRecord record) async {
    final response = await _client
        .from('training_records')
        .insert(record.toJson())
        .select()
        .single();
    return response['id'];
  }

  // Get single record by ID
  Future<TrainingRecord> get(String id) async {
    final response = await _client
        .from('training_records')
        .select()
        .eq('id', id)
        .single();
    return TrainingRecord.fromJson(response);
  }

  // Get all records for a service user
  Future<List<TrainingRecord>> getForServiceUser(String serviceUserId) async {
    final response = await _client
        .from('training_records')
        .select()
        .eq('service_user_id', serviceUserId)
        .order('assessment_date', ascending: false);
    return (response as List)
        .map((a) => TrainingRecord.fromJson(a))
        .toList();
  }

  // Update existing record
  Future<void> update(String id, Map<String, dynamic> updates) async {
    await _client
        .from('training_records')
        .update(updates)
        .eq('id', id);
  }

  // Delete record
  Future<void> delete(String id) async {
    await _client
        .from('training_records')
        .delete()
        .eq('id', id);
  }

  // Generate PDF (placeholder - implement later)
  Future<String> generatePdf(String id) async {
    // This will be implemented when PDF generation is ready
    return '';
  }
}