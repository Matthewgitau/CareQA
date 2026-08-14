import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/sleep_chart.dart';

class SleepService {
  final SupabaseClient _client;

  SleepService(this._client);

  // Get all charts for a service user
  Future<List<SleepChart>> getChartsForServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('sleep_charts')
          .select('*, profiles!created_by(full_name)')
          .eq('service_user_id', serviceUserId)
          .order('chart_date', ascending: false);
      
      return (data as List)
          .map((c) => SleepChart.fromJson(c as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching sleep charts: ${e.message}');
    }
  }

  // Get chart summaries for a service user
  Future<List<SleepChartSummary>> getChartSummariesForServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('sleep_charts')
          .select('id, service_user_id, chart_date, sleep_quality, created_by, created_at, updated_by, updated_at')
          .eq('service_user_id', serviceUserId)
          .order('chart_date', ascending: false);
      
      return (data as List)
          .map((c) => SleepChartSummary.fromJson(c as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching sleep chart summaries: ${e.message}');
    }
  }

  // Get single chart by ID
  Future<SleepChart> getChart(String id) async {
    try {
      final data = await _client
          .from('sleep_charts')
          .select('*')
          .eq('id', id)
          .single();
      
      return SleepChart.fromJson(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Error fetching sleep chart: ${e.message}');
    }
  }

  // Create new chart (carer)
  Future<String> createChart(SleepChart chart, String userId) async {
    try {
      final data = await _client
          .from('sleep_charts')
          .insert({
            ...chart.toJson(),
            'created_by': userId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      return (data as Map<String, dynamic>)['id'] as String;
    } on PostgrestException catch (e) {
      throw Exception('Error creating sleep chart: ${e.message}');
    }
  }

  // Update existing chart (admin only) - logs changes
  Future<void> updateChart(String id, Map<String, dynamic> updates, String userId) async {
    // Get current data for audit log
    final current = await getChart(id);
    
    try {
      // Update chart
      await _client
          .from('sleep_charts')
          .update({
            ...updates,
            'updated_by': userId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      // Create audit log entry
      await _client.from('sleep_audit_logs').insert({
        'chart_id': id,
        'edited_by': userId,
        'previous_data': current.toJson(),
        'new_data': updates,
        'edited_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw Exception('Error updating sleep chart: ${e.message}');
    }
  }

  // Get audit log for a chart
  Future<List<SleepAuditLog>> getAuditLog(String chartId) async {
    try {
      final data = await _client
          .from('sleep_audit_logs')
          .select('*, profiles!edited_by(full_name)')
          .eq('chart_id', chartId)
          .order('edited_at', ascending: false);
      
      return (data as List)
          .map((log) => SleepAuditLog.fromJson(log as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching audit log: ${e.message}');
    }
  }

  // Get charts with pagination and filtering
  Future<List<SleepChartSummary>> getChartsWithFilter({
    String? serviceUserId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? createdBy,
    String? sleepQuality,
    bool? hasDistressingObservations,
  }) async {
    var query = _client
        .from('sleep_charts')
        .select('id, service_user_id, chart_date, sleep_quality, created_by, created_at, updated_by, updated_at');

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
    if (sleepQuality != null) {
      query = query.eq('sleep_quality', sleepQuality);
    }
    if (hasDistressingObservations != null) {
      query = query.eq('has_distressing_observations', hasDistressingObservations);
    }

    try {
      final data = await query.order('chart_date', ascending: false);
      
      return (data as List)
          .map((c) => SleepChartSummary.fromJson(c as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching filtered charts: ${e.message}');
    }
  }

  // Delete chart (with audit trail)
  Future<void> deleteChart(String id, String userId) async {
    // Get current data for audit log
    final current = await getChart(id);
    
    try {
      // Create audit log entry for deletion
      await _client.from('sleep_audit_logs').insert({
        'chart_id': id,
        'edited_by': userId,
        'previous_data': current.toJson(),
        'new_data': {'deleted': true, 'deleted_at': DateTime.now().toIso8601String()},
        'edited_at': DateTime.now().toIso8601String(),
      });

      // Delete the chart
      await _client
          .from('sleep_charts')
          .delete()
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error deleting sleep chart: ${e.message}');
    }
  }

  // Get charts for a specific date range
  Future<List<SleepChart>> getChartsForDateRange(String serviceUserId, DateTime startDate, DateTime endDate) async {
    try {
      final data = await _client
          .from('sleep_charts')
          .select('*')
          .eq('service_user_id', serviceUserId)
          .gte('chart_date', startDate.toIso8601String())
          .lte('chart_date', endDate.toIso8601String())
          .order('chart_date', ascending: true);
      
      return (data as List)
          .map((c) => SleepChart.fromJson(c as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching charts for date range: ${e.message}');
    }
  }

  // Get charts with distressing observations
  Future<List<SleepChartSummary>> getChartsWithDistressingObservations(String serviceUserId) async {
    try {
      final data = await _client
          .from('sleep_charts')
          .select('id, service_user_id, chart_date, sleep_quality, created_by, created_at, updated_by, updated_at')
          .eq('service_user_id', serviceUserId)
          .eq('has_distressing_observations', true)
          .order('chart_date', ascending: false);
      
      return (data as List)
          .map((c) => SleepChartSummary.fromJson(c as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching charts with distressing observations: ${e.message}');
    }
  }

  // Get average sleep quality
  Future<Map<String, dynamic>> getAverageSleepQuality(String serviceUserId, DateTime startDate, DateTime endDate) async {
    try {
      final data = await _client.rpc('get_average_sleep_quality', params: {
        'service_user_id': serviceUserId,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      });
      
      return data as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      throw Exception('Error fetching average sleep quality: ${e.message}');
    }
  }

  // Get observation statistics
  Future<Map<String, dynamic>> getObservationStatistics(String serviceUserId, DateTime startDate, DateTime endDate) async {
    try {
      final data = await _client.rpc('get_observation_statistics', params: {
        'service_user_id': serviceUserId,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      });
      
      return data as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      throw Exception('Error fetching observation statistics: ${e.message}');
    }
  }
}