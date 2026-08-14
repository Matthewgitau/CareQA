import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import '../models/visit_log.dart';
import '../utils/supabase_client.dart';

class VisitLogService {
  final SupabaseClient _client = SupabaseManager.instance.client;

  Future<List<VisitLog>> getVisitLogs(String organisationId) async {
    try {
      final response = await _client
          .from('visit_logs')
          .select('*, service_user:service_users(*)')
          .eq('organisation_id', organisationId)
          .order('visit_start', ascending: false);

      return (response as List)
          .map((json) => VisitLog.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load visit logs: $e');
    }
  }

  Future<VisitLog> getVisitLogById(String id) async {
    try {
      final response = await _client
          .from('visit_logs')
          .select()
          .eq('id', id)
          .single();

      return VisitLog.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load visit log: $e');
    }
  }
}