import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import '../models/care_record.dart';
import '../utils/supabase_client.dart';

class CareRecordService {
  final SupabaseClient _client = SupabaseManager.instance.client;

  Future<List<CareRecord>> getCareRecords(String serviceUserId) async {
    try {
      final response = await _client
          .from('care_records')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => CareRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load care records: $e');
    }
  }

  Future<CareRecord> getCareRecordById(String id) async {
    try {
      final response = await _client
          .from('care_records')
          .select()
          .eq('id', id)
          .single();

      return CareRecord.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load care record: $e');
    }
  }

  Future<List<CareRecord>> getCarePlan(String serviceUserId) async {
    try {
      final response = await _client
          .from('care_records')
          .select()
          .eq('service_user_id', serviceUserId)
          .eq('type', 'care_plan')
          .order('date', ascending: false);

      return (response as List)
          .map((json) => CareRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load care plan: $e');
    }
  }
}