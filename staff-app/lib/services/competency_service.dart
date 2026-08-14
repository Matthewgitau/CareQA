import 'package:supabase_flutter/supabase_flutter.dart';
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

  Future<List<Map<String, dynamic>>> getRoleRequirements(String roleType) async {
    try {
      final response = await _client
          .from('role_competency_requirements')
          .select('*, competency_framework(*)')
          .eq('role_type', roleType)
          .order('required_level', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching role requirements: $e');
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
        final competency = requirement['competency_framework'] as Map<String, dynamic>?;
        if (competency == null) continue;

        final competencyId = competency['id'] as String;
        final requiredLevel = requirement['required_level'] as int;
        final currentLevel = currentLevels[competencyId] ?? 0;

        if (currentLevel == 0) {
          missing.add(competencyId);
        } else if (currentLevel < requiredLevel) {
          belowLevel[competencyId] = requiredLevel - currentLevel;
        } else {
          met.add(competencyId);
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
}