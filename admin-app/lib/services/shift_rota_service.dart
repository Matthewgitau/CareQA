import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/shift_rota.dart';
import 'package:admin_app/models/service_user.dart';
import 'package:admin_app/models/carer.dart';

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
    final endOfWeek = startOfWeek.add(Duration(days: 6));
    
    final startDay = startOfWeek.day;
    final startMonth = startOfWeek.month;
    final startYear = startOfWeek.year;
    
    return "w/c ${startDay} ${_getMonthName(startMonth)} ${startYear}";
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

  // Get Dom Care Routes (shifts for domiciliary care routes)
  Future<List<ShiftRota>> getDomCareRoutes() async {
    try {
      final data = await _client
          .from('shift_rotas')
          .select()
          .eq('shift_type', 'Route')
          .order('start_date', ascending: true);
      return (data as List).map((rota) => ShiftRota.fromMap(rota as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get Care Home Shifts
  Future<List<ShiftRota>> getCareHomeShifts() async {
    try {
      final data = await _client
          .from('shift_rotas')
          .select()
          .neq('shift_type', 'Route')
          .neq('shift_type', 'Warehouse')
          .order('start_date', ascending: true);
      return (data as List).map((rota) => ShiftRota.fromMap(rota as Map<String, dynamic>)).toList();
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
