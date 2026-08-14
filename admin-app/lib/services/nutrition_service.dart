import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/nutrition_assessment.dart';

class NutritionService {
  final SupabaseClient _client;

  NutritionService(this._client);

  /// Create a new nutrition risk assessment
  Future<NutritionAssessment> createAssessment(NutritionAssessment assessment) async {
    try {
      final data = await _client
          .from('nutrition_risk_assessments')
          .insert(assessment.toMap())
          .select()
          .single();

      return NutritionAssessment.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create assessment: ${e.message}');
    }
  }

  /// Get assessment by ID
  Future<NutritionAssessment> getAssessment(String id) async {
    try {
      final data = await _client
          .from('nutrition_risk_assessments')
          .select()
          .eq('id', id)
          .single();

      return NutritionAssessment.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessment: ${e.message}');
    }
  }

  /// Get all assessments for a service user
  Future<List<NutritionAssessment>> getAssessments({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client.from('nutrition_risk_assessments').select();

      if (serviceUserId != null) {
        query = query.eq('service_user_id', serviceUserId);
      }

      if (startDate != null && endDate != null) {
        query = query.gte('assessment_date', startDate.toUtc()).lte('assessment_date', endDate.toUtc());
      } else if (startDate != null) {
        query = query.gte('assessment_date', startDate.toUtc());
      } else if (endDate != null) {
        query = query.lte('assessment_date', endDate.toUtc());
      }

      final data = await query.order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => NutritionAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments: ${e.message}');
    }
  }

  /// Update an existing assessment
  Future<NutritionAssessment> updateAssessment(String id, NutritionAssessment assessment) async {
    try {
      final data = await _client
          .from('nutrition_risk_assessments')
          .update(assessment.toMap())
          .eq('id', id)
          .select()
          .single();

      return NutritionAssessment.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update assessment: ${e.message}');
    }
  }

  /// Delete an assessment
  Future<void> deleteAssessment(String id) async {
    try {
      await _client
          .from('nutrition_risk_assessments')
          .delete()
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete assessment: ${e.message}');
    }
  }

