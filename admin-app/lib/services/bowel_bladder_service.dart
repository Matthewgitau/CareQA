import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/bowel_bladder_chart.dart';

class BowelBladderService {
  final SupabaseClient _client;

  BowelBladderService(this._client);

  // Get all charts for a service user
  Future<List<BowelBladderChart>> getChartsForServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('bowel_bladder_charts')
          .select('*, profiles!created_by(full_name)')
          .eq('service_user_id', serviceUserId)
          .order('chart_date', ascending: false);
      
      return (data as List)
          .map((c) => BowelBladderChart.fromJson(c as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching bowel & bladder charts: ${e.message}');
    }
  }

  // Get chart summaries for a service user
  Future<List<BowelBladderChartSummary>> getChartSummariesForServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('bowel_bladder_charts')
          .select('id, service_user_id, chart_date, days_since_last_bowel, warning_triggered, created_by, created_at, updated_by, updated_at')
          .eq('service_user_id', serviceUserId)
          .order('chart_date', ascending: false);
      
      return (data as List)
          .map((c) => BowelBladderChartSummary.fromJson(c as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching bowel & bladder chart summaries: ${e.message}');
    }
  }

  // Get single chart by ID
  Future<BowelBladderChart> getChart(String id) async {
    try {
      final data = await _client
          .from('bowel_bladder_charts')
          .select('*')
          .eq('id', id)
          .single();
      
      return BowelBladderChart.fromJson(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Error fetching bowel & bladder chart: ${e.message}');
    }
  }

  // Create new chart (carer)
  Future<String> createChart(BowelBladderChart chart, String userId) async {
    try {
      final data = await _client
          .from('bowel_bladder_charts')
          .insert({
            ...chart.toJson(),
            'created_by': userId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      return (data as Map<String, dynamic>)['id'] as String;
    } on PostgrestException catch (e) {
      throw Exception('Error creating bowel & bladder chart: ${e.message}');
    }
  }

  // Update existing chart (admin only) - logs changes
  Future<void> updateChart(String id, Map<String, dynamic> updates, String userId) async {
    // Get current data for audit log
    final current = await getChart(id);
    
    try {
      // Update chart
      await _client
          .from('bowel_bladder_charts')
          .update({
            ...updates,
            'updated_by': userId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      // Create audit log entry
      await _client.from('bowel_bladder_audit_logs').insert({
        'chart_id': id,
        'edited_by': userId,
        'previous_data': current.toJson(),
        'new_data': updates,
        'edited_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw Exception('Error updating bowel & bladder chart: ${e.message}');
    }
  }

  // Get audit log for a chart
  Future<List<BowelBladderAuditLog>> getAuditLog(String chartId) async {
    try {
      final data = await _client
          .from('bowel_bladder_audit_logs')
          .select('*, profiles!edited_by(full_name)')
          .eq('chart_id', chartId)
          .order('edited_at', ascending: false);
      
      return (data as List)
          .map((log) => BowelBladderAuditLog.fromJson(log as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching audit log: ${e.message}');
    }
  }

  // Get charts with pagination and filtering
  Future<List<BowelBladderChartSummary>> getChartsWithFilter({
    String? serviceUserId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? createdBy,
    bool? warningTriggered,
  }) async {
    var query = _client
        .from('bowel_bladder_charts')
        .select('id, service_user_id, chart_date, days_since_last_bowel, warning_triggered, created_by, created_at, updated_by, updated_at');

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
    if (warningTriggered != null) {
      query = query.eq('warning_triggered', warningTriggered);
    }

    try {
      final data = await query.order('chart_date', ascending: false);
      
      return (data as List)
          .map((c) => BowelBladderChartSummary.fromJson(c as Map<String, dynamic>))
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
      await _client.from('bowel_bladder_audit_logs').insert({
        'chart_id': id,
        'edited_by': userId,
        'previous_data': current.toJson(),
        'new_data': {'deleted': true, 'deleted_at': DateTime.now().toIso8601String()},
        'edited_at': DateTime.now().toIso8601String(),
      });

      // Delete the chart
      await _client
          .from('bowel_bladder_charts')
          .delete()
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error deleting bowel & bladder chart: ${e.message}');
    }
  }

  // Get charts for a specific date range
  Future<List<BowelBladderChart>> getChartsForDateRange(String serviceUserId, DateTime startDate, DateTime endDate) async {
    try {
      final data = await _client
          .from('bowel_bladder_charts')
          .select('*')
          .eq('service_user_id', serviceUserId)
          .gte('chart_date', startDate.toIso8601String())
          .lte('chart_date', endDate.toIso8601String())
          .order('chart_date', ascending: true);
      
      return (data as List)
          .map((c) => BowelBladderChart.fromJson(c as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching charts for date range: ${e.message}');
    }
  }

  // Get charts with warnings
  Future<List<BowelBladderChartSummary>> getChartsWithWarnings(String serviceUserId) async {
    try {
      final data = await _client
          .from('bowel_bladder_charts')
          .select('id, service_user_id, chart_date, days_since_last_bowel, warning_triggered, created_by, created_at, updated_by, updated_at')
          .eq('service_user_id', serviceUserId)
          .eq('warning_triggered', true)
          .order('chart_date', ascending: false);
      
      return (data as List)
          .map((c) => BowelBladderChartSummary.fromJson(c as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching charts with warnings: ${e.message}');
    }
  }

  // Get average days since last bowel movement
  Future<Map<String, dynamic>> getAverageDaysSinceLastBowel(String serviceUserId, DateTime startDate, DateTime endDate) async {
    try {
      final data = await _client.rpc('get_average_days_since_last_bowel', params: {
        'service_user_id': serviceUserId,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      });
      
      return data as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      throw Exception('Error fetching average days: ${e.message}');
    }
  }
}