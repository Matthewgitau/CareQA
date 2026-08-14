import 'package:supabase/supabase.dart';
import 'package:staff_app/models/incontinence_assessment.dart';

class IncontinenceService {
  final SupabaseClient _client;

  IncontinenceService(this._client);

  /// Create a new incontinence assessment
  Future<IncontinenceAssessment> createAssessment(IncontinenceAssessment assessment) async {
    final response = await _client
        .from('incontinence_risk_assessments')
        .insert(assessment.toMap())
        .select()
        .single();

    if (response.error != null) {
      throw Exception('Failed to create assessment: ${response.error?.message}');
    }

    return IncontinenceAssessment.fromMap(response.data);
  }

  /// Get assessment by ID
  Future<IncontinenceAssessment> getAssessment(String id) async {
    final response = await _client
        .from('incontinence_risk_assessments')
        .select()
        .eq('id', id)
        .single();

    if (response.error != null) {
      throw Exception('Failed to get assessment: ${response.error?.message}');
    }

    return IncontinenceAssessment.fromMap(response.data);
  }

  /// Get all assessments for a service user
  Future<List<IncontinenceAssessment>> getAssessments({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
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

    query = query.order('assessment_date', ascending: false);

    final response = await query;

    if (response.error != null) {
      throw Exception('Failed to get assessments: ${response.error?.message}');
    }

    return (response.data as List)
        .map((item) => IncontinenceAssessment.fromMap(item))
        .toList();
  }

  /// Update an existing assessment
  Future<IncontinenceAssessment> updateAssessment(String id, IncontinenceAssessment assessment) async {
    final response = await _client
        .from('incontinence_risk_assessments')
        .update(assessment.toMap())
        .eq('id', id)
        .select()
        .single();

    if (response.error != null) {
      throw Exception('Failed to update assessment: ${response.error?.message}');
    }

    return IncontinenceAssessment.fromMap(response.data);
  }

  /// Delete an assessment
  Future<void> deleteAssessment(String id) async {
    final response = await _client
        .from('incontinence_risk_assessments')
        .delete()
        .eq('id', id);

    if (response.error != null) {
      throw Exception('Failed to delete assessment: ${response.error?.message}');
    }
  }

  /// Get assessments that need review (review date passed)
  Future<List<IncontinenceAssessment>> getAssessmentsNeedingReview() async {
    final response = await _client
        .from('incontinence_risk_assessments')
        .select()
        .is_('review_date', 'not.null')
        .lt('review_date', DateTime.now().toUtc())
        .order('review_date', ascending: true);

    if (response.error != null) {
      throw Exception('Failed to get assessments needing review: ${response.error?.message}');
    }

    return (response.data as List)
        .map((item) => IncontinenceAssessment.fromMap(item))
        .toList();
  }

  /// Get assessments by bladder continence status
  Future<List<IncontinenceAssessment>> getAssessmentsByBladderStatus(
    BladderContinenceStatus status,
  ) async {
    final response = await _client
        .from('incontinence_risk_assessments')
        .select()
        .eq('bladder_continence_status', status.value)
        .order('assessment_date', ascending: false);

    if (response.error != null) {
      throw Exception('Failed to get assessments by bladder status: ${response.error?.message}');
    }

    return (response.data as List)
        .map((item) => IncontinenceAssessment.fromMap(item))
        .toList();
  }

  /// Get assessments by bowel continence status
  Future<List<IncontinenceAssessment>> getAssessmentsByBowelStatus(
    BowelContinenceStatus status,
  ) async {
    final response = await _client
        .from('incontinence_risk_assessments')
        .select()
        .eq('bowel_continence_status', status.value)
        .order('assessment_date', ascending: false);

    if (response.error != null) {
      throw Exception('Failed to get assessments by bowel status: ${response.error?.message}');
    }

    return (response.data as List)
        .map((item) => IncontinenceAssessment.fromMap(item))
        .toList();
  }

  /// Get assessments by frequency
  Future<List<IncontinenceAssessment>> getAssessmentsByFrequency(Frequency frequency) async {
    final response = await _client
        .from('incontinence_risk_assessments')
        .select()
        .eq('frequency', frequency.value)
        .order('assessment_date', ascending: false);

    if (response.error != null) {
      throw Exception('Failed to get assessments by frequency: ${response.error?.message}');
    }

    return (response.data as List)
        .map((item) => IncontinenceAssessment.fromMap(item))
        .toList();
  }

  /// Get assessments with continence service referral
  Future<List<IncontinenceAssessment>> getAssessmentsWithReferral() async {
    final response = await _client
        .from('incontinence_risk_assessments')
        .select()
        .eq('referred_to_continence_service', true)
        .order('assessment_date', ascending: false);

    if (response.error != null) {
      throw Exception('Failed to get assessments with referral: ${response.error?.message}');
    }

    return (response.data as List)
        .map((item) => IncontinenceAssessment.fromMap(item))
        .toList();
  }

  /// Get assessments with bladder diary completed
  Future<List<IncontinenceAssessment>> getAssessmentsWithBladderDiary() async {
    final response = await _client
        .from('incontinence_risk_assessments')
        .select()
        .eq('bladder_diary_completed', true)
        .order('assessment_date', ascending: false);

    if (response.error != null) {
      throw Exception('Failed to get assessments with bladder diary: ${response.error?.message}');
    }

    return (response.data as List)
        .map((item) => IncontinenceAssessment.fromMap(item))
        .toList();
  }

  /// Get assessments with bowel diary completed
  Future<List<IncontinenceAssessment>> getAssessmentsWithBowelDiary() async {
    final response = await _client
        .from('incontinence_risk_assessments')
        .select()
        .eq('bowel_diary_completed', true)
        .order('assessment_date', ascending: false);

    if (response.error != null) {
      throw Exception('Failed to get assessments with bowel diary: ${response.error?.message}');
    }

    return (response.data as List)
        .map((item) => IncontinenceAssessment.fromMap(item))
        .toList();
  }

  /// Get statistics for incontinence assessments
  Future<Map<String, dynamic>> getStatistics({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
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

    final response = await query;

    if (response.error != null) {
      throw Exception('Failed to get statistics: ${response.error?.message}');
    }

    return response.data;
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
    final response = await _client
        .from('incontinence_risk_assessments')
        .select()
        .eq('skin_condition', condition.value)
        .order('assessment_date', ascending: false);

    if (response.error != null) {
      throw Exception('Failed to get assessments by skin condition: ${response.error?.message}');
    }

    return (response.data as List)
        .map((item) => IncontinenceAssessment.fromMap(item))
        .toList();
  }

  /// Get assessments by toilet accessibility
  Future<List<IncontinenceAssessment>> getAssessmentsByToiletAccessibility(
    ToiletAccessibility accessibility,
  ) async {
    final response = await _client
        .from('incontinence_risk_assessments')
        .select()
        .eq('toilet_accessibility', accessibility.value)
        .order('assessment_date', ascending: false);

    if (response.error != null) {
      throw Exception('Failed to get assessments by toilet accessibility: ${response.error?.message}');
    }

    return (response.data as List)
        .map((item) => IncontinenceAssessment.fromMap(item))
        .toList();
  }

  /// Get assessments with specific triggers
  Future<List<IncontinenceAssessment>> getAssessmentsByTriggers(List<String> triggerList) async {
    final response = await _client
        .from('incontinence_risk_assessments')
        .select()
        .overlaps('triggers', triggerList)
        .order('assessment_date', ascending: false);

    if (response.error != null) {
      throw Exception('Failed to get assessments by triggers: ${response.error?.message}');
    }

    return (response.data as List)
        .map((item) => IncontinenceAssessment.fromMap(item))
        .toList();
  }

  /// Get assessments with specific incontinence products
  Future<List<IncontinenceAssessment>> getAssessmentsByProducts(List<String> productList) async {
    final response = await _client
        .from('incontinence_risk_assessments')
        .select()
        .overlaps('incontinence_products', productList)
        .order('assessment_date', ascending: false);

    if (response.error != null) {
      throw Exception('Failed to get assessments by products: ${response.error?.message}');
    }

    return (response.data as List)
        .map((item) => IncontinenceAssessment.fromMap(item))
        .toList();
  }
}