import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/sleep_chart.dart';

class SleepService {
  final SupabaseClient _client;
  SleepService(this._client);

  Future<List<SleepChart>> getChartsForServiceUser(String serviceUserId) async {
    final response = await _client.from('sleep_charts')
        .select('*, profiles!assessor_id(full_name)')
        .eq('service_user_id', serviceUserId)
        .order('assessment_date', ascending: false);
    return (response as List).map((c) => SleepChart.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<SleepChart> getChart(String id) async {
    final response = await _client.from('sleep_charts').select('*').eq('id', id).single();
    return SleepChart.fromJson(response as Map<String, dynamic>);
  }

  Future<String> createChart(SleepChart chart, String userId) async {
    final now = DateTime.now().toIso8601String();
    final response = await _client.from('sleep_charts').insert({
      'service_user_id': chart.serviceUserId,
      'assessment_date': chart.chartDate.toIso8601String(),
      'responses': chart.overnightEntries.map((e) => e.toJson()).toList(),
      'assessor_id': userId,
      'created_at': now,
      'updated_at': now,
    }).select().single();
    return (response as Map<String, dynamic>)['id'] as String;
  }

  Future<List<SleepChart>> getChartsForDateRange(String serviceUserId, DateTime startDate, DateTime endDate) async {
    final response = await _client.from('sleep_charts')
        .select('*').eq('service_user_id', serviceUserId)
        .gte('assessment_date', startDate.toIso8601String())
        .lte('assessment_date', endDate.toIso8601String())
        .order('assessment_date', ascending: true);
    return (response as List).map((c) => SleepChart.fromJson(c as Map<String, dynamic>)).toList();
  }
}