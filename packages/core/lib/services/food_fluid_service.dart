import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_fluid_chart.dart';

class FoodFluidService {
  final SupabaseClient _client;

  FoodFluidService(this._client);

  // Create new food/fluid chart
  Future<String> create(FoodFluidChart chart) async {
    final response = await _client
        .from('food_fluid_charts')
        .insert(chart.toJson())
        .select()
        .single();
    return response['id'];
  }

  // Get single chart by ID
  Future<FoodFluidChart> get(String id) async {
    final response = await _client
        .from('food_fluid_charts')
        .select()
        .eq('id', id)
        .single();
    return FoodFluidChart.fromJson(response);
  }

  // Get all charts for a service user
  Future<List<FoodFluidChart>> getForServiceUser(String serviceUserId) async {
    final response = await _client
        .from('food_fluid_charts')
        .select()
        .eq('service_user_id', serviceUserId)
        .order('assessment_date', ascending: false);
    return (response as List)
        .map((a) => FoodFluidChart.fromJson(a))
        .toList();
  }

  // Update existing chart
  Future<void> update(String id, Map<String, dynamic> updates) async {
    await _client
        .from('food_fluid_charts')
        .update(updates)
        .eq('id', id);
  }

  // Delete chart
  Future<void> delete(String id) async {
    await _client
        .from('food_fluid_charts')
        .delete()
        .eq('id', id);
  }

  // Generate PDF (placeholder - implement later)
  Future<String> generatePdf(String id) async {
    // This will be implemented when PDF generation is ready
    return '';
  }
}