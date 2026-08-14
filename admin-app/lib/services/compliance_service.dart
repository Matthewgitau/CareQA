import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/compliance_flag.dart';
import 'package:admin_app/models/compliance_score.dart';
import 'package:admin_app/models/teaching_moment.dart';
import 'package:admin_app/models/regulatory_report.dart';

/// Simple in-memory cache entry.
class _CacheEntry<T> {
  final T data;
  final DateTime storedAt;
  _CacheEntry(this.data) : storedAt = DateTime.now();
  bool get isExpired => DateTime.now().difference(storedAt) > _cacheDuration;
}

const Duration _cacheDuration = Duration(minutes: 5);

class ComplianceService {
  final SupabaseClient _client;

  ComplianceService(this._client);

  // ──────────────────────────────────────────────────────────
  //  In-memory cache
  // ──────────────────────────────────────────────────────────
  final Map<String, _CacheEntry<dynamic>> _cache = {};

  T? _getCached<T>(String key) {
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) return entry.data as T;
    _cache.remove(key);
    return null;
  }

  void _setCache<T>(String key, T data) {
    _cache[key] = _CacheEntry<T>(data);
  }

  void clearCache() => _cache.clear();

  // ──────────────────────────────────────────────────────────
  //  Compliance Flags
  // ──────────────────────────────────────────────────────────
  Future<List<ComplianceFlag>> getComplianceFlags() async {
    try {
      final data = await _client
          .from('compliance_flags')
          .select('*, carers(name), shifts(scheduled_date, service_users(name))')
          .order('created_at', ascending: false);
      return (data as List)
          .map((flag) => ComplianceFlag.fromMap(flag as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<ComplianceFlag>> getComplianceFlagsByCarer(String carerId) async {
    try {
      final data = await _client
          .from('compliance_flags')
          .select('*, carers(name), shifts(scheduled_date, service_users(name))')
          .eq('carer_id', carerId)
          .order('created_at', ascending: false);
      return (data as List)
          .map((flag) => ComplianceFlag.fromMap(flag as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> updateComplianceFlagStatus(
    String flagId,
    String status,
    String? acknowledgedBy,
    String? resolvedBy,
  ) async {
    try {
      await _client.from('compliance_flags').update({
        'status': status,
        if (acknowledgedBy != null) 'acknowledged_by': acknowledgedBy,
        if (acknowledgedBy != null) 'acknowledged_at': DateTime.now(),
        if (resolvedBy != null) 'resolved_by': resolvedBy,
        if (resolvedBy != null) 'resolved_at': DateTime.now(),
      }).eq('id', flagId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // ──────────────────────────────────────────────────────────
  //  Compliance Scores
  // ──────────────────────────────────────────────────────────
  Future<List<ComplianceScore>> getComplianceScores() async {
    try {
      final data = await _client
          .from('compliance_scores')
          .select('*, carers(name)')
          .order('score_date', ascending: false);
      return (data as List)
          .map((score) =>
              ComplianceScore.fromMap(score as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<ComplianceScore>> getComplianceScoresByCarer(
      String carerId) async {
    try {
      final data = await _client
          .from('compliance_scores')
          .select()
          .eq('carer_id', carerId)
          .order('score_date', ascending: false);
      return (data as List)
          .map((score) =>
              ComplianceScore.fromMap(score as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // ──────────────────────────────────────────────────────────
  //  Dashboard-specific helpers
  // ──────────────────────────────────────────────────────────

  /// Returns the 16-category aggregated scores for the whole care home.
  /// Result: { overall_score, carer_count, category_scores: { … }, period_start, period_end }
  Future<Map<String, dynamic>> getDashboardCategoryScores({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final s = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final e = endDate ?? DateTime.now();
    final cacheKey =
        'dashboard_categories_${s.toIso8601String()}_${e.toIso8601String()}';

    final cached = _getCached<Map<String, dynamic>>(cacheKey);
    if (cached != null) return cached;

    try {
      final data = await _client.rpc('get_dashboard_category_scores', params: {
        'p_start_date': s.toIso8601String().substring(0, 10),
        'p_end_date': e.toIso8601String().substring(0, 10),
      });
      final result = Map<String, dynamic>.from(data as Map);
      _setCache(cacheKey, result);
      return result;
    } catch (_) {
      return {
        'overall_score': 0,
        'carer_count': 0,
        'category_scores': <String, dynamic>{},
      };
    }
  }

  /// Calculate a single carer's compliance score from the 16 data sources.
  Future<Map<String, dynamic>> getCarerComplianceScore(
    String carerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final s = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final e = endDate ?? DateTime.now();

    try {
      final data =
          await _client.rpc('calculate_carer_compliance_score', params: {
        'p_carer_id': carerId,
        'p_start_date': s.toIso8601String().substring(0, 10),
        'p_end_date': e.toIso8601String().substring(0, 10),
      });
      return Map<String, dynamic>.from(data as Map);
    } catch (_) {
      return {
        'overall_score': 0,
        'category_scores': <String, dynamic>{},
      };
    }
  }

  /// Trend data for the line chart.
  /// Returns a list of { period, avg_score, min_score, max_score, flag_count }.
  Future<List<Map<String, dynamic>>> getComplianceTrends({
    String interval = 'weekly',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final s = startDate ?? DateTime.now().subtract(const Duration(days: 180));
    final e = endDate ?? DateTime.now();
    final cacheKey =
        'trends_${interval}_${s.toIso8601String()}_${e.toIso8601String()}';

    final cached = _getCached<List<Map<String, dynamic>>>(cacheKey);
    if (cached != null) return cached;

    try {
      final data = await _client.rpc('get_compliance_trends_data', params: {
        'p_interval': interval,
        'p_start_date': s.toIso8601String().substring(0, 10),
        'p_end_date': e.toIso8601String().substring(0, 10),
      });
      final list = (data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _setCache(cacheKey, list);
      return list;
    } catch (_) {
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────
  //  Teaching Moments
  // ──────────────────────────────────────────────────────────
  Future<List<TeachingMoment>> getTeachingMoments() async {
    try {
      final data = await _client
          .from('teaching_moments')
          .select('*, profiles(full_name)')
          .order('created_at', ascending: false);
      return (data as List)
          .map((moment) =>
              TeachingMoment.fromMap(moment as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<TeachingMoment>> getTeachingMomentsByUser(String userId) async {
    try {
      final data = await _client
          .from('teaching_moments')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (data as List)
          .map((moment) =>
              TeachingMoment.fromMap(moment as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> updateTeachingMoment(
    String momentId,
    bool quizPassed,
    DateTime? viewedAt,
    DateTime? completedAt,
  ) async {
    try {
      await _client.from('teaching_moments').update({
        'quiz_passed': quizPassed,
        if (viewedAt != null) 'viewed_at': viewedAt,
        if (completedAt != null) 'completed_at': completedAt,
      }).eq('id', momentId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // ──────────────────────────────────────────────────────────
  //  Regulatory Reports
  // ──────────────────────────────────────────────────────────
  Future<List<RegulatoryReport>> getRegulatoryReports() async {
    try {
      final data = await _client
          .from('regulatory_reports')
          .select()
          .order('generated_at', ascending: false);
      return (data as List)
          .map((report) =>
              RegulatoryReport.fromMap(report as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<RegulatoryReport> generateRegulatoryReport(
    String reportType,
    DateTime periodStart,
    DateTime periodEnd,
    String generatedBy,
  ) async {
    try {
      final response = await _client.rpc('generate_regulatory_report', params: {
        'report_type_param': reportType,
        'period_start': periodStart,
        'period_end': periodEnd,
        'generated_by_param': generatedBy,
      });

      final reportResponse = await _client
          .from('regulatory_reports')
          .select()
          .eq('id', response)
          .single();

      return RegulatoryReport.fromMap(reportResponse as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> submitRegulatoryReport(String reportId) async {
    try {
      await _client.from('regulatory_reports').update({
        'submitted': true,
        'submitted_at': DateTime.now(),
      }).eq('id', reportId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // ──────────────────────────────────────────────────────────
  //  Compliance Summary / Insights (existing DB functions)
  // ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getComplianceSummary() async {
    try {
      final data = await _client.rpc('get_compliance_summary');
      return data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getComplianceInsights() async {
    try {
      final data = await _client.rpc('generate_compliance_insights');
      return data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────
  //  Escalation
  // ──────────────────────────────────────────────────────────
  Future<bool> escalateComplianceIssue(
    String flagId,
    String escalatedBy,
    String escalationNotes,
  ) async {
    try {
      final response = await _client.rpc('escalate_compliance_issue', params: {
        'flag_id': flagId,
        'escalated_by': escalatedBy,
        'escalation_notes': escalationNotes,
      });
      return response as bool;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<bool> resolveComplianceFlag(
    String flagId,
    String resolvedBy,
    String resolutionNotes,
  ) async {
    try {
      final response = await _client.rpc('resolve_compliance_flag', params: {
        'flag_id': flagId,
        'resolved_by': resolvedBy,
        'resolution_notes': resolutionNotes,
      });
      return response as bool;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // ──────────────────────────────────────────────────────────
  //  Compliance Settings
  // ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getComplianceSettings() async {
    try {
      final data = await _client.rpc('get_compliance_settings');
      return data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateComplianceSettings(Map<String, dynamic> newSettings) async {
    try {
      final response = await _client.rpc('update_compliance_settings', params: {
        'new_settings': newSettings,
      });
      return response as bool;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<bool> validateComplianceSettings(
      Map<String, dynamic> settings) async {
    try {
      final response = await _client.rpc('validate_compliance_settings', params: {
        'settings': settings,
      });
      return response as bool;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}