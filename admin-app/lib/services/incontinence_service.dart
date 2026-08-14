import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/incontinence_assessment.dart';

class IncontinenceService {
  final SupabaseClient _client;

  IncontinenceService(this._client);

  /// Create a new incontinence assessment
  Future<IncontinenceAssessment> createAssessment(IncontinenceAssessment assessment) async {
    try {
      final data = await _client
          .from('incontinence_risk_assessments')
          .insert(assessment.toMap())
          .select()
          .single();

      return IncontinenceAssessment.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create assessment: ${e.message}');
    }
  }

  /// Get assessment by ID
  Future<IncontinenceAssessment> getAssessment(String id) async {
    try {
      final data = await _client
          .from('incontinence_risk_assessments')
          .select()
          .eq('id', id)
          .single();

      return IncontinenceAssessment.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessment: ${e.message}');
    }
  }

  /// Get all assessments for a service user
  Future<List<IncontinenceAssessment>> getAssessments({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client.from('incontinence_risk_assessments').select();

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
          .map((item) => IncontinenceAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments: ${e.message}');
    }
  }

  /// Update an existing assessment
  Future<IncontinenceAssessment> updateAssessment(String id, IncontinenceAssessment assessment) async {
    try {
      final data = await _client
          .from('incontinence_risk_assessments')
          .update(assessment.toMap())
          .eq('id', id)
          .select()
          .single();

      return IncontinenceAssessment.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update assessment: ${e.message}');
    }
  }

  /// Delete an assessment
  Future<void> deleteAssessment(String id) async {
    try {
      await _client
          .from('incontinence_risk_assessments')
          .delete()
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete assessment: ${e.message}');
    }
  }

  /// Get assessments that need review (review date passed)
  Future<List<IncontinenceAssessment>> getAssessmentsNeedingReview() async {
    try {
      final data = await _client
          .from('incontinence_risk_assessments')
          .select()
          .not('review_date', 'is', null)
          .lt('review_date', DateTime.now().toUtc())
          .order('review_date', ascending: true);

      return (data as List)
          .map((item) => IncontinenceAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments needing review: ${e.message}');
    }
  }

  /// Get assessments by bladder continence status
  Future<List<IncontinenceAssessment>> getAssessmentsByBladderStatus(
    BladderContinenceStatus status,
  ) async {
    try {
      final data = await _client
          .from('incontinence_risk_assessments')
          .select()
          .eq('bladder_continence_status', status.value)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => IncontinenceAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by bladder status: ${e.message}');
    }
  }

  /// Get assessments by bowel continence status
  Future<List<IncontinenceAssessment>> getAssessmentsByBowelStatus(
    BowelContinenceStatus status,
  ) async {
    try {
      final data = await _client
          .from('incontinence_risk_assessments')
          .select()
          .eq('bowel_continence_status', status.value)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => IncontinenceAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by bowel status: ${e.message}');
    }
  }

  /// Get assessments by frequency
  Future<List<IncontinenceAssessment>> getAssessmentsByFrequency(Frequency frequency) async {
    try {
      final data = await _client
          .from('incontinence_risk_assessments')
          .select()
          .eq('frequency', frequency.value)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => IncontinenceAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by frequency: ${e.message}');
    }
  }

  /// Get assessments with continence service referral
  Future<List<IncontinenceAssessment>> getAssessmentsWithReferral() async {
    try {
      final data = await _client
          .from('incontinence_risk_assessments')
          .select()
          .eq('referred_to_continence_service', true)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => IncontinenceAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with referral: ${e.message}');
    }
  }

  /// Get assessments with bladder diary completed
  Future<List<IncontinenceAssessment>> getAssessmentsWithBladderDiary() async {
    try {
      final data = await _client
          .from('incontinence_risk_assessments')
          .select()
          .eq('bladder_diary_completed', true)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => IncontinenceAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with bladder diary: ${e.message}');
    }
  }

  /// Get assessments with bowel diary completed
  Future<List<IncontinenceAssessment>> getAssessmentsWithBowelDiary() async {
    try {
      final data = await _client
          .from('incontinence_risk_assessments')
          .select()
          .eq('bowel_diary_completed', true)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => IncontinenceAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with bowel diary: ${e.message}');
    }
  }

  /// Get statistics for incontinence assessments
  Future<Map<String, dynamic>> getStatistics({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client.from('incontinence_risk_assessments').select('''
        count(*),
        bladder_continence_status,
        bowel_continence_status,
        frequency,
        referred_to_continence_service,
        bladder_diary_completed,
        bowel_diary_completed
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
  Future<List<IncontinenceAssessment>> getRecentAssessments({
    String? serviceUserId,
    int days = 30,
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: days));

    return getAssessments(
      serviceUserId: serviceUserId,
      startDate: startDate,
    );
  }

  /// Get assessments by skin condition
  Future<List<IncontinenceAssessment>> getAssessmentsBySkinCondition(
    SkinCondition condition,
  ) async {
    try {
      final data = await _client
          .from('incontinence_risk_assessments')
          .select()
          .eq('skin_condition', condition.value)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => IncontinenceAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by skin condition: ${e.message}');
    }
  }

  /// Get assessments by toilet accessibility
  Future<List<IncontinenceAssessment>> getAssessmentsByToiletAccessibility(
    ToiletAccessibility accessibility,
  ) async {
    try {
      final data = await _client
          .from('incontinence_risk_assessments')
          .select()
          .eq('toilet_accessibility', accessibility.value)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => IncontinenceAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by toilet accessibility: ${e.message}');
    }
  }

  /// Get assessments with specific triggers
  Future<List<IncontinenceAssessment>> getAssessmentsByTriggers(List<String> triggerList) async {
    try {
      final data = await _client
          .from('incontinence_risk_assessments')
          .select()
          .overlaps('triggers', triggerList)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => IncontinenceAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by triggers: ${e.message}');
    }
  }

  /// Get assessments with specific incontinence products
  Future<List<IncontinenceAssessment>> getAssessmentsByProducts(List<String> productList) async {
    try {
      final data = await _client
          .from('incontinence_risk_assessments')
          .select()
          .overlaps('incontinence_products', productList)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => IncontinenceAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by products: ${e.message}');
    }
  }
}