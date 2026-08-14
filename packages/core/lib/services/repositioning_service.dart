import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/repositioning_chart.dart';

class RepositioningService {
  final SupabaseClient _client;

  RepositioningService(this._client);

  // Create new repositioning chart
  Future<String> create(RepositioningChart chart) async {
    final response = await _client
        .from('repositioning_charts')
        .insert(chart.toJson())
        .select()
        .single();
    return response['id'];
  }

  // Get single chart by ID
  Future<RepositioningChart> get(String id) async {
    final response = await _client
        .from('repositioning_charts')
        .select()
        .eq('id', id)
        .single();
    return RepositioningChart.fromJson(response);
  }

  // Get all charts for a service user
  Future<List<RepositioningChart>> getForServiceUser(String serviceUserId) async {
    final response = await _client
        .from('repositioning_charts')
        .select()
        .eq('service_user_id', serviceUserId)
        .order('assessment_date', ascending: false);
    return (response as List)
        .map((a) => RepositioningChart.fromJson(a))
        .toList();
  }

  // Update existing chart
  Future<void> update(String id, Map<String, dynamic> updates) async {
    await _client
        .from('repositioning_charts')
        .update(updates)
        .eq('id', id);
  }

  // Delete chart
  Future<void> delete(String id) async {
    await _client
        .from('repositioning_charts')
        .delete()
        .eq('id', id);
  }

  // Generate PDF (placeholder - implement later)
  Future<String> generatePdf(String id) async {
    // This will be implemented when PDF generation is ready
    return '';
  }
}