import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bowel_bladder_chart.dart';

class BowelBladderService {
  final SupabaseClient _client;

  BowelBladderService(this._client);

  // Create new bowel/bladder chart
  Future<String> create(BowelBladderChart chart) async {
    final response = await _client
        .from('bowel_bladder_charts')
        .insert(chart.toJson())
        .select()
        .single();
    return response['id'];
  }

  // Get single chart by ID
  Future<BowelBladderChart> get(String id) async {
    final response = await _client
        .from('bowel_bladder_charts')
        .select()
        .eq('id', id)
        .single();
    return BowelBladderChart.fromJson(response);
  }

  // Get all charts for a service user
  Future<List<BowelBladderChart>> getForServiceUser(String serviceUserId) async {
    final response = await _client
        .from('bowel_bladder_charts')
        .select()
        .eq('service_user_id', serviceUserId)
        .order('assessment_date', ascending: false);
    return (response as List)
        .map((a) => BowelBladderChart.fromJson(a))
        .toList();
  }

  // Update existing chart
  Future<void> update(String id, Map<String, dynamic> updates) async {
    await _client
        .from('bowel_bladder_charts')
        .update(updates)
        .eq('id', id);
  }

  // Delete chart
  Future<void> delete(String id) async {
    await _client
        .from('bowel_bladder_charts')
        .delete()
        .eq('id', id);
  }

  // Generate PDF (placeholder - implement later)
  Future<String> generatePdf(String id) async {
    // This will be implemented when PDF generation is ready
    return '';
  }
}