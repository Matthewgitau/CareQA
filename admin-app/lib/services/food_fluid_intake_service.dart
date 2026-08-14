import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_fluid_intake_log.dart';

class FoodFluidIntakeService {
  final SupabaseClient _client;

  FoodFluidIntakeService(this._client);

  Future<List<FoodFluidIntakeLog>> getLogs({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client.from('food_fluid_intake_logs').select();

    if (serviceUserId != null) {
      query = query.eq('service_user_id', serviceUserId);
    }
    if (startDate != null) {
      query = query.gte('log_date', startDate.toIso8601String().split('T').first);
    }
    if (endDate != null) {
      query = query.lte('log_date', endDate.toIso8601String().split('T').first);
    }

    final data = await query.order('log_time', ascending: false);
    return (data as List).map((item) => FoodFluidIntakeLog.fromMap(item as Map<String, dynamic>)).toList();
  }

  Future<FoodFluidIntakeLog> getLog(String id) async {
    final data = await _client
        .from('food_fluid_intake_logs')
        .select()
        .eq('id', id)
        .single();
    return FoodFluidIntakeLog.fromMap(data as Map<String, dynamic>);
  }

  Future<FoodFluidIntakeLog> createLog(FoodFluidIntakeLog log) async {
    final data = await _client
        .from('food_fluid_intake_logs')
        .insert(log.toMap())
        .select()
        .single();
    return FoodFluidIntakeLog.fromMap(data as Map<String, dynamic>);
  }

  Future<FoodFluidIntakeLog> updateLog(String id, FoodFluidIntakeLog log) async {
    final data = await _client
        .from('food_fluid_intake_logs')
        .update(log.toMap())
        .eq('id', id)
        .select()
        .single();
    return FoodFluidIntakeLog.fromMap(data as Map<String, dynamic>);
  }

  Future<void> deleteLog(String id) async {
    await _client.from('food_fluid_intake_logs').delete().eq('id', id);
  }
}