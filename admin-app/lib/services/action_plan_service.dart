import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/action_plan.dart';

class ActionPlanService {
  final SupabaseClient _client;

  ActionPlanService(this._client);

  Future<List<ActionPlan>> getActionPlans({
    String? status,
    String? priority,
    String? assignedTo,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client.from('action_plans').select();

      if (status != null) {
        query = query.eq('status', status);
      }
      if (priority != null) {
        query = query.eq('priority', priority);
      }
      if (assignedTo != null) {
        query = query.eq('assigned_to', assignedTo);
      }
      if (category != null) {
        query = query.eq('category', category);
      }
      if (startDate != null) {
        query = query.gte('target_completion_date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte('target_completion_date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('target_completion_date', ascending: true);
      return (response as List).map((json) => ActionPlan.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch action plans: $e');
    }
  }

  Future<ActionPlan?> getActionPlan(String id) async {
    try {
      final response = await _client.from('action_plans').select().eq('id', id).maybeSingle();
      if (response == null) return null;
      return ActionPlan.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch action plan: $e');
    }
  }

  Future<ActionPlan> createActionPlan(ActionPlan plan) async {
    try {
      final orgId = await _getOrganisationId();
      if (orgId == null) throw Exception('No organisation found');

      final data = plan.toJson();
      data['organisation_id'] = orgId;
      data['created_by'] = _client.auth.currentUser?.id;
      data['created_at'] = DateTime.now().toIso8601String();

      final response = await _client.from('action_plans').insert(data).select().single();
      return ActionPlan.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create action plan: $e');
    }
  }

  Future<ActionPlan> updateActionPlan(String id, Map<String, dynamic> data) async {
    try {
      data['updated_by'] = _client.auth.currentUser?.id;
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client.from('action_plans').update(data).eq('id', id).select().single();
      return ActionPlan.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update action plan: $e');
    }
  }

  Future<void> deleteActionPlan(String id) async {
    try {
      await _client.from('action_plans').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete action plan: $e');
    }
  }

  Future<List<ActionPlan>> getActionPlansByAssignee(String staffId) async {
    try {
      final response = await _client.from('action_plans')
          .select()
          .eq('assigned_to', staffId)
          .order('target_completion_date', ascending: true);
      return (response as List).map((json) => ActionPlan.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch action plans by assignee: $e');
    }
  }

  Future<List<ActionPlan>> getOverdueActionPlans() async {
    try {
      final response = await _client.from('action_plans')
          .select()
          .eq('status', 'overdue')
          .order('target_completion_date', ascending: true);
      return (response as List).map((json) => ActionPlan.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch overdue action plans: $e');
    }
  }

  Future<List<ActionPlan>> getActionPlansBySource(String sourceType, String sourceId) async {
    try {
      final response = await _client.from('action_plans')
          .select()
          .eq('source_type', sourceType)
          .eq('source_id', sourceId)
          .order('created_at', ascending: false);
      return (response as List).map((json) => ActionPlan.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch action plans by source: $e');
    }
  }

  Future<void> updateProgress(String id, int percentage) async {
    try {
      final data = <String, dynamic>{
        'progress_percentage': percentage,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (percentage == 100) {
        data['status'] = 'completed';
        data['actual_completion_date'] = DateTime.now().toIso8601String().split('T')[0];
      } else if (percentage > 0 && percentage < 100) {
        data['status'] = 'in_progress';
      }

      await _client.from('action_plans').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }

  Future<void> addUpdateLog(String id, String note) async {
    try {
      final plan = await getActionPlan(id);
      if (plan == null) throw Exception('Action plan not found');

      final updateLog = List<Map<String, dynamic>>.from(plan.updateLog);
      updateLog.add({
        'date': DateTime.now().toIso8601String(),
        'user': _client.auth.currentUser?.id ?? 'unknown',
        'note': note,
      });

      await _client.from('action_plans').update({
        'update_log': updateLog,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw Exception('Failed to add update log: $e');
    }
  }

  Future<void> verifyActionPlan(String id, String verifiedBy, String notes) async {
    try {
      await _client.from('action_plans').update({
        'status': 'verified',
        'verified_by': verifiedBy,
        'verified_date': DateTime.now().toIso8601String().split('T')[0],
        'verification_notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw Exception('Failed to verify action plan: $e');
    }
  }

  Future<Map<String, int>> getActionPlanStats() async {
    try {
      final response = await _client.from('action_plans').select('status');
      final plans = response as List;

      int open = 0, inProgress = 0, underReview = 0, completed = 0, verified = 0, closed = 0, overdue = 0;

      for (final plan in plans) {
        final status = plan['status'] as String? ?? 'open';
        switch (status) {
          case 'open':
            open++;
            break;
          case 'in_progress':
            inProgress++;
            break;
          case 'under_review':
            underReview++;
            break;
          case 'completed':
            completed++;
            break;
          case 'verified':
            verified++;
            break;
          case 'closed':
            closed++;
            break;
          case 'overdue':
            overdue++;
            break;
        }
      }

      return {
        'open': open,
        'in_progress': inProgress,
        'under_review': underReview,
        'completed': completed,
        'verified': verified,
        'closed': closed,
        'overdue': overdue,
        'total': plans.length,
      };
    } catch (e) {
      throw Exception('Failed to fetch action plan stats: $e');
    }
  }

  Future<List<ActionPlan>> getDependencies(String id) async {
    try {
      final plan = await getActionPlan(id);
      if (plan == null || plan.dependsOn == null || plan.dependsOn!.isEmpty) {
        return [];
      }

      final response = await _client.from('action_plans')
          .select()
          .inFilter('id', plan.dependsOn!);
      return (response as List).map((json) => ActionPlan.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch dependencies: $e');
    }
  }

  Future<String?> _getOrganisationId() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('profiles')
          .select('organisation_id')
          .eq('id', userId)
          .maybeSingle();

      return response?['organisation_id']?.toString();
    } catch (e) {
      return null;
    }
  }
}