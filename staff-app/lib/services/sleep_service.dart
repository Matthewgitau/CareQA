import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/sleep_chart.dart';

class SleepService {
  final SupabaseClient _client;

  SleepService(this._client);

  // Get all charts for a service user
  Future<List<SleepChart>> getChartsForServiceUser(String serviceUserId) async {
    final response = await _client
        .from('sleep_charts')
        .select('*, profiles!created_by(full_name)')
        .eq('service_user_id', serviceUserId)
        .order('chart_date', ascending: false);
    
    if (response.error != null) {
      throw Exception('Error fetching sleep charts: ${response.error}');
    }
    
    return (response.data as List)
        .map((c) => SleepChart.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // Get single chart by ID
  Future<SleepChart> getChart(String id) async {
    final response = await _client
        .from('sleep_charts')
        .select('*')
        .eq('id', id)
        .single();
    
    if (response.error != null) {
      throw Exception('Error fetching sleep chart: ${response.error}');
    }
    
    return SleepChart.fromJson(response.data as Map<String, dynamic>);
  }

  // Create new chart (carer)
  Future<String> createChart(SleepChart chart, String userId) async {
    final response = await _client
        .from('sleep_charts')
        .insert({
          ...chart.toJson(),
          'created_by': userId,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    
    if (response.error != null) {
      throw Exception('Error creating sleep chart: ${response.error}');
    }
    
    return response.data['id'] as String;
  }

  // Get charts for a specific date range
  Future<List<SleepChart>> getChartsForDateRange(String serviceUserId, DateTime startDate, DateTime endDate) async {
    final response = await _client
        .from('sleep_charts')
        .select('*')
        .eq('service_user_id', serviceUserId)
        .gte('chart_date', startDate.toIso8601String())
        .lte('chart_date', endDate.toIso8601String())
        .order('chart_date', ascending: true);
    
    if (response.error != null) {
      throw Exception('Error fetching charts for date range: ${response.error}');
    }
    
    return (response.data as List)
        .map((c) => SleepChart.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // Get charts with distressing observations
  Future<List<SleepChart>> getChartsWithDistressingObservations(String serviceUserId) async {
    final response = await _client
        .from('sleep_charts')
        .select('*')
        .eq('service_user_id', serviceUserId)
        .eq('has_distressing_observations', true)
        .order('chart_date', ascending: false);
    
    if (response.error != null) {
      throw Exception('Error fetching charts with distressing observations: ${response.error}');
    }
    
    return (response.data as List)
        .map((c) => SleepChart.fromJson(c as Map<String, dynamic>))
        .toList();
  }
}