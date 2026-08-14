import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/shift_rota.dart';
import 'package:admin_app/models/service_user.dart';
import 'package:admin_app/models/carer.dart';

class ShiftRotaService {
  final SupabaseClient _client;

  ShiftRotaService(this._client);

  // Get all shift rotas
  Stream<List<ShiftRota>> getShiftRotas() {
    return _client
        .from('shift_rotas')
        .select()
        .order('start_date', ascending: true)
        .execute()
        .asStream()
        .map((response) {
      if (response.error != null) {
        print('Error fetching shift rotas: ${response.error}');
        return [];
      }
      return (response.data as List)
          .map((rota) => ShiftRota.fromMap(rota as Map<String, dynamic>, rota['id']))
          .toList();
    });
  }

  // Get shift rotas for a specific week
  Stream<List<ShiftRota>> getShiftRotasForWeek(String weekRange) {
    return _client
        .from('shift_rotas')
        .select()
        .eq('week_range', weekRange)
        .order('start_date', ascending: true)
        .execute()
        .asStream()
        .map((response) {
      if (response.error != null) {
        print('Error fetching shift rotas for week: ${response.error}');
        return [];
      }
      return (response.data as List)
          .map((rota) => ShiftRota.fromMap(rota as Map<String, dynamic>, rota['id']))
          .toList();
    });
  }

  // Get shift rotas for a specific carer
  Stream<List<ShiftRota>> getShiftRotasForCarer(String carerId) {
    return _client
        .from('shift_rotas')
        .select()
        .eq('carer_id', carerId)
        .order('start_date', ascending: true)
        .execute()
        .asStream()
        .map((response) {
      if (response.error != null) {
        print('Error fetching shift rotas for carer: ${response.error}');
        return [];
      }
      return (response.data as List)
          .map((rota) => ShiftRota.fromMap(rota as Map<String, dynamic>, rota['id']))
          .toList();
    });
  }

  // Get shift rotas for a specific service user
  Stream<List<ShiftRota>> getShiftRotasForServiceUser(String serviceUserId) {
    return _client
        .from('shift_rotas')
        .select()
        .eq('service_user_id', serviceUserId)
        .order('start_date', ascending: true)
        .execute()
        .asStream()
        .map((response) {
      if (response.error != null) {
        print('Error fetching shift rotas for service user: ${response.error}');
        return [];
      }
      return (response.data as List)
          .map((rota) => ShiftRota.fromMap(rota as Map<String, dynamic>, rota['id']))
          .toList();
    });
  }

  // Create a new shift rota
  Future<String> createShiftRota(ShiftRota shiftRota) async {
    try {
      final response = await _client.from('shift_rotas').insert(shiftRota.toMap()).select().single();
      return response['id'];
    } catch (e) {
      print('Error creating shift rota: $e');
      throw Exception('Failed to create shift rota: $e');
    }
  }

  // Update an existing shift rota
  Future<void> updateShiftRota(String shiftRotaId, ShiftRota shiftRota) async {
    try {
      await _client.from('shift_rotas').update(shiftRota.toMap()).eq('id', shiftRotaId);
    } catch (e) {
      print('Error updating shift rota: $e');
      throw Exception('Failed to update shift rota: $e');
    }
  }

  // Delete a shift rota
  Future<void> deleteShiftRota(String shiftRotaId) async {
    try {
      await _client.from('shift_rotas').delete().eq('id', shiftRotaId);
    } catch (e) {
      print('Error deleting shift rota: $e');
      throw Exception('Failed to delete shift rota: $e');
    }
  }

  // Get all service users
  Stream<List<ServiceUser>> getServiceUsers() {
    return _client
        .from('service_users')
        .select()
        .order('created_at', ascending: false)
        .execute()
        .asStream()
        .map((response) {
      if (response.error != null) {
        print('Error fetching service users: ${response.error}');
        return [];
      }
      return (response.data as List)
          .map((user) => ServiceUser.fromMap(user as Map<String, dynamic>))
          .toList();
    });
  }

