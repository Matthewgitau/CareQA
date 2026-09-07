import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/food_fluid_chart.dart';

class FoodFluidService {
  final SupabaseClient _client;
  FoodFluidService(this._client);

  Future<List<FoodFluidChart>> getChartsForServiceUser(String serviceUserId) async {
    final response = await _client.from('food_fluid_charts')
        .select('*, profiles!assessor_id(full_name)')
        .eq('service_user_id', serviceUserId)
        .order('assessment_date', ascending: false);
    return (response as List).map((c) => FoodFluidChart.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<FoodFluidChart> getChart(String id) async {
    final response = await _client.from('food_fluid_charts').select('*').eq('id', id).single();
    return FoodFluidChart.fromJson(response as Map<String, dynamic>);
  }

  Future<String> createChart(FoodFluidChart chart, String userId) async {
    final now = DateTime.now().toIso8601String();
    final response = await _client.from('food_fluid_charts').insert({
      'service_user_id': chart.serviceUserId,
      'assessment_date': chart.chartDate.toIso8601String(),
      'responses': chart.entries,
      'assessor_id': userId,
      'created_at': now,
      'updated_at': now,
    }).select().single();
    return (response as Map<String, dynamic>)['id'] as String;
  }
}