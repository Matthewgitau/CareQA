import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/shift.dart';

class ShiftService {
  final SupabaseClient _client;

  ShiftService(this._client);

  /// Resolves the current auth user to their carers.id.
  Future<String?> _getMyCarerId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final direct = await _client.from('carers').select('id').eq('id', uid).maybeSingle();
    if (direct != null) return uid;
    final legacy = await _client.from('carers').select('id').eq('auth_user_id', uid).maybeSingle();
    if (legacy != null) return legacy['id'] as String?;
    return null;
  }

  /// Get shifts assigned to the current carer
  Future<List<Shift>> getShiftsForCurrentCarer() async {
    final carerId = await _getMyCarerId();
    if (carerId == null) return [];
    final response = await _client
        .from('shifts')
        .select('*, service_users(name, address), carers(name)')
        .eq('carer_id', carerId)
        .order('scheduled_date', ascending: true)
        .order('start_time', ascending: true);
    return (response as List)
        .map((json) => Shift.fromMap(json as Map<String, dynamic>))
        .toList();
  }

  /// Get shifts for a specific date
  Future<List<Shift>> getShiftsForDate(DateTime date) async {
    final carerId = await _getMyCarerId();
    if (carerId == null) return [];
    final dateStr = date.toIso8601String().split('T').first;
    final response = await _client
        .from('shifts')
        .select('*, service_users(name, address), carers(name)')
        .eq('carer_id', carerId)
        .eq('scheduled_date', dateStr)
        .order('start_time', ascending: true);
    return (response as List)
        .map((json) => Shift.fromMap(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a single shift by ID
  Future<Shift> getShiftById(String shiftId) async {
    final response = await _client
        .from('shifts')
        .select('*, service_users(name, address), carers(name)')
        .eq('id', shiftId)
        .single();
    return Shift.fromMap(response);
  }

  /// Returns the current carer's DOM CARE ROUTE calls (from `route_visits`).
  ///
  /// Covers ALL THREE assignment models via RLS:
  ///   - Per-visit assignment:  route_visits.carer_id resolves to auth user
  ///   - Route primary carer:   routes.carer_id resolves to auth user
  ///   - Route second carer:    routes.second_carer_id resolves to auth user
  ///
  /// RLS handles ALL filtering server-side. No manual carer filter needed.
  Future<List<Shift>> getRouteCallsForCurrentCarer() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final response = await _client
        .from('route_visits')
        .select('*, service_users(name, address), carers(name), routes(name)')
        .not('status', 'eq', 'cancelled')
        .order('visit_time', ascending: true);
    return (response as List)
        .map((row) => Shift.fromRouteCall(row as Map<String, dynamic>))
        .toList();
  }

  /// Accept a shift
  Future<void> acceptShift(String shiftId) async {
    await _client
        .from('shifts')
        .update({'status': 'confirmed'})
        .eq('id', shiftId);
  }

  /// Decline a shift
  Future<void> declineShift(String shiftId) async {
    await _client
        .from('shifts')
        .update({'status': 'declined'})
        .eq('id', shiftId);
  }
}