import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/welfare_check.dart';

class WelfareService {
  final SupabaseClient _client;

  WelfareService(this._client);

  // ==================== WELFARE CHECKS ====================

  Future<WelfareCheck?> createWelfareCheck(WelfareCheck check) async {
    try {
      final data = check.toJson();
      data.remove('id');
      data.remove('created_at');
      data.remove('updated_at');

      // Get organisation_id for RLS
      final user = _client.auth.currentUser;
      if (user != null) {
        final profile = await _client
            .from('profiles')
            .select('organisation_id')
            .eq('id', user.id)
            .single();
        data['organisation_id'] = profile['organisation_id'];
        data['created_by'] = user.id;
      }

      final response = await _client
          .from('welfare_checks')
          .insert(data)
          .select()
          .single();

      return WelfareCheck.fromJson(response);
    } catch (e) {
      print('Error creating welfare check: $e');
      rethrow;
    }
  }

  Future<List<WelfareCheck>> getWelfareChecks() async {
    try {
      final response = await _client
          .from('welfare_checks')
          .select('*')
          .order('check_date', ascending: false);
      return (response as List).map((json) => WelfareCheck.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching welfare checks: $e');
      return [];
    }
  }

  Future<List<WelfareCheck>> getWelfareChecksForStaff(String staffId) async {
    try {
      final response = await _client
          .from('welfare_checks')
          .select('*')
          .eq('staff_id', staffId)
          .order('check_date', ascending: false);
      return (response as List).map((json) => WelfareCheck.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching welfare checks for staff: $e');
      return [];
    }
  }

  Future<WelfareCheck?> updateWelfareCheck(String id, WelfareCheck check) async {
    try {
      final data = check.toJson();
      data.remove('created_at');
      data.remove('updated_at');

      final response = await _client
          .from('welfare_checks')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return WelfareCheck.fromJson(response);
    } catch (e) {
      print('Error updating welfare check: $e');
      rethrow;
    }
  }

  // ==================== REFERRALS ====================

  Future<Map<String, dynamic>> createReferral(Map<String, dynamic> referralData) async {
    try {
      final data = {...referralData};
      
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
          .from('welfare_referrals')
          .insert(data)
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error creating referral: $e');
      rethrow;
    }
  }

  // ==================== STRESS RISK ASSESSMENTS ====================

  Future<Map<String, dynamic>> createStressRiskAssessment(Map<String, dynamic> assessmentData) async {
    try {
      final data = {...assessmentData};
      
      final user = _client.auth.currentUser;
      if (user != null) {
        final profile = await _client
            .from('profiles')
            .select('organisation_id')
            .eq('id', user.id)
            .single();
        data['organisation_id'] = profile['organisation_id'];
        data['created_by'] = user.id;
      }

      final response = await _client
          .from('stress_risk_assessments')
          .insert(data)
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error creating stress risk assessment: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getStressRiskAssessments() async {
    try {
      final response = await _client
          .from('stress_risk_assessments')
          .select('*')
          .order('assessment_date', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching stress risk assessments: $e');
      return [];
    }
  }

  // ==================== HELPERS ====================

  Future<List<Map<String, dynamic>>> getAllStaff() async {
    try {
      final allEmployees = <Map<String, dynamic>>[];

      // Get non-carer staff from profiles
      final staffResponse = await _client
          .from('profiles')
          .select('id, full_name, email, role')
          .neq('role', 'carer')
          .order('full_name', ascending: true);
      
      for (final staff in staffResponse) {
        allEmployees.add({
          'id': staff['id'],
          'name': staff['full_name'],
          'type': 'staff',
        });
      }

      // Get carers from carers table
      final carersResponse = await _client
          .from('carers')
          .select('id, name, employee_number')
          .eq('is_active', true)
          .order('name', ascending: true);
      
      for (final carer in carersResponse) {
        allEmployees.add({
          'id': carer['id'],
          'name': carer['name'],
          'type': 'carer',
        });
      }

      return allEmployees;
    } catch (e) {
      print('Error fetching staff: $e');
      return [];
    }
  }
}