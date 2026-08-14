import 'package:supabase/supabase.dart';
import 'package:admin_app/models/equipment_register_assessment.dart';

class EquipmentRegisterService {
  final SupabaseClient _supabase;

  EquipmentRegisterService(this._supabase);

  // Create a new equipment register assessment
  Future<EquipmentRegisterAssessment> createAssessment(EquipmentRegisterAssessment assessment) async {
    try {
      final response = await _supabase
          .from('equipment_register_risk_assessments')
          .insert(assessment.toJson())
          .select()
          .single();

      return EquipmentRegisterAssessment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create equipment register assessment: $e');
    }
  }

  // Get a specific equipment register assessment by ID
  Future<EquipmentRegisterAssessment> getAssessment(String id) async {
    try {
      final response = await _supabase
          .from('equipment_register_risk_assessments')
          .select()
          .eq('id', id)
          .single();

      return EquipmentRegisterAssessment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get equipment register assessment: $e');
    }
  }

  // Get equipment register assessment by equipment ID
  Future<EquipmentRegisterAssessment> getAssessmentByEquipmentId(String equipmentId) async {
    try {
      final response = await _supabase
          .from('equipment_register_risk_assessments')
          .select()
          .eq('equipment_id', equipmentId)
          .single();

      return EquipmentRegisterAssessment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get equipment register assessment by equipment ID: $e');
    }
  }

