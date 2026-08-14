import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/spot_check.dart';

class SpotCheckService {
  final SupabaseClient _client;

  SpotCheckService(this._client);

  Future<List<SpotCheck>> getSpotChecks({
    String? serviceUserId, String? carerId,
    DateTime? startDate, DateTime? endDate,
    String? competencyRating, String? status,
  }) async {
    var query = _client.from('spot_checks').select();
    if (serviceUserId != null) query = query.eq('service_user_id', serviceUserId);
    if (carerId != null) query = query.eq('carer_id', carerId);
    if (startDate != null) query = query.gte('spot_check_date', startDate.toIso8601String().split('T').first);
    if (endDate != null) query = query.lte('spot_check_date', endDate.toIso8601String().split('T').first);
    if (competencyRating != null && competencyRating != 'all') query = query.eq('competency_rating', competencyRating);
    if (status != null && status != 'all') query = query.eq('status', status);
    final data = await query.order('spot_check_date', ascending: false);
    return (data as List).map((i) => SpotCheck.fromMap(i as Map<String, dynamic>)).toList();
  }

  Future<SpotCheck> getSpotCheck(String id) async {
    final data = await _client.from('spot_checks').select().eq('id', id).single();
    return SpotCheck.fromMap(data as Map<String, dynamic>);
  }

  Future<SpotCheck> createSpotCheck(SpotCheck sc) async {
    final data = await _client.from('spot_checks').insert(sc.toMap()).select().single();
    return SpotCheck.fromMap(data as Map<String, dynamic>);
  }

  Future<SpotCheck> updateSpotCheck(String id, SpotCheck sc) async {
    final data = await _client.from('spot_checks').update(sc.toMap()).eq('id', id).select().single();
    return SpotCheck.fromMap(data as Map<String, dynamic>);
  }

  Future<void> deleteSpotCheck(String id) async {
    await _client.from('spot_checks').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getServiceUsers() async {
    try {
      final data = await _client
          .from('service_users')
          .select('id, name')
          .eq('is_active', true)
          .order('name');
      return (data as List).cast<Map<String, dynamic>>();
    } catch (_) {
      final data = await _client
          .from('service_users')
          .select('id, name')
          .order('name');
      return (data as List).cast<Map<String, dynamic>>();
    }
  }

  /// Load carers from the public.carers table (RLS filters by organisation)
  Future<List<Map<String, dynamic>>> getCarers() async {
    try {
      final data = await _client
          .from('carers')
          .select('id, name, job_role')
          .eq('is_active', true)
          .order('name');
      return (data as List).cast<Map<String, dynamic>>();
    } catch (_) {
      // Fallback to service_users is_carer if carers table query fails
      try {
        final data = await _client
            .from('service_users')
            .select('id, name, job_role')
            .eq('is_active', true)
            .eq('is_carer', true)
            .order('name');
        return (data as List).cast<Map<String, dynamic>>();
      } catch (_) {
        return [];
      }
    }
  }

  /// Load admin/office staff from public.profiles for "Assign To" dropdown
  Future<List<Map<String, dynamic>>> getAdminStaff() async {
    try {
      final data = await _client
          .from('profiles')
          .select('id, name, role, email')
          .eq('is_active', true)
          .order('name');
      return (data as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}