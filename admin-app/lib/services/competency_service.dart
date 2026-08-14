import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/competency_framework.dart';
import '../models/competency_assessment.dart';

class CompetencyService {
  final SupabaseClient _client;

  CompetencyService(this._client);

  // ==================== COMPETENCY FRAMEWORK ====================

  Future<List<Competency>> getCompetencyFramework() async {
    try {
      final response = await _client
          .from('competency_framework')
          .select('*')
          .eq('is_active', true)
          .order('category', ascending: true)
          .order('competency_code', ascending: true);
      return (response as List).map((json) => Competency.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching competency framework: $e');
      return [];
    }
  }

  Future<List<Competency>> getCompetenciesByCategory(String category) async {
    try {
      final response = await _client
          .from('competency_framework')
          .select('*')
          .eq('is_active', true)
          .eq('category', category)
          .order('competency_code', ascending: true);
      return (response as List).map((json) => Competency.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching competencies by category: $e');
      return [];
    }
  }

  // ==================== ROLE REQUIREMENTS ====================

  Future<List<RoleRequirement>> getRoleRequirements(String roleType) async {
    try {
      final response = await _client
          .from('role_competency_requirements')
          .select('*, competency_framework(*)')
          .eq('role_type', roleType)
          .order('required_level', ascending: false);
      return (response as List).map((json) => RoleRequirement.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching role requirements: $e');
      return [];
    }
  }

  Future<List<RoleRequirement>> getAllRoleRequirements() async {
    try {
      final response = await _client
          .from('role_competency_requirements')
          .select('*, competency_framework(*)')
          .order('role_type', ascending: true)
          .order('required_level', ascending: false);
      return (response as List).map((json) => RoleRequirement.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching all role requirements: $e');
      return [];
    }
  }

  // ==================== STAFF COMPETENCIES ====================

  Future<List<CompetencyAssessment>> getStaffCompetencies(String staffId) async {
    try {
      final response = await _client
          .from('staff_competency_assessments')
          .select('*')
          .eq('staff_id', staffId)
          .eq('is_current', true)
          .order('assessment_date', ascending: false);
      return (response as List).map((json) => CompetencyAssessment.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching staff competencies: $e');
      return [];
    }
  }

  Future<Map<String, int>> getStaffCompetencyLevels(String staffId) async {
    try {
      final assessments = await getStaffCompetencies(staffId);
      final levels = <String, int>{};
      for (final assessment in assessments) {
        for (final rating in assessment.competencyRatings) {
          levels[rating.competencyId] = rating.achievedLevel;
        }
      }
      return levels;
    } catch (e) {
      print('Error fetching staff competency levels: $e');
      return {};
    }
  }

  // ==================== ASSESSMENTS ====================

  Future<CompetencyAssessment?> createAssessment(CompetencyAssessment assessment) async {
    try {
      final data = assessment.toJson();
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
      }

      final response = await _client
          .from('staff_competency_assessments')
          .insert(data)
          .select()
          .single();

      return CompetencyAssessment.fromJson(response);
    } catch (e) {
      print('Error creating assessment: $e');
      rethrow;
    }
  }

  Future<CompetencyAssessment?> updateAssessment(String id, Map<String, dynamic> data) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _client
          .from('staff_competency_assessments')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return CompetencyAssessment.fromJson(response);
    } catch (e) {
      print('Error updating assessment: $e');
      rethrow;
    }
  }

  Future<void> approveAssessment(String assessmentId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client
          .from('staff_competency_assessments')
          .update({
            'status': 'approved',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assessmentId);
    } catch (e) {
      print('Error approving assessment: $e');
      rethrow;
    }
  }

  Future<void> rejectAssessment(String assessmentId, String reason) async {
    try {
      await _client
          .from('staff_competency_assessments')
          .update({
            'status': 'rejected',
            'assessor_notes': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assessmentId);
    } catch (e) {
      print('Error rejecting assessment: $e');
      rethrow;
    }
  }

  // ==================== DEVELOPMENT PLANS ====================

  Future<DevelopmentPlan?> getDevelopmentPlan(String staffId) async {
    try {
      final response = await _client
          .from('staff_development_plans')
          .select('*')
          .eq('staff_id', staffId)
          .eq('status', 'active')
          .order('created_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return DevelopmentPlan.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching development plan: $e');
      return null;
    }
  }

  Future<DevelopmentPlan?> createDevelopmentPlan(DevelopmentPlan plan) async {
    try {
      final data = plan.toJson();
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
      }

      final response = await _client
          .from('staff_development_plans')
          .insert(data)
          .select()
          .single();

      return DevelopmentPlan.fromJson(response);
    } catch (e) {
      print('Error creating development plan: $e');
      rethrow;
    }
  }

  Future<void> updateDevelopmentPlan(String id, Map<String, dynamic> data) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();
      await _client
          .from('staff_development_plans')
          .update(data)
          .eq('id', id);
    } catch (e) {
      print('Error updating development plan: $e');
      rethrow;
    }
  }

  // ==================== GAP ANALYSIS ====================

  Future<Map<String, dynamic>> calculateGap(String staffId, String roleType) async {
    try {
      // Get required competencies for role
      final requirements = await getRoleRequirements(roleType);
      
      // Get current competency levels
      final currentLevels = await getStaffCompetencyLevels(staffId);

      final gaps = <String, dynamic>{};
      final missing = <String>[];
      final belowLevel = <String, int>{};
      final met = <String>[];

      for (final requirement in requirements) {
        final currentLevel = currentLevels[requirement.competencyId] ?? 0;
        if (currentLevel == 0) {
          missing.add(requirement.competencyId);
        } else if (currentLevel < requirement.requiredLevel) {
          belowLevel[requirement.competencyId] = requirement.requiredLevel - currentLevel;
        } else {
          met.add(requirement.competencyId);
        }
      }

      gaps['missing'] = missing;
      gaps['below_level'] = belowLevel;
      gaps['met'] = met;
      gaps['total_required'] = requirements.length;
      gaps['total_met'] = met.length;
      gaps['compliance_percentage'] = requirements.isNotEmpty 
        ? (met.length / requirements.length * 100).round() 
        : 0;

      return gaps;
    } catch (e) {
      print('Error calculating gap: $e');
      return {};
    }
  }

