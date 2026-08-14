import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Shift {
  final String? id;
  final String? clientOrganisationId;
  final String? serviceUserId;
  final String? carerId;
  final DateTime scheduledDate;
  final String startTime;
  final String endTime;
  final String? status;
  final String? location;
  final int? staffRequired;
  final String? staffType;
  final String? notes;
  final String? serviceUserName;
  final String? carerName;

  Shift({
    this.id,
    this.clientOrganisationId,
    this.serviceUserId,
    this.carerId,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
    this.status,
    this.location,
    this.staffRequired,
    this.staffType,
    this.notes,
    this.serviceUserName,
    this.carerName,
  });

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
        id: json['id'] as String? ?? '',
        clientOrganisationId: json['client_organisation_id'] as String?,
        serviceUserId: json['service_user_id'] as String?,
        carerId: json['carer_id'] as String?,
        scheduledDate: DateTime.tryParse(json['scheduled_date'] ?? '') ?? DateTime.now(),
        startTime: json['start_time'] as String? ?? '08:00',
        endTime: json['end_time'] as String? ?? '16:00',
        status: json['status'] as String?,
        location: json['location'] as String?,
        staffRequired: json['staff_required'] as int?,
        staffType: json['staff_type'] as String?,
        notes: json['notes'] as String?,
        serviceUserName: _extractName(json['service_users']),
        carerName: _extractName(json['carers']),
      );

  static String? _extractName(dynamic joined) {
    if (joined is Map<String, dynamic>) {
      return joined['name'] as String?;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (clientOrganisationId != null) 'client_organisation_id': clientOrganisationId,
        if (serviceUserId != null) 'service_user_id': serviceUserId,
        if (carerId != null) 'carer_id': carerId,
        'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
        'start_time': startTime,
        'end_time': endTime,
        'status': status,
        if (location != null) 'location': location,
        if (staffRequired != null) 'staff_required': staffRequired,
        if (staffType != null) 'staff_type': staffType,
        if (notes != null) 'notes': notes,
      };
}

class RouteSchedule {
  final String id;
  final String clientOrganisationId;
  final String serviceUserId;
  final String? carerId;
  final DateTime proposedStartTime;
  final DateTime proposedEndTime;
  final bool respite;
  final int callNumber;
  final String status;
  final String? notes;
  final String? serviceUserName;
  final String? carerName;

  const RouteSchedule({
    required this.id,
    required this.clientOrganisationId,
    required this.serviceUserId,
    this.carerId,
    required this.proposedStartTime,
    required this.proposedEndTime,
    this.respite = false,
    required this.callNumber,
    this.status = 'scheduled',
    this.notes,
    this.serviceUserName,
    this.carerName,
  });

  factory RouteSchedule.fromJson(Map<String, dynamic> json) => RouteSchedule(
        id: json['id'] as String,
        clientOrganisationId: json['client_organisation_id'] as String,
        serviceUserId: json['service_user_id'] as String,
        carerId: json['carer_id'] as String?,
        proposedStartTime:
            DateTime.tryParse(json['proposed_start_time'] ?? '') ?? DateTime.now(),
        proposedEndTime:
            DateTime.tryParse(json['proposed_end_time'] ?? '') ?? DateTime.now(),
        respite: json['respite'] as bool? ?? false,
        callNumber: json['call_number'] as int? ?? 0,
        status: json['status'] as String? ?? 'scheduled',
        notes: json['notes'] as String?,
        serviceUserName: Shift._extractName(json['service_users']),
        carerName: Shift._extractName(json['carers']),
      );
}

