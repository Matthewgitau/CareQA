import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/carer.dart';

/// Service for managing carers in the admin-app:
/// creating (inviting), listing, and updating carer records.
class CarerInviteService {
  final SupabaseClient _client;

  CarerInviteService(this._client);

  /// Creates a carer + auth user + profile atomically via the
  /// `create_carer_with_auth` RPC (SECURITY DEFINER).
  Future<String> createCarer({
    required String name,
    required String email,
    required String phone,
    required String jobRole,
    required String staffType,
    required String organisationId,
    required String invitedBy,
    required String temporaryPassword,
  }) async {
    try {
      final response = await _client.rpc(
        'create_carer_with_auth',
        params: {
          'p_name': name,
          'p_email': email,
          'p_phone': phone,
          'p_job_role': jobRole,
          'p_staff_type': staffType,
          'p_organisation_id': organisationId,
          'p_invited_by': invitedBy,
          'p_temporary_password': temporaryPassword,
        },
      );
      return response as String;
    } catch (e) {
      throw Exception('Failed to create carer: $e');
    }
  }

  /// Lists all carers (admin can see all).
  Future<List<Carer>> getCarers() async {
    try {
      final response = await _client
          .from('carers')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Carer.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load carers: $e');
    }
  }

  /// Updates a carer's details (role, staff type, active status).
  Future<void> updateCarer({
    required String carerId,
    String? jobRole,
    String? staffType,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{
        if (jobRole != null) 'job_role': jobRole,
        if (staffType != null) 'staff_type': staffType,
        if (isActive != null) 'is_active': isActive,
      };
      await _client.from('carers').update(data).eq('id', carerId);
    } catch (e) {
      throw Exception('Failed to update carer: $e');
    }
  }

  /// Creates or updates the staff-app login (auth.user + profiles row) for a carer.
  /// Used by the Add/Edit Carer screens to set the carer's staff-app password.
  Future<void> upsertCarerAuth({
    required String carerId,
    required String email,
    required String fullName,
    required String password,
    required String role,
    required String organisationId,
    required String invitedBy,
  }) async {
    try {
      await _client.rpc(
        'admin_upsert_carer_auth',
        params: {
          'p_carer_id': carerId,
          'p_email': email,
          'p_full_name': fullName,
          'p_password': password,
          'p_role': role,
          'p_organisation_id': organisationId,
          'p_invited_by': invitedBy,
        },
      );
    } catch (e) {
      throw Exception('Failed to save carer login: $e');
    }
  }

  /// Marks a carer as active (e.g. after they've set their password).
  Future<void> activateCarer(String carerId) async {
    try {
      await _client
          .from('carers')
          .update({'is_active': true, 'invite_status': 'active'})
          .eq('id', carerId);
    } catch (e) {
      throw Exception('Failed to activate carer: $e');
    }
  }

  /// Soft-deletes a carer (sets is_active = false).
  Future<void> deactivateCarer(String carerId) async {
    try {
      await _client
          .from('carers')
          .update({'is_active': false, 'invite_status': 'inactive'})
          .eq('id', carerId);
    } catch (e) {
      throw Exception('Failed to deactivate carer: $e');
    }
  }
}