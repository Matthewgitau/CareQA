import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/repositioning_chart.dart';

class RepositioningService {
  final SupabaseClient _client;

  RepositioningService(this._client);

  // Get all charts for a service user
  Future<List<RepositioningChart>> getChartsForServiceUser(String serviceUserId) async {
    final response = await _client
        .from('repositioning_charts')
        .select('*, profiles!created_by(full_name)')
        .eq('service_user_id', serviceUserId)
        .order('chart_date', ascending: false);
    
    if (response.error != null) {
      throw Exception('Error fetching repositioning charts: ${response.error}');
    }
    
    return (response.data as List)
        .map((c) => RepositioningChart.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // Get single chart by ID
  Future<RepositioningChart> getChart(String id) async {
    final response = await _client
        .from('repositioning_charts')
        .select('*')
        .eq('id', id)
        .single();
    
    if (response.error != null) {
      throw Exception('Error fetching repositioning chart: ${response.error}');
    }
    
    return RepositioningChart.fromJson(response.data as Map<String, dynamic>);
  }

  // Create new chart (carer)
  Future<String> createChart(RepositioningChart chart, String userId) async {
    final response = await _client
        .from('repositioning_charts')
        .insert({
          ...chart.toJson(),
          'created_by': userId,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    
    if (response.error != null) {
      throw Exception('Error creating repositioning chart: ${response.error}');
    }
    
    return response.data['id'] as String;
  }

  // Get charts for a specific date range
  Future<List<RepositioningChart>> getChartsForDateRange(String serviceUserId, DateTime startDate, DateTime endDate) async {
    final response = await _client
        .from('repositioning_charts')
        .select('*')
        .eq('service_user_id', serviceUserId)
        .gte('chart_date', startDate.toIso8601String())
        .lte('chart_date', endDate.toIso8601String())
        .order('chart_date', ascending: true);
    
    if (response.error != null) {
      throw Exception('Error fetching charts for date range: ${response.error}');
    }
    
    return (response.data as List)
        .map((c) => RepositioningChart.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // Get charts with skin concerns
  Future<List<RepositioningChart>> getChartsWithSkinConcerns(String serviceUserId) async {
    final response = await _client
        .from('repositioning_charts')
        .select('*')
        .eq('service_user_id', serviceUserId)
        .eq('has_skin_concerns', true)
        .order('chart_date', ascending: false);
    
    if (response.error != null) {
      throw Exception('Error fetching charts with skin concerns: ${response.error}');
    }
    
    return (response.data as List)
        .map((c) => RepositioningChart.fromJson(c as Map<String, dynamic>))
        .toList();
  }
}