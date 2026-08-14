import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/leave_request.dart';
import '../models/holiday_allowance.dart';
import '../models/payroll_history.dart';

class LeaveService {
  final SupabaseClient _client;

  LeaveService(this._client);

  // ==================== LEAVE REQUESTS ====================

  Future<LeaveRequest?> createLeaveRequest(LeaveRequest request) async {
    try {
      final data = request.toJson();
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
        data['requested_by'] = user.id;
      }

      final response = await _client
          .from('leave_requests')
          .insert(data)
          .select()
          .single();

      return LeaveRequest.fromJson(response);
    } catch (e) {
      print('Error creating leave request: $e');
      rethrow;
    }
  }

  Future<List<LeaveRequest>> getLeaveRequests() async {
    try {
      final response = await _client
          .from('leave_requests')
          .select('*')
          .order('created_at', ascending: false);
      return (response as List).map((json) => LeaveRequest.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching leave requests: $e');
      return [];
    }
  }

  Future<List<LeaveRequest>> getLeaveRequestsByStaff(String staffId) async {
    try {
      final response = await _client
          .from('leave_requests')
          .select('*')
          .eq('staff_id', staffId)
          .order('created_at', ascending: false);
      return (response as List).map((json) => LeaveRequest.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching leave requests for staff: $e');
      return [];
    }
  }

  Future<List<LeaveRequest>> getLeaveRequestsByStatus(String status) async {
    try {
      final response = await _client
          .from('leave_requests')
          .select('*')
          .eq('status', status)
          .order('created_at', ascending: false);
      return (response as List).map((json) => LeaveRequest.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching leave requests by status: $e');
      return [];
    }
  }

  Future<LeaveRequest?> approveLeave(String id, String approvedBy) async {
    try {
      final response = await _client
          .from('leave_requests')
          .update({
            'status': 'approved',
            'approved_by': approvedBy,
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();
      return LeaveRequest.fromJson(response);
    } catch (e) {
      print('Error approving leave: $e');
      rethrow;
    }
  }

  Future<LeaveRequest?> rejectLeave(String id, String reason) async {
    try {
      final response = await _client
          .from('leave_requests')
          .update({
            'status': 'rejected',
            'rejected_reason': reason,
          })
          .eq('id', id)
          .select()
          .single();
      return LeaveRequest.fromJson(response);
    } catch (e) {
      print('Error rejecting leave: $e');
      rethrow;
    }
  }

  Future<LeaveRequest?> updateLeaveRequest(String id, LeaveRequest request) async {
    try {
      final data = request.toJson();
      data.remove('created_at');
      data.remove('updated_at');

      final response = await _client
          .from('leave_requests')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return LeaveRequest.fromJson(response);
    } catch (e) {
      print('Error updating leave request: $e');
      rethrow;
    }
  }

  // ==================== HOLIDAY ALLOWANCE ====================

  Future<HolidayAllowance?> getHolidayAllowance(String staffId, int year) async {
    try {
      final response = await _client
          .from('holiday_allowance')
          .select('*')
          .eq('staff_id', staffId)
          .eq('year', year)
          .single();
      return HolidayAllowance.fromJson(response);
    } catch (e) {
      print('Error fetching holiday allowance: $e');
      return null;
    }
  }

  Future<List<HolidayAllowance>> getAllHolidayAllowances(int year) async {
    try {
      final response = await _client
          .from('holiday_allowance')
          .select('*')
          .eq('year', year)
          .order('staff_id');
      return (response as List).map((json) => HolidayAllowance.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching holiday allowances: $e');
      return [];
    }
  }

  Future<HolidayAllowance?> updateHolidayAllowance(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('holiday_allowance')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return HolidayAllowance.fromJson(response);
    } catch (e) {
      print('Error updating holiday allowance: $e');
      rethrow;
    }
  }

  // ==================== PAYROLL ====================

  Future<List<PayrollHistory>> getPayrollHistory() async {
    try {
      final response = await _client
          .from('payroll_history')
          .select('*')
          .order('period_start', ascending: false);
      return (response as List).map((json) => PayrollHistory.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching payroll history: $e');
      return [];
    }
  }

  Future<List<PayrollHistory>> getPayrollByPeriod(DateTime start, DateTime end) async {
    try {
      final response = await _client
          .from('payroll_history')
          .select('*')
          .gte('period_start', start.toIso8601String().split('T').first)
          .lte('period_end', end.toIso8601String().split('T').first)
          .order('staff_id');
      return (response as List).map((json) => PayrollHistory.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching payroll by period: $e');
      return [];
    }
  }

  Future<PayrollHistory?> createPayrollEntry(PayrollHistory entry) async {
    try {
      final data = entry.toJson();
      data.remove('id');
      data.remove('created_at');
      data.remove('updated_at');

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
          .from('payroll_history')
          .insert(data)
          .select()
          .single();

      return PayrollHistory.fromJson(response);
    } catch (e) {
      print('Error creating payroll entry: $e');
      rethrow;
    }
  }

  // ==================== HELPERS ====================

  Future<List<Map<String, dynamic>>> getAllStaff() async {
    try {
      final data = await _client
          .from('profiles')
          .select('id, full_name, email, role')
          .order('full_name', ascending: true);
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching staff: $e');
      return [];
    }
  }

  Future<double> calculateHolidayPay(String staffId, int days, String rateType) async {
    try {
      final profile = await _client
          .from('profiles')
          .select('organisation_id')
          .eq('id', staffId)
          .single();

      final settings = await _client
          .from('leave_policy_settings')
          .select('*')
          .eq('organisation_id', (profile as Map<String, dynamic>)['organisation_id'])
          .single() as Map<String, dynamic>?;

      double dailyRate = 100.0; // Default £100/day
      final policy = settings;

      switch (rateType) {
        case 'statutory':
          dailyRate = 95.85; // UK statutory rate
          break;
        case 'enhanced':
          dailyRate = (policy?['enhanced_holiday_days'] ?? 150).toDouble();
          break;
        case 'full_pay':
          dailyRate = 200.0; // Default full pay rate
          break;
        default:
          dailyRate = 0;
      }

      return days * dailyRate;
    } catch (e) {
      print('Error calculating holiday pay: $e');
      return 0;
    }
  }
}