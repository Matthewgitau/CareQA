import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/employee_incentive.dart';
import '../models/points_account.dart';
import '../models/reward_catalogue.dart';
import '../models/incentive_program.dart';

class IncentiveService {
  final SupabaseClient _client;

  IncentiveService(this._client);

  // ==================== INCENTIVE AWARDS ====================

  Future<EmployeeIncentive?> createIncentiveAward(EmployeeIncentive incentive) async {
    try {
      final data = incentive.toJson();
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
          .from('employee_incentives')
          .insert(data)
          .select()
          .single();

      return EmployeeIncentive.fromJson(response);
    } catch (e) {
      print('Error creating incentive award: $e');
      rethrow;
    }
  }

  Future<List<EmployeeIncentive>> getIncentives() async {
    try {
      final response = await _client
          .from('employee_incentives')
          .select('*')
          .order('award_date', ascending: false);
      return (response as List).map((json) => EmployeeIncentive.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching incentives: $e');
      return [];
    }
  }

  Future<List<EmployeeIncentive>> getIncentivesForStaff(String staffId) async {
    try {
      final response = await _client
          .from('employee_incentives')
          .select('*')
          .eq('staff_id', staffId)
          .order('award_date', ascending: false);
      return (response as List).map((json) => EmployeeIncentive.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching incentives for staff: $e');
      return [];
    }
  }

  // ==================== POINTS MANAGEMENT ====================

  Future<PointsAccount?> getPointsBalance(String staffId) async {
    try {
      final response = await _client
          .from('employee_points_accounts')
          .select('*')
          .eq('staff_id', staffId)
          .single();
      return PointsAccount.fromJson(response);
    } catch (e) {
      print('Error fetching points balance: $e');
      return null;
    }
  }

  Future<List<PointsAccount>> getAllPointsBalances() async {
    try {
      final response = await _client
          .from('employee_points_accounts')
          .select('*')
          .order('current_points_balance', ascending: false);
      return (response as List).map((json) => PointsAccount.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching all points balances: $e');
      return [];
    }
  }

  Future<void> addPoints(String staffId, int points, String reason) async {
    try {
      await _client.rpc('add_points_to_employee', params: {
        'p_staff_id': staffId,
        'p_points': points,
        'p_reason': reason,
      });
    } catch (e) {
      print('Error adding points: $e');
      rethrow;
    }
  }

  // ==================== REWARD CATALOGUE ====================

  Future<List<RewardCatalogue>> getRewardCatalogue() async {
    try {
      final response = await _client
          .from('reward_catalogue')
          .select('*')
          .eq('is_available', true)
          .order('points_required', ascending: true);
      return (response as List).map((json) => RewardCatalogue.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching reward catalogue: $e');
      return [];
    }
  }

  Future<RewardCatalogue?> createReward(RewardCatalogue reward) async {
    try {
      final data = reward.toJson();
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
        data['created_by'] = user.id;
      }

      final response = await _client
          .from('reward_catalogue')
          .insert(data)
          .select()
          .single();

      return RewardCatalogue.fromJson(response);
    } catch (e) {
      print('Error creating reward: $e');
      rethrow;
    }
  }

  // ==================== POINTS REDEMPTION ====================

  Future<Map<String, dynamic>> redeemPoints(String staffId, String rewardId, int pointsSpent) async {
    try {
      final reward = await _client
          .from('reward_catalogue')
          .select('*')
          .eq('id', rewardId)
          .single();

      final redemptionData = {
        'staff_id': staffId,
        'staff_name': reward['reward_name'],
        'reward_id': rewardId,
        'reward_name': reward['reward_name'],
        'points_spent': pointsSpent,
        'redemption_date': DateTime.now().toIso8601String().split('T').first,
        'status': 'pending',
      };

      final user = _client.auth.currentUser;
      if (user != null) {
        final profile = await _client
            .from('profiles')
            .select('organisation_id')
            .eq('id', user.id)
            .single();
        redemptionData['organisation_id'] = profile['organisation_id'];
      }

      final response = await _client
          .from('points_redemptions')
          .insert(redemptionData)
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error redeeming points: $e');
      rethrow;
    }
  }

  // ==================== INCENTIVE PROGRAMS ====================

  Future<List<IncentiveProgram>> getIncentivePrograms() async {
    try {
      final response = await _client
          .from('incentive_programs')
          .select('*')
          .order('start_date', ascending: false);
      return (response as List).map((json) => IncentiveProgram.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching incentive programs: $e');
      return [];
    }
  }

  Future<IncentiveProgram?> createIncentiveProgram(IncentiveProgram program) async {
    try {
      final data = program.toJson();
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
        data['created_by'] = user.id;
      }

      final response = await _client
          .from('incentive_programs')
          .insert(data)
          .select()
          .single();

      return IncentiveProgram.fromJson(response);
    } catch (e) {
      print('Error creating incentive program: $e');
      rethrow;
    }
  }

  // ==================== PERFORMANCE METRICS ====================

  Future<List<Map<String, dynamic>>> getPerformanceMetrics(String staffId) async {
    try {
      final response = await _client
          .from('performance_metrics')
          .select('*')
          .eq('staff_id', staffId)
          .order('metric_period_start', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching performance metrics: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> calculatePointsForPerformance(String staffId) async {
    try {
      final metrics = await getPerformanceMetrics(staffId);
      
      int totalPoints = 0;
      for (final metric in metrics) {
        final achievement = metric['achievement_percentage'] ?? 0;
        if (achievement >= 100) {
          totalPoints += 100;
        } else if (achievement >= 80) {
          totalPoints += 50;
        } else if (achievement >= 60) {
          totalPoints += 25;
        }
      }

      return {
        'total_points': totalPoints,
        'metrics_count': metrics.length,
      };
    } catch (e) {
      print('Error calculating points: $e');
      return {'total_points': 0, 'metrics_count': 0};
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