  // Get all equipment register assessments
  Future<List<EquipmentRegisterAssessment>> getAssessments({
    String? equipmentCategory,
    String? equipmentCondition,
    String? reportedFaults,
    String? riskLevel,
    bool? lolerExpired,
    bool? patExpired,
    bool? serviceDue,
    bool? reviewDue,
    bool? isSafeForUse,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase.from('equipment_register_risk_assessments').select();

      if (equipmentCategory != null) {
        query = query.eq('equipment_category', equipmentCategory);
      }

      if (equipmentCondition != null) {
        query = query.eq('equipment_condition', equipmentCondition);
      }

      if (reportedFaults != null) {
        query = query.eq('reported_faults', reportedFaults);
      }

      if (riskLevel != null) {
        query = query.eq('risk_level', riskLevel);
      }

      if (lolerExpired != null) {
        query = query.eq('loler_expired', lolerExpired);
      }

      if (patExpired != null) {
        query = query.eq('pat_expired', patExpired);
      }

      if (serviceDue != null) {
        query = query.eq('service_due', serviceDue);
      }

      if (reviewDue != null) {
        query = query.eq('review_due', reviewDue);
      }

      if (isSafeForUse != null) {
        query = query.eq('is_safe_for_use', isSafeForUse);
      }

      if (startDate != null && endDate != null) {
        query = query.gte('created_at', startDate.toIso8601String())
                   .lte('created_at', endDate.toIso8601String());
      }

      final response = await query.order('equipment_name', ascending: true);

      return response.map((item) => EquipmentRegisterAssessment.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get equipment register assessments: $e');
    }
  }

  // Update an equipment register assessment
  Future<EquipmentRegisterAssessment> updateAssessment(String id, EquipmentRegisterAssessment assessment) async {
    try {
      final response = await _supabase
          .from('equipment_register_risk_assessments')
          .update(assessment.toJson())
          .eq('id', id)
          .select()
          .single();

      return EquipmentRegisterAssessment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update equipment register assessment: $e');
    }
  }

  // Delete an equipment register assessment
  Future<void> deleteAssessment(String id) async {
    try {
      await _supabase
          .from('equipment_register_risk_assessments')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete equipment register assessment: $e');
    }
  }

  // Get equipment by category
  Future<List<EquipmentRegisterAssessment>> getEquipmentByCategory(String category) async {
    try {
      final response = await _supabase
          .from('equipment_register_risk_assessments')
          .select()
          .eq('equipment_category', category)
          .order('equipment_name', ascending: true);

      return response.map((item) => EquipmentRegisterAssessment.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get equipment by category: $e');
    }
  }

  // Get equipment with expired tests
  Future<List<EquipmentRegisterAssessment>> getEquipmentWithExpiredTests() async {
    try {
      final response = await _supabase
          .from('equipment_status_dashboard')
          .select()
          .or([
            'loler_expired.eq.true',
            'pat_expired.eq.true'
          ])
          .order('equipment_name', ascending: true);

      return response.map((item) => EquipmentRegisterAssessment.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get equipment with expired tests: $e');
    }
  }

  // Get equipment with service due
  Future<List<EquipmentRegisterAssessment>> getEquipmentWithServiceDue() async {
    try {
      final response = await _supabase
          .from('equipment_status_dashboard')
          .select()
          .eq('service_due', true)
          .order('next_service_due_date', ascending: true);

      return response.map((item) => EquipmentRegisterAssessment.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get equipment with service due: $e');
    }
  }

  // Get equipment with high/critical risk
  Future<List<EquipmentRegisterAssessment>> getHighRiskEquipment() async {
    try {
      final response = await _supabase
          .from('equipment_register_risk_assessments')
          .select()
          .or([
            'risk_level.eq.critical',
            'risk_level.eq.high'
          ])
          .order('risk_level', ascending: false)
          .order('equipment_name', ascending: true);

      return response.map((item) => EquipmentRegisterAssessment.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get high risk equipment: $e');
    }
  }

  // Get unsafe equipment
  Future<List<EquipmentRegisterAssessment>> getUnsafeEquipment() async {
    try {
      final response = await _supabase
          .from('equipment_status_dashboard')
          .select()
          .eq('is_safe_for_use', false)
          .order('equipment_name', ascending: true);

      return response.map((item) => EquipmentRegisterAssessment.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get unsafe equipment: $e');
    }
  }

  // Get equipment with reported faults
  Future<List<EquipmentRegisterAssessment>> getEquipmentWithFaults() async {
    try {
      final response = await _supabase
          .from('equipment_register_risk_assessments')
          .select()
          .neq('reported_faults', 'none')
          .order('fault_reported_date', ascending: false);

      return response.map((item) => EquipmentRegisterAssessment.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get equipment with faults: $e');
    }
  }

  // Get equipment requiring training
  Future<List<EquipmentRegisterAssessment>> getEquipmentRequiringTraining() async {
    try {
      final response = await _supabase
          .from('equipment_register_risk_assessments')
          .select()
          .or([
            'staff_trained.eq.false',
            'training_record_available.eq.false'
          ])
          .order('equipment_name', ascending: true);

      return response.map((item) => EquipmentRegisterAssessment.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get equipment requiring training: $e');
    }
  }

  // Get equipment statistics
  Future<Map<String, dynamic>> getEquipmentStatistics() async {
    try {
      // Get total count
      final totalCount = await _supabase
          .from('equipment_register_risk_assessments')
          .select('count(*)')
          .single();

      // Get counts by category
      final categoryCounts = await _supabase
          .from('equipment_register_risk_assessments')
          .select('equipment_category, count(*)')
          .group('equipment_category');

      // Get counts by condition
      final conditionCounts = await _supabase
          .from('equipment_register_risk_assessments')
          .select('equipment_condition, count(*)')
          .group('equipment_condition');

      // Get counts by risk level
      final riskCounts = await _supabase
          .from('equipment_register_risk_assessments')
          .select('risk_level, count(*)')
          .group('risk_level');

      // Get counts by safety status
      final safetyCounts = await _supabase
          .from('equipment_status_dashboard')
          .select('is_safe_for_use, count(*)')
          .group('is_safe_for_use');

      // Get counts by test status
      final testCounts = await _supabase
          .from('equipment_status_dashboard')
          .select('loler_expired, pat_expired, count(*)')
          .group('loler_expired, pat_expired');

      return {
        'total_count': totalCount['count'],
        'category_counts': categoryCounts,
        'condition_counts': conditionCounts,
        'risk_counts': riskCounts,
        'safety_counts': safetyCounts,
        'test_counts': testCounts,
      };
    } catch (e) {
      throw Exception('Failed to get equipment statistics: $e');
    }
  }

  // Get equipment requiring immediate attention
  Future<List<EquipmentRegisterAssessment>> getEquipmentRequiringImmediateAttention() async {
    try {
      final response = await _supabase
          .from('equipment_status_dashboard')
          .select()
          .or([
            'loler_expired.eq.true',
            'pat_expired.eq.true',
            'is_safe_for_use.eq.false',
            'reported_faults.eq.major',
            'service_due.eq.true'
          ])
          .order('equipment_name', ascending: true);

      return response.map((item) => EquipmentRegisterAssessment.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get equipment requiring immediate attention: $e');
    }
  }

  // Mark equipment as unsafe
  Future<void> markEquipmentUnsafe(String id) async {
    try {
      await _supabase
          .from('equipment_register_risk_assessments')
          .update({
            'equipment_condition': 'unsafe',
            'risk_level': 'critical',
            'action_required': 'Equipment unsafe - Remove from service immediately'
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to mark equipment as unsafe: $e');
    }
  }

  // Mark equipment as safe
  Future<void> markEquipmentSafe(String id) async {
    try {
      await _supabase
          .from('equipment_register_risk_assessments')
          .update({
            'equipment_condition': 'good',
            'reported_faults': 'none',
            'risk_level': 'low',
            'action_required': null
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to mark equipment as safe: $e');
    }
  }

  // Update service dates
  Future<void> updateServiceDates(String id, DateTime lastServiceDate, DateTime nextServiceDueDate) async {
    try {
      await _supabase
          .from('equipment_register_risk_assessments')
          .update({
            'last_service_date': lastServiceDate.toIso8601String(),
            'next_service_due_date': nextServiceDueDate.toIso8601String(),
            'service_due': false
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to update service dates: $e');
    }
  }

  // Update test dates
  Future<void> updateTestDates({
    String? id,
    DateTime? patTestDate,
    DateTime? patTestExpiry,
    DateTime? lolerTestDate,
    DateTime? lolerTestExpiry,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (patTestDate != null) {
        updateData['pat_test_date'] = patTestDate.toIso8601String();
      }
      
      if (patTestExpiry != null) {
        updateData['pat_test_expiry'] = patTestExpiry.toIso8601String();
      }
      
      if (lolerTestDate != null) {
        updateData['loler_test_date'] = lolerTestDate.toIso8601String();
      }
      
      if (lolerTestExpiry != null) {
        updateData['loler_test_expiry'] = lolerTestExpiry.toIso8601String();
      }

      if (id != null) {
        await _supabase
            .from('equipment_register_risk_assessments')
            .update(updateData)
            .eq('id', id);
      }
    } catch (e) {
      throw Exception('Failed to update test dates: $e');
    }
  }

  // Report fault
  Future<void> reportFault(String id, String faultType, String? actionRequired) async {
    try {
      await _supabase
          .from('equipment_register_risk_assessments')
          .update({
            'reported_faults': faultType,
            'fault_reported_date': DateTime.now().toIso8601String(),
            'action_required': actionRequired,
            'risk_level': faultType == 'major' ? 'critical' : 'medium'
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to report fault: $e');
    }
  }

  // Resolve fault
  Future<void> resolveFault(String id) async {
    try {
      await _supabase
          .from('equipment_register_risk_assessments')
          .update({
            'reported_faults': 'none',
            'fault_resolved_date': DateTime.now().toIso8601String(),
            'action_required': null,
            'risk_level': 'low'
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to resolve fault: $e');
    }
  }

  // Mark staff as trained
  Future<void> markStaffTrained(String id, bool trainingRecordAvailable) async {
    try {
      await _supabase
          .from('equipment_register_risk_assessments')
          .update({
            'staff_trained': true,
            'training_record_available': trainingRecordAvailable,
            'risk_level': 'low'
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to mark staff as trained: $e');
    }
  }

  // Get equipment due for review
  Future<List<EquipmentRegisterAssessment>> getEquipmentDueForReview() async {
    try {
      final response = await _supabase
          .from('equipment_status_dashboard')
          .select()
          .eq('review_due', true)
          .order('review_date', ascending: true);

      return response.map((item) => EquipmentRegisterAssessment.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get equipment due for review: $e');
    }
  }

  // Update review date
  Future<void> updateReviewDate(String id, DateTime reviewDate) async {
    try {
      await _supabase
          .from('equipment_register_risk_assessments')
          .update({
            'review_date': reviewDate.toIso8601String(),
            'review_due': false
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to update review date: $e');
    }
  }

  // Get recent equipment assessments
  Future<List<EquipmentRegisterAssessment>> getRecentAssessments({
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from('equipment_register_risk_assessments')
          .select()
          .order('updated_at', ascending: false)
          .limit(limit);

      return response.map((item) => EquipmentRegisterAssessment.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get recent equipment assessments: $e');
    }
  }

  // Search equipment by name or ID
  Future<List<EquipmentRegisterAssessment>> searchEquipment(String searchTerm) async {
    try {
      final response = await _supabase
          .from('equipment_register_risk_assessments')
          .select()
          .or([
            'equipment_name.ilike.%${searchTerm}%',
            'equipment_id.ilike.%${searchTerm}%',
            'serial_number.ilike.%${searchTerm}%'
          ])
          .order('equipment_name', ascending: true);

      return response.map((item) => EquipmentRegisterAssessment.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to search equipment: $e');
    }
  }
}