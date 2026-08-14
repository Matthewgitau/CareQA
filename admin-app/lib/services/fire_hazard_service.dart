import 'package:supabase/supabase.dart';
import '../models/fire_hazard_assessment.dart';

class FireHazardService {
  final SupabaseClient _supabase;

  FireHazardService(this._supabase);

  /// Create a new fire hazard assessment
  Future<FireHazardAssessment> createAssessment(FireHazardAssessment assessment) async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .insert(assessment.toJson())
          .select()
          .single();

      return FireHazardAssessment.fromJson(response);
    } catch (error) {
      throw Exception('Failed to create fire hazard assessment: $error');
    }
  }

  /// Get a fire hazard assessment by ID
  Future<FireHazardAssessment> getAssessment(String id) async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('id', id)
          .single();

      return FireHazardAssessment.fromJson(response);
    } catch (error) {
      throw Exception('Failed to get fire hazard assessment: $error');
    }
  }

  /// Get fire hazard assessment by service user ID
  Future<FireHazardAssessment?> getAssessmentByServiceUserId(String serviceUserId) async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        return null;
      }

      return FireHazardAssessment.fromJson(response.first);
    } catch (error) {
      throw Exception('Failed to get fire hazard assessment by service user: $error');
    }
  }

  /// Get all fire hazard assessments with optional filtering
  Future<List<FireHazardAssessment>> getAssessments({
    String? serviceUserId,
    String? riskLevel,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('fire_hazard_assessments').select();

      if (serviceUserId != null) {
        query = query.eq('service_user_id', serviceUserId);
      }

      if (riskLevel != null) {
        query = query.eq('risk_level', riskLevel);
      }

      if (startDate != null) {
        query = query.gte('assessment_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('assessment_date', endDate.toIso8601String());
      }

      final response = await query
          .order('assessment_date', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get fire hazard assessments: $error');
    }
  }

  /// Update a fire hazard assessment
  Future<FireHazardAssessment> updateAssessment(String id, FireHazardAssessment assessment) async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .update(assessment.toJson())
          .eq('id', id)
          .select()
          .single();

      return FireHazardAssessment.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update fire hazard assessment: $error');
    }
  }

  /// Delete a fire hazard assessment
  Future<void> deleteAssessment(String id) async {
    try {
      await _supabase
          .from('fire_hazard_assessments')
          .delete()
          .eq('id', id);
    } catch (error) {
      throw Exception('Failed to delete fire hazard assessment: $error');
    }
  }

  /// Get fire hazard assessments by service user ID
  Future<List<FireHazardAssessment>> getAssessmentsByServiceUser(String serviceUserId) async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments by service user: $error');
    }
  }

  /// Get all fire hazard assessments
  Future<List<FireHazardAssessment>> getAllAssessments() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get all assessments: $error');
    }
  }

  /// Get fire hazard assessments by risk level
  Future<List<FireHazardAssessment>> getAssessmentsByRiskLevel(String riskLevel) async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('risk_level', riskLevel)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get fire hazard assessments by risk level: $error');
    }
  }

  /// Get assessments with expired or soon-to-expire equipment
  Future<List<FireHazardAssessment>> getAssessmentsWithExpiredEquipment() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .or('extinguisher_service_due_soon.eq.true,blanket_service_due_soon.eq.true,alarm_test_overdue.eq.true,emergency_lighting_test_overdue.eq.true')
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with expired equipment: $error');
    }
  }

  /// Get assessments with high fire risk
  Future<List<FireHazardAssessment>> getHighRiskAssessments() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('risk_level', 'high')
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get high risk assessments: $error');
    }
  }

  /// Get assessments with training due soon
  Future<List<FireHazardAssessment>> getAssessmentsWithTrainingDue() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('training_due_soon', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with training due: $error');
    }
  }

  /// Get assessments with PAT test due soon
  Future<List<FireHazardAssessment>> getAssessmentsWithPatTestDue() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('pat_test_due_soon', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with PAT test due: $error');
    }
  }

  /// Get assessments requiring immediate attention (high risk or critical issues)
  Future<List<FireHazardAssessment>> getAssessmentsRequiringImmediateAttention() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .or('risk_level.eq.high,alarm_test_overdue.eq.true,emergency_lighting_test_overdue.eq.true,extinguisher_service_due_soon.eq.true')
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments requiring immediate attention: $error');
    }
  }

  /// Get fire hazard statistics
  Future<Map<String, dynamic>> getFireHazardStatistics() async {
    try {
      // Get total count
      final totalCount = await _supabase
          .from('fire_hazard_assessments')
          .select('count(*)');

      // Get risk level counts
      final riskLevelCounts = await _supabase.rpc('get_fire_hazard_risk_level_counts');

      // Get expired equipment counts
      final expiredEquipment = await _supabase.rpc('get_fire_hazard_expired_equipment_counts');

      // Get recent assessments count (last 30 days)
      final recentCount = await _supabase
          .from('fire_hazard_assessments')
          .select('count(*)')
          .gte('assessment_date', DateTime.now().subtract(const Duration(days: 30)).toIso8601String());

      return {
        'total_assessments': totalCount.length,
        'risk_level_counts': riskLevelCounts,
        'expired_equipment_counts': expiredEquipment,
        'recent_assessments': recentCount.length,
      };
    } catch (error) {
      throw Exception('Failed to get fire hazard statistics: $error');
    }
  }

  /// Mark fire extinguisher service as due
  Future<FireHazardAssessment> markExtinguisherServiceDue(String id, DateTime nextServiceDue) async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .update({'fire_extinguisher_next_service_due': nextServiceDue.toIso8601String()})
          .eq('id', id)
          .select()
          .single();

      return FireHazardAssessment.fromJson(response);
    } catch (error) {
      throw Exception('Failed to mark extinguisher service as due: $error');
    }
  }

  /// Mark fire blanket service as due
  Future<FireHazardAssessment> markBlanketServiceDue(String id, DateTime serviceDate) async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .update({'fire_blanket_service_date': serviceDate.toIso8601String()})
          .eq('id', id)
          .select()
          .single();

      return FireHazardAssessment.fromJson(response);
    } catch (error) {
      throw Exception('Failed to mark blanket service as due: $error');
    }
  }

  /// Mark staff training as due
  Future<FireHazardAssessment> markTrainingDue(String id, DateTime nextDueDate) async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .update({'staff_training_next_due': nextDueDate.toIso8601String()})
          .eq('id', id)
          .select()
          .single();

      return FireHazardAssessment.fromJson(response);
    } catch (error) {
      throw Exception('Failed to mark training as due: $error');
    }
  }

  /// Mark PAT test as due
  Future<FireHazardAssessment> markPatTestDue(String id, DateTime expiryDate) async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .update({'pat_test_expiry_date': expiryDate.toIso8601String()})
          .eq('id', id)
          .select()
          .single();

      return FireHazardAssessment.fromJson(response);
    } catch (error) {
      throw Exception('Failed to mark PAT test as due: $error');
    }
  }

  /// Update fire alarm test date
  Future<FireHazardAssessment> updateFireAlarmTest(String id, DateTime testDate) async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .update({
            'fire_alarm_test_date': testDate.toIso8601String(),
            'fire_alarm_weekly_test_recorded': true
          })
          .eq('id', id)
          .select()
          .single();

      return FireHazardAssessment.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update fire alarm test: $error');
    }
  }

  /// Update emergency lighting test date
  Future<FireHazardAssessment> updateEmergencyLightingTest(String id, DateTime testDate) async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .update({'emergency_lighting_test_date': testDate.toIso8601String()})
          .eq('id', id)
          .select()
          .single();

      return FireHazardAssessment.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update emergency lighting test: $error');
    }
  }

  /// Update action plan
  Future<FireHazardAssessment> updateActionPlan(
    String id, {
    List<Map<String, dynamic>>? actionItems,
    String? responsiblePerson,
    DateTime? completionDeadline,
    DateTime? reviewDate,
  }) async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .update({
            'action_items': actionItems ?? [],
            'responsible_person': responsiblePerson,
            'completion_deadline': completionDeadline?.toIso8601String(),
            'review_date': reviewDate?.toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return FireHazardAssessment.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update action plan: $error');
    }
  }

  /// Get assessments due for review (older than 1 year)
  Future<List<FireHazardAssessment>> getAssessmentsDueForReview() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .lt('assessment_date', DateTime.now().subtract(const Duration(days: 365)).toIso8601String())
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments due for review: $error');
    }
  }

  /// Get recent assessments (last 90 days)
  Future<List<FireHazardAssessment>> getRecentAssessments({int limit = 50}) async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .gte('assessment_date', DateTime.now().subtract(const Duration(days: 90)).toIso8601String())
          .order('assessment_date', ascending: false)
          .limit(limit);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get recent assessments: $error');
    }
  }

  /// Search assessments by assessor name
  Future<List<FireHazardAssessment>> searchAssessmentsByAssessor(String assessorName) async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .ilike('assessor_name', '%$assessorName%')
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to search assessments by assessor: $error');
    }
  }

  /// Get assessments by fire warden
  Future<List<FireHazardAssessment>> getAssessmentsByFireWarden(String fireWardenName) async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .ilike('fire_warden_name', '%$fireWardenName%')
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments by fire warden: $error');
    }
  }

  /// Get assessments with specific fire extinguisher types
  Future<List<FireHazardAssessment>> getAssessmentsByExtinguisherTypes(List<String> types) async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .contains('fire_extinguisher_types', types.join(','))
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments by extinguisher types: $error');
    }
  }

  /// Get assessments with specific fire drill frequency
  Future<List<FireHazardAssessment>> getAssessmentsByDrillFrequency(String frequency) async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('fire_drill_frequency', frequency)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments by drill frequency: $error');
    }
  }

  /// Get assessments with PEEPs in place
  Future<List<FireHazardAssessment>> getAssessmentsWithPeepsInPlace() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('peeps_in_place_for_all_service_users', 'yes')
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with PEEPs in place: $error');
    }
  }

  /// Get assessments with evacuation plan displayed
  Future<List<FireHazardAssessment>> getAssessmentsWithEvacuationPlanDisplayed() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('evacuation_plan_displayed', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with evacuation plan displayed: $error');
    }
  }

  /// Get assessments with fire log book maintained
  Future<List<FireHazardAssessment>> getAssessmentsWithFireLogBookMaintained() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('fire_log_book_maintained', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with fire log book maintained: $error');
    }
  }

  /// Get assessments with weekly checks recorded
  Future<List<FireHazardAssessment>> getAssessmentsWithWeeklyChecksRecorded() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('weekly_checks_recorded', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with weekly checks recorded: $error');
    }
  }

  /// Get assessments with monthly checks recorded
  Future<List<FireHazardAssessment>> getAssessmentsWithMonthlyChecksRecorded() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('monthly_checks_recorded', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with monthly checks recorded: $error');
    }
  }

  /// Get assessments with kitchen extractor hood cleaned
  Future<List<FireHazardAssessment>> getAssessmentsWithCleanExtractorHood() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('kitchen_extractor_hood_cleaned', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with clean extractor hood: $error');
    }
  }

  /// Get assessments with laundry dryer lint filter cleaned
  Future<List<FireHazardAssessment>> getAssessmentsWithCleanLintFilter() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('laundry_dryer_lint_filter_cleaned', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with clean lint filter: $error');
    }
  }

  /// Get assessments with electrical equipment not overloaded
  Future<List<FireHazardAssessment>> getAssessmentsWithProperElectricalLoad() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('electrical_equipment_not_overloaded', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with proper electrical load: $error');
    }
  }

  /// Get assessments with charging devices on non-flammable surface
  Future<List<FireHazardAssessment>> getAssessmentsWithSafeCharging() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('charging_devices_on_non_flammable_surface', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with safe charging: $error');
    }
  }

  /// Get assessments with external waste bins away from building
  Future<List<FireHazardAssessment>> getAssessmentsWithProperWasteStorage() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('external_waste_bins_away_from_building', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with proper waste storage: $error');
    }
  }

  /// Get assessments with locked bin stores
  Future<List<FireHazardAssessment>> getAssessmentsWithLockedBinStores() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('bin_stores_locked', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with locked bin stores: $error');
    }
  }

  /// Get assessments with working external lighting
  Future<List<FireHazardAssessment>> getAssessmentsWithWorkingExternalLighting() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('external_lighting_working', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with working external lighting: $error');
    }
  }

  /// Get assessments with working intruder alarm
  Future<List<FireHazardAssessment>> getAssessmentsWithWorkingIntruderAlarm() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('intruder_alarm_working', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with working intruder alarm: $error');
    }
  }

  /// Get assessments with fire doors self-closing
  Future<List<FireHazardAssessment>> getAssessmentsWithSelfClosingFireDoors() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('fire_doors_self_closing', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with self-closing fire doors: $error');
    }
  }

  /// Get assessments with fire door gaps less than 4mm
  Future<List<FireHazardAssessment>> getAssessmentsWithProperFireDoorGaps() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('fire_door_gaps_less_than_4mm', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with proper fire door gaps: $error');
    }
  }

  /// Get assessments with intact fire door seals
  Future<List<FireHazardAssessment>> getAssessmentsWithIntactFireDoorSeals() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('fire_door_seals_intact', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with intact fire door seals: $error');
    }
  }

  /// Get assessments with intact compartment walls
  Future<List<FireHazardAssessment>> getAssessmentsWithIntactCompartmentWalls() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('compartment_walls_intact', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with intact compartment walls: $error');
    }
  }

  /// Get assessments with sealed ceiling/floor penetrations
  Future<List<FireHazardAssessment>> getAssessmentsWithSealedPenetrations() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('ceiling_floor_penetrations_sealed', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with sealed penetrations: $error');
    }
  }

  /// Get assessments with clearly marked emergency exits
  Future<List<FireHazardAssessment>> getAssessmentsWithMarkedEmergencyExits() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('emergency_exits_clearly_marked', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with marked emergency exits: $error');
    }
  }

  /// Get assessments with easily opened exit doors
  Future<List<FireHazardAssessment>> getAssessmentsWithEasyExitDoors() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('exit_doors_open_easily', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with easy exit doors: $error');
    }
  }

  /// Get assessments with unobstructed exit routes
  Future<List<FireHazardAssessment>> getAssessmentsWithUnobstructedExits() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('exit_routes_unobstructed', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with unobstructed exits: $error');
    }
  }

  /// Get assessments with working emergency lighting
  Future<List<FireHazardAssessment>> getAssessmentsWithWorkingEmergencyLighting() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('emergency_lighting_working', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with working emergency lighting: $error');
    }
  }

  /// Get assessments with illuminated fire exit signs
  Future<List<FireHazardAssessment>> getAssessmentsWithIlluminatedExitSigns() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('fire_exit_signs_illuminated', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with illuminated exit signs: $error');
    }
  }

  /// Get assessments with outward opening final exits
  Future<List<FireHazardAssessment>> getAssessmentsWithOutwardOpeningExits() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('final_exits_open_outward', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with outward opening exits: $error');
    }
  }

  /// Get assessments with mobility aid suitable escape routes
  Future<List<FireHazardAssessment>> getAssessmentsWithMobilityAidRoutes() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('escape_routes_suitable_for_mobility_aids', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with mobility aid routes: $error');
    }
  }

  /// Get assessments with reviewed PEEPs
  Future<List<FireHazardAssessment>> getAssessmentsWithReviewedPeeps() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('peeps_reviewed_annually', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with reviewed PEEPs: $error');
    }
  }

  /// Get assessments with rehearsed evacuation plans
  Future<List<FireHazardAssessment>> getAssessmentsWithRehearsedEvacuationPlans() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('evacuation_plan_rehearsed', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with rehearsed evacuation plans: $error');
    }
  }

  /// Get assessments with signed in/out visitors
  Future<List<FireHazardAssessment>> getAssessmentsWithVisitorSignInOut() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('visitors_signed_in_out', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with visitor sign in/out: $error');
    }
  }

  /// Get assessments with adequate night staff numbers
  Future<List<FireHazardAssessment>> getAssessmentsWithAdequateNightStaff() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('night_staff_numbers_adequate', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with adequate night staff: $error');
    }
  }

  /// Get assessments with identified disabled refuge points
  Future<List<FireHazardAssessment>> getAssessmentsWithDisabledRefugePoints() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('disabled_refuge_points_identified', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with disabled refuge points: $error');
    }
  }

  /// Get assessments with completed staff fire training
  Future<List<FireHazardAssessment>> getAssessmentsWithCompletedStaffTraining() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('staff_fire_training_completed', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with completed staff training: $error');
    }
  }

  /// Get assessments with conducted fire drills
  Future<List<FireHazardAssessment>> getAssessmentsWithConductedFireDrills() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('fire_drill_conducted', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with conducted fire drills: $error');
    }
  }

  /// Get assessments with appointed fire warden
  Future<List<FireHazardAssessment>> getAssessmentsWithFireWarden() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('fire_warden_appointed', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with fire warden: $error');
    }
  }

  /// Get assessments with documented fire extinguisher locations
  Future<List<FireHazardAssessment>> getAssessmentsWithDocumentedExtinguisherLocations() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('fire_extinguisher_locations_documented', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with documented extinguisher locations: $error');
    }
  }

  /// Get assessments with monthly equipment inspection
  Future<List<FireHazardAssessment>> getAssessmentsWithMonthlyEquipmentInspection() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('equipment_inspected_monthly', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with monthly equipment inspection: $error');
    }
  }

  /// Get assessments with heat detectors in kitchens
  Future<List<FireHazardAssessment>> getAssessmentsWithHeatDetectorsInKitchens() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('heat_detectors_in_kitchens', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with heat detectors in kitchens: $error');
    }
  }

  /// Get assessments with fire blanket in kitchen
  Future<List<FireHazardAssessment>> getAssessmentsWithFireBlanketInKitchen() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('fire_blanket_in_kitchen', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with fire blanket in kitchen: $error');
    }
  }

  /// Get assessments with fire hose reel
  Future<List<FireHazardAssessment>> getAssessmentsWithFireHoseReel() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('fire_hose_reel_present', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with fire hose reel: $error');
    }
  }

  /// Get assessments with cooker isolator switch accessible
  Future<List<FireHazardAssessment>> getAssessmentsWithAccessibleCookerIsolator() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('cooker_isolator_switch_accessible', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with accessible cooker isolator: $error');
    }
  }

  /// Get assessments with PAT testing up to date
  Future<List<FireHazardAssessment>> getAssessmentsWithUpToDatePatTesting() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('pat_testing_up_to_date', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with up to date PAT testing: $error');
    }
  }

  /// Get assessments with reviewed fire risk assessment
  Future<List<FireHazardAssessment>> getAssessmentsWithReviewedFireRiskAssessment() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .not('fire_risk_assessment_review_date', 'is', null)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with reviewed fire risk assessment: $error');
    }
  }

  /// Get assessments with staff knowing PEEPs for assigned service users
  Future<List<FireHazardAssessment>> getAssessmentsWithStaffKnowingPeeps() async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('staff_know_peeps_for_assigned_service_users', true)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with staff knowing PEEPs: $error');
    }
  }

  /// Get assessments with fire alarm system type
  Future<List<FireHazardAssessment>> getAssessmentsByAlarmSystemType(String systemType) async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('fire_alarm_system_type', systemType)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments by alarm system type: $error');
    }
  }

  /// Get assessments with smoke detectors present
  Future<List<FireHazardAssessment>> getAssessmentsWithSmokeDetectors(String presence) async {
    try {
      final response = await _supabase
          .from('fire_hazard_assessments')
          .select()
          .eq('smoke_detectors_present', presence)
          .order('assessment_date', ascending: false);

      return response.map((item) => FireHazardAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments with smoke detectors: $error');
    }
  }
}
