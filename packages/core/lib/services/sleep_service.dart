import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sleep_chart.dart';

class SleepService {
  final SupabaseClient _client;

  SleepService(this._client);

  // Create new sleep chart
  Future<String> create(SleepChart chart) async {
    final response = await _client
        .from('sleep_charts')
        .insert(chart.toJson())
        .select()
        .single();
    return response['id'];
  }

  // Get single chart by ID
  Future<SleepChart> get(String id) async {
    final response = await _client
        .from('sleep_charts')
        .select()
        .eq('id', id)
        .single();
    return SleepChart.fromJson(response);
  }

  // Get all charts for a service user
  Future<List<SleepChart>> getForServiceUser(String serviceUserId) async {
    final response = await _client
        .from('sleep_charts')
        .select()
        .eq('service_user_id', serviceUserId)
        .order('assessment_date', ascending: false);
    return (response as List)
        .map((a) => SleepChart.fromJson(a))
        .toList();
  }

  // Update existing chart
  Future<void> update(String id, Map<String, dynamic> updates) async {
    await _client
        .from('sleep_charts')
        .update(updates)
        .eq('id', id);
  }

  // Delete chart
  Future<void> delete(String id) async {
    await _client
        .from('sleep_charts')
        .delete()
        .eq('id', id);
  }

  // Generate PDF (placeholder - implement later)
  Future<String> generatePdf(String id) async {
    // This will be implemented when PDF generation is ready
    return '';
  }
}