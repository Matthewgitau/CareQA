import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/policy.dart';

class PolicyService {
  final SupabaseClient _client;

  PolicyService(this._client);

  Future<List<Policy>> getPolicies({
    String? status,
    String? category,
    String? department,
  }) async {
    try {
      var query = _client.from('policy_library').select();

      if (status != null) {
        query = query.eq('status', status);
      }
      if (category != null) {
        query = query.eq('category', category);
      }
      if (department != null) {
        query = query.eq('department', department);
      }

      final response = await query.order('updated_at', ascending: false);
      return (response as List).map((json) => Policy.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch policies: $e');
    }
  }

  Future<Policy?> getPolicy(String id) async {
    try {
      final response = await _client.from('policy_library').select().eq('id', id).maybeSingle();
      if (response == null) return null;
      return Policy.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch policy: $e');
    }
  }

  Future<Policy> createPolicy(Policy policy) async {
    try {
      final orgId = await _getOrganisationId();
      if (orgId == null) throw Exception('No organisation found');

      final data = policy.toJson();
      data['organisation_id'] = orgId;
      data['created_by'] = _client.auth.currentUser?.id;
      data['created_at'] = DateTime.now().toIso8601String();

      final response = await _client.from('policy_library').insert(data).select().single();
      return Policy.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create policy: $e');
    }
  }

  Future<Policy> updatePolicy(String id, Map<String, dynamic> data) async {
    try {
      data['updated_by'] = _client.auth.currentUser?.id;
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client.from('policy_library').update(data).eq('id', id).select().single();
      return Policy.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update policy: $e');
    }
  }

  Future<void> deletePolicy(String id) async {
    try {
      await _client.from('policy_library').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete policy: $e');
    }
  }

  Future<List<Policy>> getPoliciesByCategory(String category) async {
    try {
      final response = await _client.from('policy_library')
          .select()
          .eq('category', category)
          .order('policy_title');
      return (response as List).map((json) => Policy.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch policies by category: $e');
    }
  }

  Future<List<Policy>> getPoliciesByStatus(String status) async {
    try {
      final response = await _client.from('policy_library')
          .select()
          .eq('status', status)
          .order('updated_at', ascending: false);
      return (response as List).map((json) => Policy.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch policies by status: $e');
    }
  }

  Future<List<Policy>> getPoliciesForReview() async {
    try {
      final response = await _client.from('policy_library')
          .select()
          .lte('next_review_date', DateTime.now().toIso8601String().split('T')[0])
          .order('next_review_date', ascending: true);
      return (response as List).map((json) => Policy.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch policies for review: $e');
    }
  }

  Future<List<Policy>> getPoliciesForAcknowledgment(String staffId) async {
    try {
      final response = await _client.from('policy_library')
          .select()
          .eq('status', 'published')
          .eq('is_mandatory', true)
          .order('publish_date', ascending: false);
      
      final policies = (response as List).map((json) => Policy.fromJson(json)).toList();
      return policies.where((policy) => !policy.hasStaffAcknowledged(staffId)).toList();
    } catch (e) {
      throw Exception('Failed to fetch policies for acknowledgment: $e');
    }
  }

  Future<Policy> publishPolicy(String id, {String? publishedBy}) async {
    try {
      final data = {
        'status': 'published',
        'publish_date': DateTime.now().toIso8601String().split('T')[0],
        'published_by': publishedBy ?? _client.auth.currentUser?.id,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client.from('policy_library').update(data).eq('id', id).select().single();
      return Policy.fromJson(response);
    } catch (e) {
      throw Exception('Failed to publish policy: $e');
    }
  }

  Future<Policy> archivePolicy(String id) async {
    try {
      final data = {
        'status': 'archived',
        'archived_date': DateTime.now().toIso8601String().split('T')[0],
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client.from('policy_library').update(data).eq('id', id).select().single();
      return Policy.fromJson(response);
    } catch (e) {
      throw Exception('Failed to archive policy: $e');
    }
  }

  Future<Policy> reviewPolicy(String id, String notes) async {
    try {
      final reviewEntry = {
        'date': DateTime.now().toIso8601String(),
        'reviewer': _client.auth.currentUser?.id ?? 'unknown',
        'notes': notes,
        'changes': 'Policy reviewed',
      };

      final policy = await getPolicy(id);
      if (policy == null) throw Exception('Policy not found');

      final reviewHistory = List<Map<String, dynamic>>.from(policy.reviewHistory);
      reviewHistory.add(reviewEntry);

      final data = {
        'review_history': reviewHistory,
        'review_date': DateTime.now().toIso8601String().split('T')[0],
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client.from('policy_library').update(data).eq('id', id).select().single();
      return Policy.fromJson(response);
    } catch (e) {
      throw Exception('Failed to review policy: $e');
    }
  }

  Future<void> recordRead(String policyId, String staffId) async {
    try {
      final policy = await getPolicy(policyId);
      if (policy == null) return;

      final readBy = List<Map<String, dynamic>>.from(policy.readBy);
      readBy.add({
        'staff_id': staffId,
        'date': DateTime.now().toIso8601String(),
      });

      await _client.from('policy_library').update({
        'read_by': readBy,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', policyId);
    } catch (e) {
      throw Exception('Failed to record read: $e');
    }
  }

  Future<void> recordAcknowledgment(String policyId, String staffId, {bool acknowledged = true}) async {
    try {
      final policy = await getPolicy(policyId);
      if (policy == null) return;

      final acknowledgedBy = List<Map<String, dynamic>>.from(policy.acknowledgedBy);
      
      // Remove existing entry if any
      acknowledgedBy.removeWhere((entry) => entry['staff_id'] == staffId);
      
      // Add new entry
      acknowledgedBy.add({
        'staff_id': staffId,
        'date': DateTime.now().toIso8601String(),
        'acknowledged': acknowledged,
      });

      await _client.from('policy_library').update({
        'acknowledged_by': acknowledgedBy,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', policyId);
    } catch (e) {
      throw Exception('Failed to record acknowledgment: $e');
    }
  }

  Future<Map<String, int>> getPolicyStats() async {
    try {
      final response = await _client.from('policy_library').select('status, category, is_mandatory');
      final policies = response as List;

      int draft = 0, reviewPending = 0, approved = 0, published = 0, archived = 0;
      final categories = <String, int>{};
      int mandatory = 0;

      for (final policy in policies) {
        final status = policy['status'] as String? ?? 'draft';
        final category = policy['category'] as String? ?? 'other';
        final isMandatory = policy['is_mandatory'] as bool? ?? true;

        switch (status) {
          case 'draft':
            draft++;
            break;
          case 'review_pending':
            reviewPending++;
            break;
          case 'approved':
            approved++;
            break;
          case 'published':
            published++;
            break;
          case 'archived':
            archived++;
            break;
        }

        categories[category] = (categories[category] ?? 0) + 1;

        if (isMandatory) mandatory++;
      }

      return {
        'draft': draft,
        'review_pending': reviewPending,
        'approved': approved,
        'published': published,
        'archived': archived,
        'total': policies.length,
        'mandatory': mandatory,
      };
    } catch (e) {
      throw Exception('Failed to fetch policy stats: $e');
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