class ShiftService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Shift>> getShiftsForDate(DateTime date) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final profile = await _client
        .from('profiles')
        .select('role, organisation_id, client_organisation_id')
        .eq('id', user.id)
        .single();

    final role = profile['role'] as String? ?? '';
    final organisationId = profile['organisation_id'] as String?;
    final clientOrgId = profile['client_organisation_id'] as String?;

    final dateStr = date.toIso8601String().split('T')[0];
    
    // Build query based on role
    dynamic query = _client
        .from('shifts')
        .select('*, service_users(name), carers(name)');
    
    // Always filter by date
    query = query.eq('scheduled_date', dateStr);
    
    // Admins see all shifts, client users see only their shifts
    if (role != 'admin' && role != 'super_admin' && clientOrgId != null) {
      query = query.eq('client_organisation_id', clientOrgId);
    }
    
    // Apply ordering last
    query = query.order('start_time', ascending: true);

    final response = await query;

    return (response as List)
        .map((json) => Shift.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<RouteSchedule>> getRoutesForDate(DateTime date) async {
    final clientOrgId = await _getClientOrgId();
    if (clientOrgId == null) throw Exception('No client organisation');

    final dayStart =
        DateTime(date.year, date.month, date.day).toUtc().toIso8601String();
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59)
        .toUtc()
        .toIso8601String();

    final response = await _client
        .from('routes')
        .select('*, service_users(name), carers(name)')
        .eq('client_organisation_id', clientOrgId)
        .gte('proposed_start_time', dayStart)
        .lte('proposed_start_time', dayEnd)
        .order('proposed_start_time', ascending: true);

    return (response as List)
        .map((json) => RouteSchedule.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Shift>> getShiftsForMonth(DateTime month) async {
    final clientOrgId = await _getClientOrgId();
    if (clientOrgId == null) throw Exception('No client organisation');

    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);

    final response = await _client
        .from('shifts')
        .select()
        .eq('client_organisation_id', clientOrgId)
        .gte('scheduled_date', startDate.toIso8601String().split('T')[0])
        .lte('scheduled_date', endDate.toIso8601String().split('T')[0])
        .order('scheduled_date', ascending: true)
        .order('start_time', ascending: true);

    return (response as List)
        .map((json) => Shift.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateShift(Shift shift) async {
    if (shift.id == null) throw Exception('Shift ID is required');
    await _client
        .from('shifts')
        .update(shift.toJson())
        .eq('id', shift.id!);
  }

  Future<void> assignCarerToShift(String shiftId, String carerId) async {
    if (shiftId.isEmpty) throw Exception('Shift ID is required');
    if (carerId.isEmpty) throw Exception('Carer ID is required');
    
    debugPrint('=== ASSIGNING CARER ===');
    debugPrint('Shift ID: $shiftId');
    debugPrint('Carer ID: $carerId');
    debugPrint('Current user: ${Supabase.instance.client.auth.currentUser?.id}');
    
    try {
      // First, verify the shift exists
      final existingShift = await _client
          .from('shifts')
          .select('id, carer_id, status')
          .eq('id', shiftId)
          .single();
      
      debugPrint('Existing shift: $existingShift');
      
      // Now update it
      final response = await _client
          .from('shifts')
          .update({'carer_id': carerId, 'status': 'confirmed'})
          .eq('id', shiftId)
          .select();

      debugPrint('Update response: $response');
      
      if (response.isEmpty) {
        throw Exception('No rows updated - shift may not exist or you do not have permission');
      }
      
      debugPrint('=== ASSIGNMENT SUCCESSFUL ===');
    } catch (e) {
      debugPrint('=== ASSIGNMENT FAILED ===');
      debugPrint('Error: $e');
      rethrow;
    }
  }

  Future<void> unassignCarerFromShift(String shiftId, String carerId) async {
    if (shiftId.isEmpty) throw Exception('Shift ID is required');
    await _client
        .from('shifts')
        .update({'carer_id': null, 'status': 'scheduled'})
        .eq('id', shiftId);
  }

  Future<void> sendShiftReminder(String shiftId) async {
    // Placeholder - wire up real push notifications later
    debugPrint('Reminder sent for shift $shiftId');
  }

  /// Get all available carers from public.carers
  Future<List<Map<String, dynamic>>> getCarers() async {
    try {
      final response = await _client
          .from('carers')
          .select('id, name, employee_number, job_role, photo_url')
          .eq('is_active', true)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => json as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to load carers: $e');
    }
  }

  Future<String?> _getClientOrgId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    try {
      // First try user metadata (fast path)
      final metaClientOrgId =
          user.userMetadata?['client_organisation_id'] as String?;
      if (metaClientOrgId != null && metaClientOrgId.isNotEmpty) {
        return metaClientOrgId;
      }

      // Fall back to the profiles table
      final profile = await _client
          .from('profiles')
          .select('client_organisation_id, organisation_id')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) return null;

      final clientOrgId = profile['client_organisation_id'] as String?;
      if (clientOrgId != null && clientOrgId.isNotEmpty) {
        return clientOrgId;
      }

      // Fall back to organisation_id for admin users
      return profile['organisation_id'] as String?;
    } catch (e) {
      debugPrint('Failed to resolve client organisation: $e');
      return null;
    }
  }
}