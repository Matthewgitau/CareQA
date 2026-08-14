import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/challenging_behaviour_assessment.dart';

class ChallengingBehaviourService {
  final SupabaseClient _client;

  ChallengingBehaviourService(this._client);

  /// Create a new challenging behaviour risk assessment
  Future<ChallengingBehaviourAssessment> createAssessment(ChallengingBehaviourAssessment assessment) async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .insert(assessment.toMap())
          .select()
          .single();

      return ChallengingBehaviourAssessment.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create assessment: ${e.message}');
    }
  }

  /// Get assessment by ID
  Future<ChallengingBehaviourAssessment> getAssessment(String id) async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .eq('id', id)
          .single();

      return ChallengingBehaviourAssessment.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessment: ${e.message}');
    }
  }

  /// Get all assessments for a service user
  Future<List<ChallengingBehaviourAssessment>> getAssessments({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
    String? behaviourType,
    String? riskLevel,
  }) async {
    var query = _client.from('challenging_behaviour_risk_assessments').select();

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

    if (behaviourType != null) {
      query = query.eq('behaviour_type', behaviourType);
    }

    if (riskLevel != null) {
      query = query.eq('risk_level', riskLevel);
    }

    try {
      final data = await query.order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments: ${e.message}');
    }
  }

  /// Update an existing assessment
  Future<ChallengingBehaviourAssessment> updateAssessment(String id, ChallengingBehaviourAssessment assessment) async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .update(assessment.toMap())
          .eq('id', id)
          .select()
          .single();

      return ChallengingBehaviourAssessment.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update assessment: ${e.message}');
    }
  }

  /// Delete an assessment
  Future<void> deleteAssessment(String id) async {
    try {
      await _client
          .from('challenging_behaviour_risk_assessments')
          .delete()
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete assessment: ${e.message}');
    }
  }

  /// Get assessments that need review (review date passed)
  Future<List<ChallengingBehaviourAssessment>> getAssessmentsNeedingReview() async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .not('review_date', 'is', null)
          .lt('review_date', DateTime.now().toUtc())
          .order('review_date', ascending: true);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments needing review: ${e.message}');
    }
  }

  /// Get assessments that need behaviour monitoring (monitoring date passed)
  Future<List<ChallengingBehaviourAssessment>> getAssessmentsNeedingMonitoring() async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .not('next_behaviour_monitoring_date', 'is', null)
          .lt('next_behaviour_monitoring_date', DateTime.now().toUtc())
          .order('next_behaviour_monitoring_date', ascending: true);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments needing monitoring: ${e.message}');
    }
  }

  /// Get assessments by risk level
  Future<List<ChallengingBehaviourAssessment>> getAssessmentsByRiskLevel(String riskLevel) async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .eq('risk_level', riskLevel)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by risk level: ${e.message}');
    }
  }

  /// Get critical/urgent assessments
  Future<List<ChallengingBehaviourAssessment>> getUrgentAssessments() async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .eq('risk_level', 'critical')
          .or('injuries_to_others.eq.true.and.intensity.eq.severe')
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get urgent assessments: ${e.message}');
    }
  }

  /// Get assessments by behaviour type
  Future<List<ChallengingBehaviourAssessment>> getAssessmentsByBehaviourType(String behaviourType) async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .eq('behaviour_type', behaviourType)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by behaviour type: ${e.message}');
    }
  }

  /// Get assessments by intensity
  Future<List<ChallengingBehaviourAssessment>> getAssessmentsByIntensity(String intensity) async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .eq('intensity', intensity)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by intensity: ${e.message}');
    }
  }

  /// Get assessments with PBS plan in place
  Future<List<ChallengingBehaviourAssessment>> getAssessmentsWithPbsPlan() async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .eq('pbs_plan_in_place', true)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with PBS plan: ${e.message}');
    }
  }

  /// Get assessments without PBS plan
  Future<List<ChallengingBehaviourAssessment>> getAssessmentsWithoutPbsPlan() async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .eq('pbs_plan_in_place', false)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments without PBS plan: ${e.message}');
    }
  }

  /// Get assessments with staff trained in de-escalation
  Future<List<ChallengingBehaviourAssessment>> getAssessmentsWithTrainedStaff() async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .eq('staff_trained_de_escalation', true)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with trained staff: ${e.message}');
    }
  }

  /// Get assessments with property damage
  Future<List<ChallengingBehaviourAssessment>> getAssessmentsWithPropertyDamage() async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .eq('property_damage', true)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with property damage: ${e.message}');
    }
  }

  /// Get assessments with injuries to others
  Future<List<ChallengingBehaviourAssessment>> getAssessmentsWithInjuriesToOthers() async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .eq('injuries_to_others', true)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with injuries to others: ${e.message}');
    }
  }

  /// Get assessments with injuries to self
  Future<List<ChallengingBehaviourAssessment>> getAssessmentsWithInjuriesToSelf() async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .eq('injuries_to_self', true)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with injuries to self: ${e.message}');
    }
  }

  /// Get assessments by support needs
  Future<List<ChallengingBehaviourAssessment>> getAssessmentsBySupportNeeds(String supportNeeds) async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .eq('support_needs', supportNeeds)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by support needs: ${e.message}');
    }
  }

  /// Get assessments by medication used
  Future<List<ChallengingBehaviourAssessment>> getAssessmentsByMedication(String medication) async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .eq('medication_used', medication)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by medication: ${e.message}');
    }
  }

  /// Get assessments by frequency
  Future<List<ChallengingBehaviourAssessment>> getAssessmentsByFrequency(String frequency) async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .eq('behaviour_frequency', frequency)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by frequency: ${e.message}');
    }
  }

  /// Get statistics for challenging behaviour assessments
  Future<Map<String, dynamic>> getStatistics({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client.from('challenging_behaviour_risk_assessments').select('''
      count(*),
      behaviour_type,
      behaviour_frequency,
      intensity,
      risk_level,
      injuries_caused,
      injuries_to_self,
      injuries_to_others,
      property_damage,
      staff_trained_de_escalation,
      pbs_plan_in_place,
      support_needs,
      medication_used
    ''');

    if (serviceUserId != null) {
      query = query.eq('service_user_id', serviceUserId);
    }

    if (startDate != null && endDate != null) {
      query = query.gte('assessment_date', startDate.toUtc()).lte('assessment_date', endDate.toUtc());
    }

    try {
      final data = await query;
      return {'data': data};
    } on PostgrestException catch (e) {
      throw Exception('Failed to get statistics: ${e.message}');
    }
  }

  /// Get recent assessments (last 30 days)
  Future<List<ChallengingBehaviourAssessment>> getRecentAssessments({
    String? serviceUserId,
    int days = 30,
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: days));

    return getAssessments(
      serviceUserId: serviceUserId,
      startDate: startDate,
    );
  }

  /// Get assessments with specific triggers
  Future<List<ChallengingBehaviourAssessment>> getAssessmentsByTriggers(List<String> triggerList) async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .overlaps('triggers', triggerList)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by triggers: ${e.message}');
    }
  }

  /// Get assessments with specific warning signs
  Future<List<ChallengingBehaviourAssessment>> getAssessmentsByWarningSigns(List<String> warningSigns) async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .overlaps('warning_signs', warningSigns)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by warning signs: ${e.message}');
    }
  }

  /// Get assessments with specific de-escalation strategies
  Future<List<ChallengingBehaviourAssessment>> getAssessmentsByDeEscalationStrategies(List<String> strategies) async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .overlaps('de_escalation_strategies', strategies)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by de-escalation strategies: ${e.message}');
    }
  }

  /// Get assessments by assessor name
  Future<List<ChallengingBehaviourAssessment>> getAssessmentsByAssessor(String assessorName) async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .eq('assessor_name', assessorName)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by assessor: ${e.message}');
    }
  }

  /// Get assessments with environmental modifications needed
  Future<List<ChallengingBehaviourAssessment>> getAssessmentsWithEnvironmentalModifications() async {
    try {
      final data = await _client
          .from('challenging_behaviour_risk_assessments')
          .select()
          .not('environmental_modifications_needed', 'is', null)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => ChallengingBehaviourAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with environmental modifications: ${e.message}');
    }
  }
}