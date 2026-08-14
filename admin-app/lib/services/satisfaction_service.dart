import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/satisfaction_survey.dart';
import '../models/staff_recognition.dart';
import '../models/satisfaction_trend.dart';

class SatisfactionService {
  final SupabaseClient _client;

  SatisfactionService(this._client);

  // ==================== SURVEYS ====================

  Future<SatisfactionSurvey?> createSurvey(SatisfactionSurvey survey) async {
    try {
      final data = survey.toJson();
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
        data['created_by'] = user.id;
      }

      final response = await _client
          .from('satisfaction_surveys')
          .insert(data)
          .select()
          .single();

      return SatisfactionSurvey.fromJson(response);
    } catch (e) {
      print('Error creating survey: $e');
      rethrow;
    }
  }

  Future<List<SatisfactionSurvey>> getSurveys() async {
    try {
      final response = await _client
          .from('satisfaction_surveys')
          .select('*')
          .order('survey_date', ascending: false);
      return (response as List).map((json) => SatisfactionSurvey.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching surveys: $e');
      return [];
    }
  }

  Future<List<SatisfactionSurvey>> getSurveysForStaff(String staffId) async {
    try {
      final response = await _client
          .from('satisfaction_surveys')
          .select('*')
          .eq('staff_id', staffId)
          .order('survey_date', ascending: false);
      return (response as List).map((json) => SatisfactionSurvey.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching surveys for staff: $e');
      return [];
    }
  }

  Future<SatisfactionSurvey?> updateSurvey(String id, SatisfactionSurvey survey) async {
    try {
      final data = survey.toJson();
      data.remove('created_at');
      data.remove('updated_at');

      final response = await _client
          .from('satisfaction_surveys')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return SatisfactionSurvey.fromJson(response);
    } catch (e) {
      print('Error updating survey: $e');
      rethrow;
    }
  }

  // ==================== TRENDS ====================

  Future<List<SatisfactionTrend>> getTrends() async {
    try {
      final response = await _client
          .from('satisfaction_trends')
          .select('*')
          .order('period_start', ascending: false);
      return (response as List).map((json) => SatisfactionTrend.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching trends: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> generateTrendReport() async {
    try {
      final surveys = await getSurveys();
      
      if (surveys.isEmpty) {
        return {
          'total_surveys': 0,
          'avg_satisfaction': 0.0,
          'avg_engagement': 0.0,
          'response_rate': 0.0,
        };
      }

      final avgSatisfaction = surveys.map((s) => s.overallSatisfaction ?? 0).reduce((a, b) => a + b) / surveys.length;
      final avgEngagement = surveys.map((s) => s.engagementScore ?? 0).reduce((a, b) => a + b) / surveys.length;
      
      return {
        'total_surveys': surveys.length,
        'avg_satisfaction': avgSatisfaction,
        'avg_engagement': avgEngagement,
        'surveys': surveys,
      };
    } catch (e) {
      print('Error generating trend report: $e');
      return {};
    }
  }

  // ==================== RECOGNITION ====================

  Future<StaffRecognition?> createRecognition(StaffRecognition recognition) async {
    try {
      final data = recognition.toJson();
      data.remove('id');
      data.remove('created_at');

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
          .from('staff_recognition')
          .insert(data)
          .select()
          .single();

      return StaffRecognition.fromJson(response);
    } catch (e) {
      print('Error creating recognition: $e');
      rethrow;
    }
  }

  Future<List<StaffRecognition>> getRecognition() async {
    try {
      final response = await _client
          .from('staff_recognition')
          .select('*')
          .order('recognition_date', ascending: false);
      return (response as List).map((json) => StaffRecognition.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching recognition: $e');
      return [];
    }
  }

  // ==================== HELPERS ====================

  Future<List<Map<String, dynamic>>> getAllStaff() async {
    try {
      final allEmployees = <Map<String, dynamic>>[];

      // Get non-carer staff from profiles
      final staffResponse = await _client
          .from('profiles')
          .select('id, full_name, email, role')
          .neq('role', 'carer')
          .order('full_name', ascending: true);
      
      for (final staff in staffResponse) {
        allEmployees.add({
          'id': staff['id'],
          'name': staff['full_name'],
          'type': 'staff',
        });
      }

      // Get carers from carers table
      final carersResponse = await _client
          .from('carers')
          .select('id, name, employee_number')
          .eq('is_active', true)
          .order('name', ascending: true);
      
      for (final carer in carersResponse) {
        allEmployees.add({
          'id': carer['id'],
          'name': carer['name'],
          'type': 'carer',
        });
      }

      return allEmployees;
    } catch (e) {
      print('Error fetching staff: $e');
      return [];
    }
  }
}