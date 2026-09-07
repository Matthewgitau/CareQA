import 'package:supabase_flutter/supabase_flutter.dart';

/// Queries all care recording tables for a service user on a given date.
/// Used by the shift detail screen to show what's already been logged.
class CareLogSummaryService {
  final SupabaseClient _client;
  CareLogSummaryService(this._client);

  Future<Map<String, dynamic>> getLogs({
    required String serviceUserId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T').first;
    final dayStart = '${dateStr}T00:00:00Z';
    final dayEnd = '${dateStr}T23:59:59Z';
    final results = <String, dynamic>{
      'daily_notes': 0,
      'food_fluid': 0,
      'bowel_bladder': 0,
      'repositioning': 0,
      'sleep': 0,
      'body_map': 0,
      'mar': 0,
    };

    try {
      final dailyNotes = await _client.from('daily_notes').select('id')
          .eq('service_user_id', serviceUserId)
          .eq('visit_date', dateStr);
      results['daily_notes'] = (dailyNotes as List).length;
    } catch (_) {}

    try {
      final foodFluid = await _client.from('food_fluid_charts').select('id')
          .eq('service_user_id', serviceUserId)
          .gte('assessment_date', dayStart)
          .lte('assessment_date', dayEnd);
      results['food_fluid'] = (foodFluid as List).length;
    } catch (_) {}

    try {
      final bowelBladder = await _client.from('bowel_bladder_charts').select('id')
          .eq('service_user_id', serviceUserId)
          .gte('assessment_date', dayStart)
          .lte('assessment_date', dayEnd);
      results['bowel_bladder'] = (bowelBladder as List).length;
    } catch (_) {}

    try {
      final repositioning = await _client.from('repositioning_charts').select('id')
          .eq('service_user_id', serviceUserId)
          .gte('assessment_date', dayStart)
          .lte('assessment_date', dayEnd);
      results['repositioning'] = (repositioning as List).length;
    } catch (_) {}

    try {
      final sleep = await _client.from('sleep_charts').select('id')
          .eq('service_user_id', serviceUserId)
          .gte('assessment_date', dayStart)
          .lte('assessment_date', dayEnd);
      results['sleep'] = (sleep as List).length;
    } catch (_) {}

    try {
      final bodyMap = await _client.from('body_map_assessments').select('id')
          .eq('service_user_id', serviceUserId)
          .gte('created_at', dayStart)
          .lte('created_at', dayEnd);
      results['body_map'] = (bodyMap as List).length;
    } catch (_) {}

    try {
      final marLogs = await _client.from('mar_administration_logs').select('id')
          .eq('service_user_id', serviceUserId)
          .gte('scheduled_time', dayStart)
          .lte('scheduled_time', dayEnd);
      results['mar'] = (marLogs as List).length;
    } catch (_) {}

    return results;
  }
}