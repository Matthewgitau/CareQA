import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/bowel_bladder_chart.dart';

class BowelBladderService {
  final SupabaseClient _client;
  BowelBladderService(this._client);

  Future<List<BowelBladderChart>> getChartsForServiceUser(String serviceUserId) async {
    final response = await _client.from('bowel_bladder_charts')
        .select('*, profiles!assessor_id(full_name)')
        .eq('service_user_id', serviceUserId)
        .order('assessment_date', ascending: false);
    return (response as List).map((c) => BowelBladderChart.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<BowelBladderChart> getChart(String id) async {
    final response = await _client.from('bowel_bladder_charts').select('*').eq('id', id).single();
    return BowelBladderChart.fromJson(response as Map<String, dynamic>);
  }

  Future<String> createChart(BowelBladderChart chart, String userId) async {
    final now = DateTime.now().toIso8601String();
    final response = await _client.from('bowel_bladder_charts').insert({
      'service_user_id': chart.serviceUserId,
      'assessment_date': chart.chartDate.toIso8601String(),
      'responses': chart.toJson(),
      'assessor_id': userId,
      'created_at': now,
      'updated_at': now,
    }).select().single();
    return (response as Map<String, dynamic>)['id'] as String;
  }
}