  // Get all carers
  Stream<List<Carer>> getCarers() {
    return _client
        .from('carers')
        .select()
        .order('created_at', ascending: false)
        .execute()
        .asStream()
        .map((response) {
      if (response.error != null) {
        print('Error fetching carers: ${response.error}');
        return [];
      }
      return (response.data as List)
          .map((carer) => Carer.fromMap(carer as Map<String, dynamic>))
          .toList();
    });
  }

  // Get carers with specific qualifications
  Stream<List<Carer>> getCarersByQualifications(List<String> requiredQualifications) {
    return _client
        .from('carers')
        .select()
        .execute()
        .asStream()
        .map((response) {
      if (response.error != null) {
        print('Error fetching carers by qualifications: ${response.error}');
        return [];
      }
      return (response.data as List)
          .map((carer) => Carer.fromMap(carer as Map<String, dynamic>))
          .where((carer) {
            // Check if carer has all required qualifications
            return requiredQualifications.every((req) => carer.qualifications.contains(req));
          })
          .toList();
    });
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

      final response = await query.execute();
      
      if (response.error != null) {
        print('Error checking for conflicts: ${response.error}');
        return false;
      }

      return (response.data as List).isNotEmpty;
    } catch (e) {
      print('Error checking for conflicts: $e');
      throw Exception('Failed to check for conflicts: $e');
    }
  }

  // Get available carers for a specific time slot
  Future<List<Carer>> getAvailableCarers(DateTime startDate, DateTime endDate, List<String> requiredQualifications) async {
    try {
      // Get all carers with required qualifications
      final carersResponse = await _client.from('carers').select().execute();
      
      if (carersResponse.error != null) {
        print('Error fetching carers: ${carersResponse.error}');
        return [];
      }

      final qualifiedCarers = (carersResponse.data as List)
          .map((carer) => Carer.fromMap(carer as Map<String, dynamic>))
          .where((carer) {
            return requiredQualifications.every((req) => carer.qualifications.contains(req));
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
    } catch (e) {
      print('Error getting available carers: $e');
      throw Exception('Failed to get available carers: $e');
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
    } catch (e) {
      print('Error creating recurring shifts: $e');
      throw Exception('Failed to create recurring shifts: $e');
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
          .order('start_date')
          .execute();

      if (response.error != null) {
        print('Error fetching shifts for route optimization: ${response.error}');
        return [];
      }

      return (response.data as List)
          .map((rota) => ShiftRota.fromMap(rota as Map<String, dynamic>, rota['id']))
          .toList();
    } catch (e) {
      print('Error getting shifts for route optimization: $e');
      throw Exception('Failed to get shifts for route optimization: $e');
    }
  }

  // Update shift status
  Future<void> updateShiftStatus(String shiftId, String status) async {
    try {
      await _client.from('shift_rotas').update({
        'status': status,
        'updated_at': DateTime.now(),
      }).eq('id', shiftId);
    } catch (e) {
      print('Error updating shift status: $e');
      throw Exception('Failed to update shift status: $e');
    }
  }

  // Get shifts by status for a carer
  Stream<List<ShiftRota>> getShiftsByStatus(String carerId, String status) {
    return _client
        .from('shift_rotas')
        .select()
        .eq('carer_id', carerId)
        .eq('status', status)
        .order('start_date', ascending: true)
        .execute()
        .asStream()
        .map((response) {
      if (response.error != null) {
        print('Error fetching shifts by status: ${response.error}');
        return [];
      }
      return (response.data as List)
          .map((rota) => ShiftRota.fromMap(rota as Map<String, dynamic>, rota['id']))
          .toList();
    });
  }

  // Get upcoming shifts for a carer (next 7 days)
  Stream<List<ShiftRota>> getUpcomingShifts(String carerId) {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: 7));
    
    return _client
        .from('shift_rotas')
        .select()
        .eq('carer_id', carerId)
        .eq('status', 'Scheduled')
        .gte('start_date', now)
        .lte('start_date', endDate)
        .order('start_date', ascending: true)
        .execute()
        .asStream()
        .map((response) {
      if (response.error != null) {
        print('Error fetching upcoming shifts: ${response.error}');
        return [];
      }
      return (response.data as List)
          .map((rota) => ShiftRota.fromMap(rota as Map<String, dynamic>, rota['id']))
          .toList();
    });
  }
}