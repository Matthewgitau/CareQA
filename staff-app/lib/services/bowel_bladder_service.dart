import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/bowel_bladder_chart.dart';

class BowelBladderService {
  final SupabaseClient _client;

  BowelBladderService(this._client);

  // Get all charts for a service user
  Future<List<BowelBladderChart>> getChartsForServiceUser(String serviceUserId) async {
    final response = await _client
        .from('bowel_bladder_charts')
        .select('*, profiles!created_by(full_name)')
        .eq('service_user_id', serviceUserId)
        .order('chart_date', ascending: false);
    
    if (response.error != null) {
      throw Exception('Error fetching bowel & bladder charts: ${response.error}');
    }
    
    return (response.data as List)
        .map((c) => BowelBladderChart.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // Get chart summaries for a service user
  Future<List<BowelBladderChartSummary>> getChartSummariesForServiceUser(String serviceUserId) async {
    final response = await _client
        .from('bowel_bladder_charts')
        .select('id, service_user_id, chart_date, days_since_last_bowel, warning_triggered, created_by, created_at, updated_by, updated_at')
        .eq('service_user_id', serviceUserId)
        .order('chart_date', ascending: false);
    
    if (response.error != null) {
      throw Exception('Error fetching bowel & bladder chart summaries: ${response.error}');
    }
    
    return (response.data as List)
        .map((c) => BowelBladderChartSummary.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // Get single chart by ID
  Future<BowelBladderChart> getChart(String id) async {
    final response = await _client
        .from('bowel_bladder_charts')
        .select('*')
        .eq('id', id)
        .single();
    
    if (response.error != null) {
      throw Exception('Error fetching bowel & bladder chart: ${response.error}');
    }
    
    return BowelBladderChart.fromJson(response.data as Map<String, dynamic>);
  }

  // Create new chart (carer)
  Future<String> createChart(BowelBladderChart chart, String userId) async {
    final response = await _client
        .from('bowel_bladder_charts')
        .insert({
          ...chart.toJson(),
          'created_by': userId,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    
    if (response.error != null) {
      throw Exception('Error creating bowel & bladder chart: ${response.error}');
    }
    
    return response.data['id'] as String;
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
        .select('id, service_user_id, chart_date, days_since_last_bowel, warning_triggered, created_by, created_at, updated_by, updated_at')
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
    if (warningTriggered != null) {
      query = query.eq('warning_triggered', warningTriggered);
    }

    final response = await query;
    
    if (response.error != null) {
      throw Exception('Error fetching filtered charts: ${response.error}');
    }
    
    return (response.data as List)
        .map((c) => BowelBladderChartSummary.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // Get charts for a specific date range
  Future<List<BowelBladderChart>> getChartsForDateRange(String serviceUserId, DateTime startDate, DateTime endDate) async {
    final response = await _client
        .from('bowel_bladder_charts')
        .select('*')
        .eq('service_user_id', serviceUserId)
        .gte('chart_date', startDate.toIso8601String())
        .lte('chart_date', endDate.toIso8601String())
        .order('chart_date', ascending: true);
    
    if (response.error != null) {
      throw Exception('Error fetching charts for date range: ${response.error}');
    }
    
    return (response.data as List)
        .map((c) => BowelBladderChart.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // Get charts with warnings
  Future<List<BowelBladderChartSummary>> getChartsWithWarnings(String serviceUserId) async {
    final response = await _client
        .from('bowel_bladder_charts')
        .select('id, service_user_id, chart_date, days_since_last_bowel, warning_triggered, created_by, created_at, updated_by, updated_at')
        .eq('service_user_id', serviceUserId)
        .eq('warning_triggered', true)
        .order('chart_date', ascending: false);
    
    if (response.error != null) {
      throw Exception('Error fetching charts with warnings: ${response.error}');
    }
    
    return (response.data as List)
        .map((c) => BowelBladderChartSummary.fromJson(c as Map<String, dynamic>))
        .toList();
  }
}

class BowelBladderChartSummary {
  final String id;
  final String serviceUserId;
  final DateTime chartDate;
  final int daysSinceLastBowel;
  final bool warningTriggered;
  final int bowelEntryCount;
  final int bladderEntryCount;
  final int totalBladderVolume;
  final bool hasIncontinence;
  final String? createdBy;
  final DateTime? createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;

  BowelBladderChartSummary({
    required this.id,
    required this.serviceUserId,
    required this.chartDate,
    required this.daysSinceLastBowel,
    required this.warningTriggered,
    required this.bowelEntryCount,
    required this.bladderEntryCount,
    required this.totalBladderVolume,
    required this.hasIncontinence,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
  });

  factory BowelBladderChartSummary.fromJson(Map<String, dynamic> json) => BowelBladderChartSummary(
    id: json['id'],
    serviceUserId: json['service_user_id'],
    chartDate: DateTime.parse(json['chart_date']),
    daysSinceLastBowel: json['days_since_last_bowel'] ?? 0,
    warningTriggered: json['warning_triggered'] ?? false,
    bowelEntryCount: json['bowel_entry_count'] ?? 0,
    bladderEntryCount: json['bladder_entry_count'] ?? 0,
    totalBladderVolume: json['total_bladder_volume'] ?? 0,
    hasIncontinence: json['has_incontinence'] ?? false,
    createdBy: json['created_by'],
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    updatedBy: json['updated_by'],
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
  );
}

class BowelBladderAuditLog {
  final String id;
  final String chartId;
  final String editedBy;
  final Map<String, dynamic> previousData;
  final Map<String, dynamic> newData;
  final DateTime editedAt;
  final String? editedByName;

  BowelBladderAuditLog({
    required this.id,
    required this.chartId,
    required this.editedBy,
    required this.previousData,
    required this.newData,
    required this.editedAt,
    this.editedByName,
  });

  factory BowelBladderAuditLog.fromJson(Map<String, dynamic> json) => BowelBladderAuditLog(
    id: json['id'],
    chartId: json['chart_id'],
    editedBy: json['edited_by'],
    previousData: Map<String, dynamic>.from(json['previous_data'] ?? {}),
    newData: Map<String, dynamic>.from(json['new_data'] ?? {}),
    editedAt: DateTime.parse(json['edited_at']),
    editedByName: json['profiles']?['full_name'],
  );
}