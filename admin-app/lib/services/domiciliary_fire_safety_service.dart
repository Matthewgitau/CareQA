import 'package:supabase/supabase.dart';
import '../models/domiciliary_fire_safety_assessment.dart';

class DomiciliaryFireSafetyService {
  final SupabaseClient _supabase;

  DomiciliaryFireSafetyService(this._supabase);

  Future<DomiciliaryFireSafetyAssessment> createAssessment(DomiciliaryFireSafetyAssessment assessment) async {
    try {
      final response = await _supabase
          .from('domiciliary_fire_safety_assessments')
          .insert(assessment.toJson())
          .select()
          .single();
      return DomiciliaryFireSafetyAssessment.fromJson(response);
    } catch (error) {
      throw Exception('Failed to create fire safety assessment: $error');
    }
  }

  Future<DomiciliaryFireSafetyAssessment> updateAssessment(String id, DomiciliaryFireSafetyAssessment assessment) async {
    try {
      final response = await _supabase
          .from('domiciliary_fire_safety_assessments')
          .update(assessment.toJson())
          .eq('id', id)
          .select()
          .single();
      return DomiciliaryFireSafetyAssessment.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update fire safety assessment: $error');
    }
  }

  Future<void> deleteAssessment(String id) async {
    try {
      await _supabase.from('domiciliary_fire_safety_assessments').delete().eq('id', id);
    } catch (error) {
      throw Exception('Failed to delete fire safety assessment: $error');
    }
  }

  Future<List<DomiciliaryFireSafetyAssessment>> getAllAssessments() async {
    try {
      final response = await _supabase
          .from('domiciliary_fire_safety_assessments')
          .select()
          .order('created_at', ascending: false);
      return response.map((item) => DomiciliaryFireSafetyAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments: $error');
    }
  }

  Future<List<DomiciliaryFireSafetyAssessment>> getAssessmentsByServiceUser(String serviceUserId) async {
    try {
      final response = await _supabase
          .from('domiciliary_fire_safety_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('created_at', ascending: false);
      return response.map((item) => DomiciliaryFireSafetyAssessment.fromJson(item)).toList();
    } catch (error) {
      throw Exception('Failed to get assessments by service user: $error');
    }
  }
}