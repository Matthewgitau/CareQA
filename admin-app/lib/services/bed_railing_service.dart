import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/bed_railing_assessment.dart';

class BedRailingService {
  final SupabaseClient _client;

  BedRailingService(this._client);

  /// Create a new bed railing risk assessment
  Future<BedRailingAssessment> createAssessment(BedRailingAssessment assessment) async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .insert(assessment.toMap())
          .select()
          .single();

      return BedRailingAssessment.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create assessment: ${e.message}');
    }
  }

  /// Get assessment by ID
  Future<BedRailingAssessment> getAssessment(String id) async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .select()
          .eq('id', id)
          .single();

      return BedRailingAssessment.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessment: ${e.message}');
    }
  }

  /// Get all assessments for a service user
  Future<List<BedRailingAssessment>> getAssessments({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
    String? bedType,
    String? bedRailsType,
    String? riskLevel,
    bool? highRiskOnly,
    bool? dueForCheck,
    bool? lolCompliant,
  }) async {
    var query = _client.from('bed_railing_risk_assessments').select();

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

    if (bedType != null) {
      query = query.eq('bed_type', bedType);
    }

    if (bedRailsType != null) {
      query = query.eq('bed_rails_type', bedRailsType);
    }

    if (riskLevel != null) {
      query = query.or('risk_of_falling_out_of_bed.eq.$riskLevel.or.risk_of_entrapment.eq.$riskLevel');
    }

    if (highRiskOnly == true) {
      query = query.or('risk_of_falling_out_of_bed.eq.high.or.risk_of_entrapment.eq.high');
    }

    if (dueForCheck == true) {
      query = query.lt('next_check_date', DateTime.now().toUtc());
    }

    if (lolCompliant != null) {
      if (lolCompliant) {
        query = query.eq('manufacturer_instructions_available', true)
            .eq('rail_condition', 'good')
            .eq('rail_height_and_fit', 'correct')
            .eq('entrapment_risk_assessed', true)
            .eq('staff_trained_in_bed_rail_use', true)
            .eq('rail_regularly_checked', true);
      } else {
        query = query.or('manufacturer_instructions_available.eq.false.or.rail_condition.eq.damaged.or.rail_height_and_fit.eq.incorrect.or.entrapment_risk_assessed.eq.false.or.staff_trained_in_bed_rail_use.eq.false.or.rail_regularly_checked.eq.false');
      }
    }

    try {
      final data = await query.order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => BedRailingAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments: ${e.message}');
    }
  }

  /// Update an existing assessment
  Future<BedRailingAssessment> updateAssessment(String id, BedRailingAssessment assessment) async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .update(assessment.toMap())
          .eq('id', id)
          .select()
          .single();

      return BedRailingAssessment.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update assessment: ${e.message}');
    }
  }

  /// Delete an assessment
  Future<void> deleteAssessment(String id) async {
    try {
      await _client
          .from('bed_railing_risk_assessments')
          .delete()
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete assessment: ${e.message}');
    }
  }

  /// Get assessments that need review (review date passed)
  Future<List<BedRailingAssessment>> getAssessmentsNeedingReview() async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .select()
          .not('review_date', 'is', null)
          .lt('review_date', DateTime.now().toUtc())
          .order('review_date', ascending: true);

      return (data as List)
          .map((item) => BedRailingAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments needing review: ${e.message}');
    }
  }

  /// Get assessments that need bed rail checks (next check date passed)
  Future<List<BedRailingAssessment>> getAssessmentsNeedingChecks() async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .select()
          .not('next_check_date', 'is', null)
          .lt('next_check_date', DateTime.now().toUtc())
          .order('next_check_date', ascending: true);

      return (data as List)
          .map((item) => BedRailingAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments needing checks: ${e.message}');
    }
  }

  /// Get high-risk assessments
  Future<List<BedRailingAssessment>> getHighRiskAssessments() async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .select()
          .or('risk_of_falling_out_of_bed.eq.high.or.risk_of_entrapment.eq.high')
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => BedRailingAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get high-risk assessments: ${e.message}');
    }
  }

  /// Get LOLER non-compliant assessments
  Future<List<BedRailingAssessment>> getLOLERNonCompliantAssessments() async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .select()
          .or('manufacturer_instructions_available.eq.false.or.rail_condition.eq.damaged.or.rail_height_and_fit.eq.incorrect.or.entrapment_risk_assessed.eq.false.or.staff_trained_in_bed_rail_use.eq.false.or.rail_regularly_checked.eq.false')
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => BedRailingAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get LOLER non-compliant assessments: ${e.message}');
    }
  }

  /// Get assessments by bed type
  Future<List<BedRailingAssessment>> getAssessmentsByBedType(String bedType) async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .select()
          .eq('bed_type', bedType)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => BedRailingAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by bed type: ${e.message}');
    }
  }

  /// Get assessments by bed rails type
  Future<List<BedRailingAssessment>> getAssessmentsByBedRailsType(String bedRailsType) async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .select()
          .eq('bed_rails_type', bedRailsType)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => BedRailingAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by bed rails type: ${e.message}');
    }
  }

  /// Get assessments by rail condition
  Future<List<BedRailingAssessment>> getAssessmentsByRailCondition(String railCondition) async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .select()
          .eq('rail_condition', railCondition)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => BedRailingAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by rail condition: ${e.message}');
    }
  }

  /// Get assessments by patient mobility
  Future<List<BedRailingAssessment>> getAssessmentsByPatientMobility(String patientMobility) async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .select()
          .eq('patient_mobility', patientMobility)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => BedRailingAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by patient mobility: ${e.message}');
    }
  }

  /// Get assessments with cognitive impairment
  Future<List<BedRailingAssessment>> getAssessmentsWithCognitiveImpairment() async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .select()
          .eq('cognitive_impairment', true)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => BedRailingAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with cognitive impairment: ${e.message}');
    }
  }

  /// Get assessments with agitation/restlessness
  Future<List<BedRailingAssessment>> getAssessmentsWithAgitation() async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .select()
          .eq('agitation_restlessness', true)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => BedRailingAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with agitation: ${e.message}');
    }
  }

  /// Get assessments with manufacturer instructions available
  Future<List<BedRailingAssessment>> getAssessmentsWithManufacturerInstructions() async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .select()
          .eq('manufacturer_instructions_available', true)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => BedRailingAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with manufacturer instructions: ${e.message}');
    }
  }

  /// Get assessments with entrapment risk assessed
  Future<List<BedRailingAssessment>> getAssessmentsWithEntrapmentRiskAssessed() async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .select()
          .eq('entrapment_risk_assessed', true)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => BedRailingAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with entrapment risk assessed: ${e.message}');
    }
  }

  /// Get assessments with staff trained in bed rail use
  Future<List<BedRailingAssessment>> getAssessmentsWithTrainedStaff() async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .select()
          .eq('staff_trained_in_bed_rail_use', true)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => BedRailingAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with trained staff: ${e.message}');
    }
  }

  /// Get assessments with regular rail checks
  Future<List<BedRailingAssessment>> getAssessmentsWithRegularChecks() async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .select()
          .eq('rail_regularly_checked', true)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => BedRailingAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with regular checks: ${e.message}');
    }
  }

  /// Get assessments with alternative measures considered
  Future<List<BedRailingAssessment>> getAssessmentsWithAlternativeMeasures() async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .select()
          .eq('alternative_measures_considered', true)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => BedRailingAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with alternative measures: ${e.message}');
    }
  }

  /// Get assessments with family consent obtained
  Future<List<BedRailingAssessment>> getAssessmentsWithFamilyConsent() async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .select()
          .eq('family_consent_obtained', true)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => BedRailingAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with family consent: ${e.message}');
    }
  }

  /// Get statistics for bed railing assessments
  Future<Map<String, dynamic>> getStatistics({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client.from('bed_railing_risk_assessments').select('''
      count(*),
      bed_type,
      bed_rails_type,
      rail_condition,
      patient_mobility,
      risk_of_falling_out_of_bed,
      risk_of_entrapment,
      cognitive_impairment,
      agitation_restlessness,
      manufacturer_instructions_available,
      entrapment_risk_assessed,
      staff_trained_in_bed_rail_use,
      rail_regularly_checked,
      alternative_measures_considered,
      family_consent_obtained
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

  /// Get LOLER compliance statistics
  Future<Map<String, dynamic>> getLOLERComplianceStatistics({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client.from('bed_railing_risk_assessments').select('''
      count(*),
      count(*) FILTER (WHERE manufacturer_instructions_available = true) as with_instructions,
      count(*) FILTER (WHERE rail_condition = 'good') as good_condition,
      count(*) FILTER (WHERE rail_height_and_fit = 'correct') as correct_fit,
      count(*) FILTER (WHERE entrapment_risk_assessed = true) as risk_assessed,
      count(*) FILTER (WHERE staff_trained_in_bed_rail_use = true) as staff_trained,
      count(*) FILTER (WHERE rail_regularly_checked = true) as regularly_checked,
      count(*) FILTER (
        WHERE manufacturer_instructions_available = true 
        AND rail_condition = 'good' 
        AND rail_height_and_fit = 'correct'
        AND entrapment_risk_assessed = true
        AND staff_trained_in_bed_rail_use = true
        AND rail_regularly_checked = true
      ) as lol_compliant
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
      throw Exception('Failed to get LOLER compliance statistics: ${e.message}');
    }
  }

  /// Get risk level statistics
  Future<Map<String, dynamic>> getRiskLevelStatistics({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client.from('bed_railing_risk_assessments').select('''
      count(*) FILTER (WHERE risk_of_falling_out_of_bed = 'high' OR risk_of_entrapment = 'high') as high_risk,
      count(*) FILTER (WHERE risk_of_falling_out_of_bed = 'medium' OR risk_of_entrapment = 'medium') as medium_risk,
      count(*) FILTER (WHERE risk_of_falling_out_of_bed = 'low' AND risk_of_entrapment = 'low') as low_risk,
      count(*) FILTER (WHERE risk_of_falling_out_of_bed = 'high') as high_fall_risk,
      count(*) FILTER (WHERE risk_of_entrapment = 'high') as high_entrapment_risk,
      count(*) FILTER (WHERE risk_of_falling_out_of_bed = 'medium') as medium_fall_risk,
      count(*) FILTER (WHERE risk_of_entrapment = 'medium') as medium_entrapment_risk,
      count(*) FILTER (WHERE risk_of_falling_out_of_bed = 'low') as low_fall_risk,
      count(*) FILTER (WHERE risk_of_entrapment = 'low') as low_entrapment_risk
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
      throw Exception('Failed to get risk level statistics: ${e.message}');
    }
  }

  /// Get recent assessments (last 30 days)
  Future<List<BedRailingAssessment>> getRecentAssessments({
    String? serviceUserId,
    int days = 30,
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: days));

    return getAssessments(
      serviceUserId: serviceUserId,
      startDate: startDate,
    );
  }

  /// Get assessments by assessor name
  Future<List<BedRailingAssessment>> getAssessmentsByAssessor(String assessorName) async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .select()
          .eq('assessor_name', assessorName)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => BedRailingAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments by assessor: ${e.message}');
    }
  }

  /// Get assessments with action plans
  Future<List<BedRailingAssessment>> getAssessmentsWithActionPlans() async {
    try {
      final data = await _client
          .from('bed_railing_risk_assessments')
          .select()
          .not('action_plan', 'is', null)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => BedRailingAssessment.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get assessments with action plans: ${e.message}');
    }
  }
}