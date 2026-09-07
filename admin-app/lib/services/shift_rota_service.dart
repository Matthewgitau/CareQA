import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/shift_rota.dart';
import 'package:admin_app/models/service_user.dart';
import 'package:admin_app/models/service_user_call.dart';
import 'package:admin_app/models/carer.dart';
import 'package:admin_app/services/shift_service.dart';

class ShiftRotaService {
  final SupabaseClient _client;

  ShiftRotaService(this._client);

  // Get all shift rotas
  Future<List<ShiftRota>> getShiftRotas() async {
    try {
      final data = await _client
          .from('shift_rotas')
          .select()
          .order('start_date', ascending: true);
      return (data as List).map((rota) => ShiftRota.fromMap(rota as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get shift rotas for a specific week
  Future<List<ShiftRota>> getShiftRotasForWeek(String weekRange) async {
    try {
      final data = await _client
          .from('shift_rotas')
          .select()
          .eq('week_range', weekRange)
          .order('start_date', ascending: true);
      return (data as List).map((rota) => ShiftRota.fromMap(rota as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get shift rotas for a specific carer
  Future<List<ShiftRota>> getShiftRotasForCarer(String carerId) async {
    try {
      final data = await _client
          .from('shift_rotas')
          .select()
          .eq('carer_id', carerId)
          .order('start_date', ascending: true);
      return (data as List).map((rota) => ShiftRota.fromMap(rota as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get shift rotas for a specific service user
  Future<List<ShiftRota>> getShiftRotasForServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('shift_rotas')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('start_date', ascending: true);
      return (data as List).map((rota) => ShiftRota.fromMap(rota as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Create a new shift rota
  Future<String> createShiftRota(ShiftRota shiftRota) async {
    try {
      final response = await _client.from('shift_rotas').insert(shiftRota.toMap()).select().single();
      return response['id'];
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Update an existing shift rota
  Future<void> updateShiftRota(String shiftRotaId, ShiftRota shiftRota) async {
    try {
      await _client.from('shift_rotas').update(shiftRota.toMap()).eq('id', shiftRotaId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Delete a shift rota
  Future<void> deleteShiftRota(String shiftRotaId) async {
    try {
      await _client.from('shift_rotas').delete().eq('id', shiftRotaId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get all service users
  Future<List<ServiceUser>> getServiceUsers() async {
    try {
      final data = await _client
          .from('service_users')
          .select()
          .order('created_at', ascending: false);
      return (data as List).map((user) => ServiceUser.fromMap(user as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get all carers
  Future<List<Carer>> getCarers() async {
    try {
      final data = await _client
          .from('carers')
          .select()
          .order('created_at', ascending: false);
      return (data as List).map((carer) => Carer.fromMap(carer as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get carers with specific qualifications
  Future<List<Carer>> getCarersByQualifications(List<String> requiredQualifications) async {
    try {
      final data = await _client
          .from('carers')
          .select();
      return (data as List)
          .map((carer) => Carer.fromMap(carer as Map<String, dynamic>))
          .where((carer) {
            // qualification filtering deferred to business logic phase
            return true;
          })
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Check for conflicts (double booking)
  Future<bool> checkForConflicts(String carerId, DateTime startDate, DateTime endDate, [String? excludeShiftId]) async {
    try {
      final query = _client
          .from('shift_rotas')
          .select()
          .eq('carer_id', carerId)
          .eq('status', 'Scheduled')
          .lt('start_date', endDate)
          .gt('end_date', startDate);

      if (excludeShiftId != null) {
        query.neq('id', excludeShiftId);
      }

      final response = await query;
      
      return (response as List).isNotEmpty;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get available carers for a specific time slot
  Future<List<Carer>> getAvailableCarers(DateTime startDate, DateTime endDate, List<String> requiredQualifications) async {
    try {
      // Get all carers with required qualifications
      final carersResponse = await _client.from('carers').select();
      
      final qualifiedCarers = (carersResponse as List)
          .map((carer) => Carer.fromMap(carer as Map<String, dynamic>))
          .where((carer) {
            // qualification filtering deferred to business logic phase
            return true;
          })
          .toList();

      // Check availability for each carer
      final availableCarers = <Carer>[];
      
      for (final carer in qualifiedCarers) {
        final hasConflict = await checkForConflicts(carer.id, startDate, endDate);
        if (!hasConflict) {
          availableCarers.add(carer);
        }
      }

      return availableCarers;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Create recurring shifts
  Future<void> createRecurringShifts(ShiftRota baseShift, int weeks) async {
    try {
      final weekDays = <DateTime>[];
      final baseDate = baseShift.startDate;
      
      // Get the day of week for the base shift
      final dayOfWeek = baseShift.dayOfWeek;
      
      // Calculate dates for the next 'weeks' weeks
      for (int i = 0; i < weeks; i++) {
        final targetDate = baseDate.add(Duration(days: i * 7));
        weekDays.add(targetDate);
      }

      // Create shifts for each week
      for (final date in weekDays) {
        final shift = ShiftRota(
          id: '',
          serviceUserId: baseShift.serviceUserId,
          carerId: baseShift.carerId,
          startDate: date,
          endDate: baseShift.endDate.add(Duration(days: (date.difference(baseShift.startDate).inDays))),
          shiftType: baseShift.shiftType,
          dayOfWeek: dayOfWeek,
          weekRange: _getWeekRange(date),
          notes: baseShift.notes,
          isRecurring: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: _client.auth.currentUser?.id ?? '',
          status: baseShift.status,
        );

        await createShiftRota(shift);
      }
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get week range string (e.g., "w/c 10 Mar 2026")
  String _getWeekRange(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));

    final startDay = startOfWeek.day;
    final startMonth = startOfWeek.month;
    final startYear = startOfWeek.year;

    return "w/c $startDay ${_getMonthName(startMonth)} $startYear";
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  // Get shifts for route optimization
  Future<List<ShiftRota>> getShiftsForRouteOptimization(String carerId, DateTime date) async {
    try {
      final weekRange = _getWeekRange(date);
      
      final response = await _client
          .from('shift_rotas')
          .select()
          .eq('carer_id', carerId)
          .eq('week_range', weekRange)
          .eq('status', 'Scheduled')
          .order('start_date');

      return (response as List)
          .map((rota) => ShiftRota.fromMap(rota as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Update shift status
  Future<void> updateShiftStatus(String shiftId, String status) async {
    try {
      await _client.from('shift_rotas').update({
        'status': status,
        'updated_at': DateTime.now(),
      }).eq('id', shiftId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get shifts by status for a carer
  Future<List<ShiftRota>> getShiftsByStatus(String carerId, String status) async {
    try {
      final data = await _client
          .from('shift_rotas')
          .select()
          .eq('carer_id', carerId)
          .eq('status', status)
          .order('start_date', ascending: true);
      return (data as List).map((rota) => ShiftRota.fromMap(rota as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get Dom Care Routes from public.service_user_calls
  // Each service user's call schedule (calls_per_day + call_times)
  // represents their planned domiciliary care visits.
  Future<List<ServiceUserCall>> getDomCareRoutes() async {
    try {
      final data = await _client
          .from('service_user_calls')
          .select('*, service_users(name)')
          .order('created_at', ascending: true);
      return (data as List)
          .map((json) => ServiceUserCall.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get Care Home Shifts from public.shifts
  Future<List<Shift>> getCareHomeShifts() async {
    try {
      final data = await _client
          .from('shifts')
          .select('*, service_users(name), carers(name)')
          .order('scheduled_date', ascending: true)
          .order('start_time', ascending: true);
      return (data as List)
          .map((json) => Shift.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Toggles a flag (respite/hospital/holiday) on a service_user_calls row
  /// and records the change in `service_user_call_log`.
  ///
  /// `service_user_call_log` is the definitive legal record for why a planned
  /// call was omitted from the rota (e.g. a hospital stay), covering
  /// duty-of-care documentation and billing justification.
  Future<void> toggleServiceUserCallFlag(
    String callId,
    String flag, // 'respite' | 'hospital' | 'holiday'
    bool value,
  ) async {
    try {
      // 1. Read the current value (and org) BEFORE updating so the audit log
      //    can record an accurate old_value.
      final current = await _client
          .from('service_user_calls')
          .select('$flag, organisation_id')
          .eq('id', callId)
          .single();

      final oldValue = current[flag] as bool?;
      final organisationId = current['organisation_id'] as String?;

      // 2. Perform the UPDATE.
      await _client
          .from('service_user_calls')
          .update({flag: value, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', callId);

      // 3. Write the audit entry (best-effort — never break the toggle).
      await _logServiceUserCallFlag(
        callId: callId,
        flag: flag,
        oldValue: oldValue,
        newValue: value,
        organisationId: organisationId,
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Best-effort audit write for a planned-call flag change.
  /// Mirrors `route_service._logChange`: logging must never break the UI,
  /// so failures are swallowed.
  Future<void> _logServiceUserCallFlag({
    required String callId,
    required String flag,
    required bool? oldValue,
    required bool newValue,
    String? organisationId,
  }) async {
    try {
      await _client.from('service_user_call_log').insert({
        'call_id': callId,
        'flag_type': flag,
        'old_value': oldValue,
        'new_value': newValue,
        'changed_by': _client.auth.currentUser?.id,
        'organisation_id': organisationId,
      });
    } catch (_) {
      // Swallow: a failed audit write must not fail the flag toggle.
    }
  }

  /// Fetches the audit history of planned-call flag changes for a call,
  /// newest first (for the Dom Care rota "History" button).
  Future<List<Map<String, dynamic>>> getServiceUserCallLog(String callId) async {
    try {
      final data = await _client
          .from('service_user_call_log')
          .select('id, flag_type, old_value, new_value, created_at')
          .eq('call_id', callId)
          .order('created_at', ascending: false);
      return (data as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // ------------------------------------------------------------
  // SERVICE-USER AWAY STATUS (respite / hospital / holiday)
  // ------------------------------------------------------------

  Future<String?> _currentOrganisationId() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return null;
      final row = await _client
          .from('profiles')
          .select('organisation_id')
          .eq('id', uid)
          .maybeSingle();
      return row?['organisation_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _openStatus(String serviceUserId) async {
    final data = await _client
        .from('service_user_statuses')
        .select('id, status_type, started_at, ended_at')
        .eq('service_user_id', serviceUserId)
        .order('started_at', ascending: false);
    for (final r in (data as List).cast<Map<String, dynamic>>()) {
      if (r['ended_at'] == null) return r;
    }
    return null;
  }

  Future<void> _syncServiceUserCallFlags(String serviceUserId) async {
    final open = await _openStatus(serviceUserId);
    final type = open?['status_type'] as String?;
    await _client.from('service_user_calls').update({
      'respite': type == 'respite',
      'hospital': type == 'hospital',
      'holiday': type == 'holiday',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('service_user_id', serviceUserId);
  }

  /// Sets the service user's single current away status (mutually exclusive).
  /// Closes any open period, opens a new one, and mirrors the flags onto
  /// service_user_calls so billable-hours logic keeps working.
  Future<void> setServiceUserStatus(String serviceUserId, String statusType,
      {String? reason}) async {
    final uid = _client.auth.currentUser?.id;
    final org = await _currentOrganisationId();
    final open = await _openStatus(serviceUserId);
    if (open != null && open['status_type'] == statusType) return;

    try {
      if (open != null) {
        await _client
            .from('service_user_statuses')
            .update({'ended_at': DateTime.now().toIso8601String(), 'ended_by': uid})
            .eq('id', open['id']);
      }
      await _client.from('service_user_statuses').insert({
        'service_user_id': serviceUserId,
        'status_type': statusType,
        'started_at': DateTime.now().toIso8601String(),
        'started_by': uid,
        'reason': reason,
        'organisation_id': org,
      });
      await _syncServiceUserCallFlags(serviceUserId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Marks the user back (closes the open status) and returns the closed
  /// period so the UI can prompt for a body-map assessment.
  Future<Map<String, dynamic>?> markServiceUserBack(String serviceUserId) async {
    final uid = _client.auth.currentUser?.id;
    final open = await _openStatus(serviceUserId);
    try {
      if (open != null) {
        await _client
            .from('service_user_statuses')
            .update({'ended_at': DateTime.now().toIso8601String(), 'ended_by': uid})
            .eq('id', open['id']);
      }
      await _syncServiceUserCallFlags(serviceUserId);
      return open;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Map of serviceUserId -> current statusType (for the Route Schedule).
  /// Best-effort: if the table doesn't exist yet (migration 144 not applied)
  /// or RLS denies, return an empty map so the screen still renders.
  Future<Map<String, String>> getActiveStatuses() async {
    try {
      final data = await _client
          .from('service_user_statuses')
          .select('service_user_id, status_type, ended_at');
      final result = <String, String>{};
      for (final r in (data as List).cast<Map<String, dynamic>>()) {
        if (r['ended_at'] == null) {
          result[r['service_user_id'] as String] = r['status_type'] as String;
        }
      }
      return result;
    } catch (_) {
      return <String, String>{};
    }
  }

  /// Records a body-map skin-check (performed when a user returns).
  Future<void> saveBodyMapAssessment({
    required String serviceUserId,
    String? statusId,
    required bool noNewMarks,
    String? notes,
  }) async {
    try {
      final org = await _currentOrganisationId();
      await _client.from('body_map_assessments').insert({
        'service_user_id': serviceUserId,
        'status_id': statusId,
        'assessed_by': _client.auth.currentUser?.id,
        'no_new_marks': noNewMarks,
        'notes': notes,
        'organisation_id': org,
      });
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // ------------------------------------------------------------
  // WEEKLY TIMETABLE + PERMANENT ROUTE MEMBERSHIP
  // ------------------------------------------------------------

  /// Returns a service user's global weekly timetable as
  /// weekday (1=Mon..7=Sun) -> list of {time, duration_minutes} entries.
  Future<Map<int, List<Map<String, dynamic>>>> getServiceUserWeeklyCalls(
      String serviceUserId) async {
    try {
      final data = await _client
          .from('service_user_weekly_calls')
          .select('weekday, call_times')
          .eq('service_user_id', serviceUserId);
      final result = <int, List<Map<String, dynamic>>>{};
      for (final r in (data as List).cast<Map<String, dynamic>>()) {
        final weekday = (r['weekday'] as num).toInt();
        final slots = <Map<String, dynamic>>[];
        final raw = r['call_times'];
        if (raw is List) {
          for (final e in raw) {
            if (e is Map) {
              slots.add({
                'time': e['time']?.toString() ?? '',
                'duration_minutes': (e['duration_minutes'] as num?)?.toInt() ?? 60,
              });
            } else if (e is String) {
              slots.add({'time': e, 'duration_minutes': 60});
            }
          }
        }
        result[weekday] = slots;
      }
      return result;
    } catch (_) {
      return <int, List<Map<String, dynamic>>>{};
    }
  }

  /// Replaces the service user's entire weekly timetable with [weekly],
  /// where each entry carries its own {time, duration_minutes}.
  Future<void> saveServiceUserWeeklyCalls(
      String serviceUserId, Map<int, List<Map<String, dynamic>>> weekly) async {
    try {
      final org = await _currentOrganisationId();
      await _client
          .from('service_user_weekly_calls')
          .delete()
          .eq('service_user_id', serviceUserId);
      for (final entry in weekly.entries) {
        if (entry.value.isEmpty) continue;
        await _client.from('service_user_weekly_calls').insert({
          'service_user_id': serviceUserId,
          'weekday': entry.key,
          'call_times': entry.value, // [{time, duration_minutes}]
          'organisation_id': org,
        });
      }
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> addServiceUserToRoute(String routeId, String serviceUserId) async {
    try {
      final org = await _currentOrganisationId();
      await _client.from('route_service_users').upsert({
        'route_id': routeId,
        'service_user_id': serviceUserId,
        'organisation_id': org,
      }, onConflict: 'route_id,service_user_id');
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> removeServiceUserFromRoute(String routeId, String serviceUserId) async {
    try {
      await _client
          .from('route_service_users')
          .delete()
          .eq('route_id', routeId)
          .eq('service_user_id', serviceUserId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get Warehouse Shifts
  Future<List<ShiftRota>> getWarehouseShifts() async {
    try {
      final data = await _client
          .from('shift_rotas')
          .select()
          .eq('shift_type', 'Warehouse')
          .order('start_date', ascending: true);
      return (data as List).map((rota) => ShiftRota.fromMap(rota as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get upcoming shifts for a carer (next 7 days)
  Future<List<ShiftRota>> getUpcomingShifts(String carerId) async {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: 7));
    
    try {
      final data = await _client
          .from('shift_rotas')
          .select()
          .eq('carer_id', carerId)
          .eq('status', 'Scheduled')
          .gte('start_date', now)
          .lte('start_date', endDate)
          .order('start_date', ascending: true);
      return (data as List).map((rota) => ShiftRota.fromMap(rota as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}