  Future<List<Competency>> getRecommendedTraining(String staffId, String roleType) async {
    try {
      final gap = await calculateGap(staffId, roleType);
      final missingIds = gap['missing'] as List<String>? ?? [];
      final belowLevelIds = (gap['below_level'] as Map<String, int>?)?.keys.toList() ?? [];

      final neededIds = [...missingIds, ...belowLevelIds];

      if (neededIds.isEmpty) return [];

      // Fetch all competencies and filter client-side
      final allCompetencies = await getCompetencyFramework();
      return allCompetencies.where((c) => neededIds.contains(c.id)).toList();
    } catch (e) {
      print('Error getting recommended training: $e');
      return [];
    }
  }

  // ==================== STATS AND REPORTS ====================

  Future<Map<String, dynamic>> getCompetencyStats(String staffId) async {
    try {
      final assessments = await getStaffCompetencies(staffId);
      
      if (assessments.isEmpty) {
        return {
          'total_assessed': 0,
          'average_score': 0.0,
          'competent_count': 0,
          'development_needed_count': 0,
          'not_competent_count': 0,
        };
      }

      int competentCount = 0;
      int developmentNeededCount = 0;
      int notCompetentCount = 0;
      double totalScore = 0;

      for (final assessment in assessments) {
        totalScore += assessment.getAverageScore();
        switch (assessment.overallRating) {
          case 'competent':
            competentCount++;
            break;
          case 'development_needed':
            developmentNeededCount++;
            break;
          case 'not_competent':
            notCompetentCount++;
            break;
        }
      }

      return {
        'total_assessed': assessments.length,
        'average_score': totalScore / assessments.length,
        'competent_count': competentCount,
        'development_needed_count': developmentNeededCount,
        'not_competent_count': notCompetentCount,
      };
    } catch (e) {
      print('Error fetching competency stats: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getCompetencySummary() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return {};

      final profile = await _client
          .from('profiles')
          .select('organisation_id')
          .eq('id', user.id)
          .single();

      final orgId = profile['organisation_id'];

      final response = await _client
          .from('staff_competency_assessments')
          .select('*, staff:profiles!staff_id(full_name)')
          .eq('organisation_id', orgId)
          .eq('is_current', true);

      final assessments = response as List;
      
      if (assessments.isEmpty) {
        return {
          'total_assessments': 0,
          'competent': 0,
          'development_needed': 0,
          'not_competent': 0,
          'average_score': 0.0,
        };
      }

      int competent = 0, developmentNeeded = 0, notCompetent = 0;
      double totalScore = 0;

      for (final assessment in assessments) {
        final ratings = assessment['competency_ratings'] as List? ?? [];
        if (ratings.isNotEmpty) {
          final avg = ratings.fold<double>(0, (sum, r) => sum + (r['achieved_level'] ?? 0)) / ratings.length;
          totalScore += avg;
        }
        
        switch (assessment['overall_rating']) {
          case 'competent': competent++; break;
          case 'development_needed': developmentNeeded++; break;
          case 'not_competent': notCompetent++; break;
        }
      }

      return {
        'total_assessments': assessments.length,
        'competent': competent,
        'development_needed': developmentNeeded,
        'not_competent': notCompetent,
        'average_score': totalScore / assessments.length,
      };
    } catch (e) {
      print('Error fetching competency summary: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getExpiredCompetencies() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final profile = await _client
          .from('profiles')
          .select('organisation_id')
          .eq('id', user.id)
          .single();

      final response = await _client
          .from('staff_competency_assessments')
          .select('*, staff:profiles!staff_id(full_name), competency:competency_framework(competency_name)')
          .eq('organisation_id', profile['organisation_id'])
          .eq('is_current', true)
          .lt('expiry_date', DateTime.now().toIso8601String().split('T').first)
          .order('expiry_date', ascending: true);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      print('Error fetching expired competencies: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getExpiringCompetencies(int daysUntilExpiry) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final profile = await _client
          .from('profiles')
          .select('organisation_id')
          .eq('id', user.id)
          .single();

      final expiryDate = DateTime.now().add(Duration(days: daysUntilExpiry)).toIso8601String().split('T').first;

      final response = await _client
          .from('staff_competency_assessments')
          .select('*, staff:profiles!staff_id(full_name), competency:competency_framework(competency_name)')
          .eq('organisation_id', profile['organisation_id'])
          .eq('is_current', true)
          .gte('expiry_date', DateTime.now().toIso8601String().split('T').first)
          .lte('expiry_date', expiryDate)
          .order('expiry_date', ascending: true);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      print('Error fetching expiring competencies: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecordsByType(String assessmentType) async {
    try {
      final response = await _client
          .from('staff_competency_assessments')
          .select('*, staff:profiles!staff_id(full_name)')
          .eq('assessment_type', assessmentType)
          .order('assessment_date', ascending: false);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      print('Error fetching records by type: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllRecords() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final profile = await _client
          .from('profiles')
          .select('organisation_id')
          .eq('id', user.id)
          .single();

      final response = await _client
          .from('staff_competency_assessments')
          .select('*, staff:profiles!staff_id(full_name)')
          .eq('organisation_id', profile['organisation_id'])
          .order('assessment_date', ascending: false);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      print('Error fetching all records: $e');
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