  /// Get assessments that need review (review date passed)
  Future<List<NutritionAssessment>> getAssessmentsNeedingReview() async {
    try {
      final data = await _client
          .from('nutrition_risk_assessments')
          .select()
          .not('review_date', 'is', null)
          .lt('review_date', DateTime.now().toUtc())
          .order('review_date', ascending: true);

      return (data as List)
          .map((item) => NutritionAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments needing review: ${e.message}');
    }
  }

  /// Get assessments by risk category
  Future<List<NutritionAssessment>> getAssessmentsByRiskCategory(String riskCategory) async {
    try {
      final data = await _client
          .from('nutrition_risk_assessments')
          .select()
          .eq('risk_category', riskCategory)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => NutritionAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by risk category: ${e.message}');
    }
  }

  /// Get assessments by MUST score
  Future<List<NutritionAssessment>> getAssessmentsByMustScore(int mustScore) async {
    try {
      final data = await _client
          .from('nutrition_risk_assessments')
          .select()
          .eq('must_total_score', mustScore)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => NutritionAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by MUST score: ${e.message}');
    }
  }

  /// Get assessments with dietitian referral
  Future<List<NutritionAssessment>> getAssessmentsWithDietitianReferral() async {
    try {
      final data = await _client
          .from('nutrition_risk_assessments')
          .select()
          .eq('referred_to_dietitian', true)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => NutritionAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with dietitian referral: ${e.message}');
    }
  }

  /// Get assessments with supplementation required
  Future<List<NutritionAssessment>> getAssessmentsWithSupplementation() async {
    try {
      final data = await _client
          .from('nutrition_risk_assessments')
          .select()
          .eq('supplementation_required', true)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => NutritionAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with supplementation: ${e.message}');
    }
  }

  /// Get assessments with swallowing difficulties
  Future<List<NutritionAssessment>> getAssessmentsWithSwallowingDifficulties() async {
    try {
      final data = await _client
          .from('nutrition_risk_assessments')
          .select()
          .eq('swallowing_difficulties', true)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => NutritionAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with swallowing difficulties: ${e.message}');
    }
  }

  /// Get assessments by BMI range
  Future<List<NutritionAssessment>> getAssessmentsByBmiRange(double minBmi, double maxBmi) async {
    try {
      final data = await _client
          .from('nutrition_risk_assessments')
          .select()
          .gte('bmi', minBmi)
          .lte('bmi', maxBmi)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => NutritionAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by BMI range: ${e.message}');
    }
  }

  /// Get assessments by weight loss percentage range
  Future<List<NutritionAssessment>> getAssessmentsByWeightLossRange(double minLoss, double maxLoss) async {
    try {
      final data = await _client
          .from('nutrition_risk_assessments')
          .select()
          .gte('weight_loss_percentage', minLoss)
          .lte('weight_loss_percentage', maxLoss)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => NutritionAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by weight loss range: ${e.message}');
    }
  }

  /// Get statistics for nutrition assessments
  Future<Map<String, dynamic>> getStatistics({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client.from('nutrition_risk_assessments').select('''
        count(*),
        risk_category,
        must_total_score,
        bmi,
        weight_loss_percentage,
        referred_to_dietitian,
        supplementation_required,
        swallowing_difficulties
      ''');

      if (serviceUserId != null) {
        query = query.eq('service_user_id', serviceUserId);
      }

      if (startDate != null && endDate != null) {
        query = query.gte('assessment_date', startDate.toUtc()).lte('assessment_date', endDate.toUtc());
      }

      final data = await query;

      return {'data': data};
    } on PostgrestException catch (e) {
      throw Exception('Failed to get statistics: ${e.message}');
    }
  }

  /// Get recent assessments (last 30 days)
  Future<List<NutritionAssessment>> getRecentAssessments({
    String? serviceUserId,
    int days = 30,
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: days));

    return getAssessments(
      serviceUserId: serviceUserId,
      startDate: startDate,
    );
  }

  /// Get assessments with specific dietary requirements
  Future<List<NutritionAssessment>> getAssessmentsByDietaryRequirements(String requirement) async {
    try {
      final data = await _client
          .from('nutrition_risk_assessments')
          .select()
          .ilike('dietary_requirements', '%$requirement%')
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => NutritionAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by dietary requirements: ${e.message}');
    }
  }

  /// Get assessments with specific food preferences/allergies
  Future<List<NutritionAssessment>> getAssessmentsByFoodPreferences(String preference) async {
    try {
      final data = await _client
          .from('nutrition_risk_assessments')
          .select()
          .ilike('food_preferences_allergies', '%$preference%')
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => NutritionAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by food preferences: ${e.message}');
    }
  }

  /// Get assessments by acute disease effect score
  Future<List<NutritionAssessment>> getAssessmentsByAcuteDiseaseEffect(int score) async {
    try {
      final data = await _client
          .from('nutrition_risk_assessments')
          .select()
          .eq('acute_disease_effect_score', score)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => NutritionAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by acute disease effect: ${e.message}');
    }
  }

  /// Get assessments with weight check due
  Future<List<NutritionAssessment>> getAssessmentsWithWeightCheckDue() async {
    try {
      final data = await _client
          .from('nutrition_risk_assessments')
          .select()
          .not('next_weight_check_date', 'is', null)
          .lt('next_weight_check_date', DateTime.now().toUtc())
          .order('next_weight_check_date', ascending: true);

      return (data as List)
          .map((item) => NutritionAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with weight check due: ${e.message}');
    }
  }

  /// Get assessments by assessor name
  Future<List<NutritionAssessment>> getAssessmentsByAssessor(String assessorName) async {
    try {
      final data = await _client
          .from('nutrition_risk_assessments')
          .select()
          .eq('assessor_name', assessorName)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => NutritionAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by assessor: ${e.message}');
    }
  }
}