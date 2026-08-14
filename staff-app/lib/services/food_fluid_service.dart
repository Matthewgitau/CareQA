import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/food_fluid_chart.dart';

class FoodFluidService {
  final SupabaseClient _client;

  FoodFluidService(this._client);

  // Get all charts for a service user
  Future<List<FoodFluidChart>> getChartsForServiceUser(String serviceUserId) async {
    final response = await _client
        .from('food_fluid_charts')
        .select('*, profiles!created_by(full_name)')
        .eq('service_user_id', serviceUserId)
        .order('chart_date', ascending: false);
    
    if (response.error != null) {
      throw Exception('Error fetching food & fluid charts: ${response.error}');
    }
    
    return (response.data as List)
        .map((c) => FoodFluidChart.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // Get chart summaries for a service user
  Future<List<FoodFluidChartSummary>> getChartSummariesForServiceUser(String serviceUserId) async {
    final response = await _client
        .from('food_fluid_charts')
        .select('id, service_user_id, chart_date, total_fluid_ml, fluid_target_met, created_by, created_at, updated_by, updated_at')
        .eq('service_user_id', serviceUserId)
        .order('chart_date', ascending: false);
    
    if (response.error != null) {
      throw Exception('Error fetching food & fluid chart summaries: ${response.error}');
    }
    
    return (response.data as List)
        .map((c) => FoodFluidChartSummary.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // Get single chart by ID
  Future<FoodFluidChart> getChart(String id) async {
    final response = await _client
        .from('food_fluid_charts')
        .select('*')
        .eq('id', id)
        .single();
    
    if (response.error != null) {
      throw Exception('Error fetching food & fluid chart: ${response.error}');
    }
    
    return FoodFluidChart.fromJson(response.data as Map<String, dynamic>);
  }

  // Create new chart (carer)
  Future<String> createChart(FoodFluidChart chart, String userId) async {
    final response = await _client
        .from('food_fluid_charts')
        .insert({
          ...chart.toJson(),
          'created_by': userId,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    
    if (response.error != null) {
      throw Exception('Error creating food & fluid chart: ${response.error}');
    }
    
    return response.data['id'] as String;
  }

  // Update existing chart (admin only) - logs changes
  Future<void> updateChart(String id, Map<String, dynamic> updates, String userId) async {
    // Get current data for audit log
    final current = await getChart(id);
    
    // Update chart
    final updateResponse = await _client
        .from('food_fluid_charts')
        .update({
          ...updates,
          'updated_by': userId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
    
    if (updateResponse.error != null) {
      throw Exception('Error updating food & fluid chart: ${updateResponse.error}');
    }

    // Create audit log entry
    final auditResponse = await _client.from('food_fluid_audit_logs').insert({
      'chart_id': id,
      'edited_by': userId,
      'previous_data': current.toJson(),
      'new_data': updates,
      'edited_at': DateTime.now().toIso8601String(),
    });
    
    if (auditResponse.error != null) {
      throw Exception('Error creating audit log: ${auditResponse.error}');
    }
  }

  // Get audit log for a chart
  Future<List<Map<String, dynamic>>> getAuditLog(String chartId) async {
    final response = await _client
        .from('food_fluid_audit_logs')
        .select('*, profiles!edited_by(full_name)')
        .eq('chart_id', chartId)
        .order('edited_at', ascending: false);
    
    if (response.error != null) {
      throw Exception('Error fetching audit log: ${response.error}');
    }
    
    return List<Map<String, dynamic>>.from(response.data);
  }

  // Get charts with pagination and filtering
  Future<List<FoodFluidChartSummary>> getChartsWithFilter({
    String? serviceUserId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? createdBy,
  }) async {
    var query = _client
        .from('food_fluid_charts')
        .select('id, service_user_id, chart_date, total_fluid_ml, fluid_target_met, created_by, created_at, updated_by, updated_at')
        .order('chart_date', ascending: false);

    if (serviceUserId != null) {
      query = query.eq('service_user_id', serviceUserId);
    }
    if (dateFrom != null) {
      query = query.gte('chart_date', dateFrom.toIso8601String());
    }
    if (dateTo != null) {
      query = query.lte('chart_date', dateTo.toIso8601String());
    }
    if (createdBy != null) {
      query = query.eq('created_by', createdBy);
    }

    final response = await query;
    
    if (response.error != null) {
      throw Exception('Error fetching filtered charts: ${response.error}');
    }
    
    return (response.data as List)
        .map((c) => FoodFluidChartSummary.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // Delete chart (with audit trail)
  Future<void> deleteChart(String id, String userId) async {
    // Get current data for audit log
    final current = await getChart(id);
    
    // Create audit log entry for deletion
    final auditResponse = await _client.from('food_fluid_audit_logs').insert({
      'chart_id': id,
      'edited_by': userId,
      'previous_data': current.toJson(),
      'new_data': {'deleted': true, 'deleted_at': DateTime.now().toIso8601String()},
      'edited_at': DateTime.now().toIso8601String(),
    });
    
    if (auditResponse.error != null) {
      throw Exception('Error creating deletion audit log: ${auditResponse.error}');
    }

    // Delete the chart
    final deleteResponse = await _client
        .from('food_fluid_charts')
        .delete()
        .eq('id', id);
    
    if (deleteResponse.error != null) {
      throw Exception('Error deleting food & fluid chart: ${deleteResponse.error}');
    }
  }

  // Get charts for a specific date range
  Future<List<FoodFluidChart>> getChartsForDateRange(String serviceUserId, DateTime startDate, DateTime endDate) async {
    final response = await _client
        .from('food_fluid_charts')
        .select('*')
        .eq('service_user_id', serviceUserId)
        .gte('chart_date', startDate.toIso8601String())
        .lte('chart_date', endDate.toIso8601String())
        .order('chart_date', ascending: true);
    
    if (response.error != null) {
      throw Exception('Error fetching charts for date range: ${response.error}');
    }
    
    return (response.data as List)
        .map((c) => FoodFluidChart.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // Get daily average fluid intake for a service user
  Future<Map<String, dynamic>> getDailyAverageFluidIntake(String serviceUserId, DateTime startDate, DateTime endDate) async {
    final response = await _client.rpc('get_daily_average_fluid_intake', {
      'service_user_id': serviceUserId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    });
    
    if (response.error != null) {
      throw Exception('Error fetching daily average: ${response.error}');
    }
    
    return response.data as Map<String, dynamic>;
  }
}
