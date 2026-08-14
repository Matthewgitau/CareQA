import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/disciplinary_case.dart';

/// Service for managing disciplinary cases
class DisciplinaryService {
  final SupabaseClient _client;

  DisciplinaryService(this._client);

  // Expose client for file uploads
  SupabaseClient get client => _client;

  // ==================== CRUD OPERATIONS ====================

  Future<List<DisciplinaryCase>> getAllCases() async {
    try {
      final response = await _client
          .from('disciplinary_cases')
          .select('*')
          .order('incident_date', ascending: false);
      return (response as List).map((json) => DisciplinaryCase.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching disciplinary cases: $e');
      return [];
    }
  }

  Future<DisciplinaryCase?> getCaseById(String id) async {
    try {
      final response = await _client
          .from('disciplinary_cases')
          .select('*')
          .eq('id', id)
          .single();
      return DisciplinaryCase.fromJson(response);
    } catch (e) {
      print('Error fetching case: $e');
      return null;
    }
  }

  Future<DisciplinaryCase?> createCase(DisciplinaryCase case_) async {
    try {
      final data = case_.toJson();
      data.remove('id');
      data.remove('created_at');
      data.remove('updated_at');
      data.remove('case_reference'); // Let trigger generate this

      // Get current user's organisation_id for RLS policy
      final user = _client.auth.currentUser;
      if (user != null) {
        final profile = await _client
            .from('profiles')
            .select('organisation_id')
            .eq('id', user.id)
            .single();
        data['organisation_id'] = profile['organisation_id'];
      }

      final response = await _client
          .from('disciplinary_cases')
          .insert(data)
          .select()
          .single();

      return DisciplinaryCase.fromJson(response);
    } catch (e) {
      print('Error creating case: $e');
      rethrow;
    }
  }

  Future<DisciplinaryCase?> updateCase(DisciplinaryCase case_) async {
    try {
      final data = case_.toJson();
      data.remove('created_at');
      data.remove('updated_at');
      data.remove('case_reference'); // Don't update case reference

      // Ensure organisation_id is set for RLS
      final user = _client.auth.currentUser;
      if (user != null && !data.containsKey('organisation_id')) {
        final profile = await _client
            .from('profiles')
            .select('organisation_id')
            .eq('id', user.id)
            .single();
        data['organisation_id'] = profile['organisation_id'];
      }

      final response = await _client
          .from('disciplinary_cases')
          .update(data)
          .eq('id', case_.id)
          .select()
          .single();

      return DisciplinaryCase.fromJson(response);
    } catch (e) {
      print('Error updating case: $e');
      rethrow;
    }
  }

  Future<void> deleteCase(String id) async {
    try {
      await _client.from('disciplinary_cases').delete().eq('id', id);
    } catch (e) {
      print('Error deleting case: $e');
      rethrow;
    }
  }

  // ==================== FILTERING ====================

  Future<List<DisciplinaryCase>> getCasesByStatus(String status) async {
    try {
      final response = await _client
          .from('disciplinary_cases')
          .select('*')
          .eq('status', status)
          .order('incident_date', ascending: false);
      return (response as List).map((json) => DisciplinaryCase.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching cases by status: $e');
      return [];
    }
  }

  Future<List<DisciplinaryCase>> getCasesByStaff(String staffId) async {
    try {
      final response = await _client
          .from('disciplinary_cases')
          .select('*')
          .eq('staff_id', staffId)
          .order('incident_date', ascending: false);
      return (response as List).map((json) => DisciplinaryCase.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching cases by staff: $e');
      return [];
    }
  }

  Future<List<DisciplinaryCase>> searchCases(String query) async {
    try {
      final response = await _client
          .from('disciplinary_cases')
          .select('*')
          .or('staff_name.ilike.%$query%,case_reference.ilike.%$query%')
          .order('incident_date', ascending: false);
      return (response as List).map((json) => DisciplinaryCase.fromJson(json)).toList();
    } catch (e) {
      print('Error searching cases: $e');
      return [];
    }
  }

  // ==================== HELPERS ====================

  Future<List<Map<String, dynamic>>> getAllStaff() async {
    try {
      final data = await _client
          .from('profiles')
          .select('id, full_name, email, role')
          .neq('role', 'carer')
          .order('full_name', ascending: true);
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching staff: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllCarers() async {
    try {
      // Direct query on public.carers - has 'name' and 'employee_number' columns
      final data = await _client
          .from('carers')
          .select('id, name, employee_number')
          .eq('is_active', true)
          .order('name', ascending: true);
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching carers: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllServiceUsers() async {
    try {
      final data = await _client
          .from('service_users')
          .select('id, name, address, is_active')
          .eq('is_active', true)
          .order('name', ascending: true);
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching service users: $e');
      return [];
    }
  }
}