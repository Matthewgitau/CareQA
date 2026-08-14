import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/environmental_assessment.dart';

class EnvironmentalService {
  final SupabaseClient _client;

  EnvironmentalService(this._client);

  Future<List<EnvironmentalAssessment>> getAssessments({String? serviceUserId}) async {
    try {
      var query = _client.from('environmental_risk_assessments').select();
      
      if (serviceUserId != null) {
        query = query.eq('service_user_id', serviceUserId);
      }

      final data = await query.order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => EnvironmentalAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<EnvironmentalAssessment> getAssessment(String id) async {
    try {
      final data = await _client
          .from('environmental_risk_assessments')
          .select()
          .eq('id', id)
          .single();

      return EnvironmentalAssessment.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<EnvironmentalAssessment> createAssessment(EnvironmentalAssessment assessment) async {
    try {
      final data = await _client
          .from('environmental_risk_assessments')
          .insert(assessment.toMap())
          .select()
          .single();

      return EnvironmentalAssessment.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<EnvironmentalAssessment> updateAssessment(String id, EnvironmentalAssessment assessment) async {
    try {
      final data = await _client
          .from('environmental_risk_assessments')
          .update(assessment.toMap())
          .eq('id', id)
          .select()
          .single();

      return EnvironmentalAssessment.fromMap(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> deleteAssessment(String id) async {
    try {
      await _client
          .from('environmental_risk_assessments')
          .delete()
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<EnvironmentalAssessment>> getAssessmentsByLocation(String location) async {
    try {
      final data = await _client
          .from('environmental_risk_assessments')
          .select()
          .eq('location', location)
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => EnvironmentalAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<EnvironmentalAssessment>> getHighRiskAssessments() async {
    try {
      final data = await _client
          .from('environmental_risk_assessments')
          .select()
          .eq('risk_level', 'high')
          .or('risk_level.eq.high,risk_level.eq.critical')
          .order('assessment_date', ascending: false);

      return (data as List)
          .map((item) => EnvironmentalAssessment.fromMap(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> getAssessmentStats() async {
    try {
      final recent = await _client
          .from('environmental_risk_assessments')
          .select()
          .order('assessment_date', ascending: false)
          .limit(5);
      return {
        'total': (recent as List).length,
        'recent_assessments': recent,
      };
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}