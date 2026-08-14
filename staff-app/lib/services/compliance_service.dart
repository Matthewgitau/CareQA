import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:staff_app/models/compliance_flag.dart';
import 'package:staff_app/models/compliance_score.dart';
import 'package:staff_app/models/teaching_moment.dart';

class ComplianceService {
  final SupabaseClient _client;

  ComplianceService(this._client);

  // Compliance Flags
  Stream<List<ComplianceFlag>> getComplianceFlagsByCarer(String carerId) {
    return _client
        .from('compliance_flags')
        .select('*, carers(name), shifts(scheduled_date, service_users(name))')
        .eq('carer_id', carerId)
        .order('created_at', ascending: false)
        .execute()
        .asStream()
        .map((response) {
      if (response.error != null) {
        print('Error fetching compliance flags: ${response.error}');
        return [];
      }
      return (response.data as List)
          .map((flag) => ComplianceFlag.fromMap(flag as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> updateComplianceFlagStatus(
    String flagId, 
    String status, 
    String? acknowledgedBy, 
    String? resolvedBy
  ) async {
    try {
      await _client.from('compliance_flags').update({
        'status': status,
        if (acknowledgedBy != null) 'acknowledged_by': acknowledgedBy,
        if (acknowledgedBy != null) 'acknowledged_at': DateTime.now(),
        if (resolvedBy != null) 'resolved_by': resolvedBy,
        if (resolvedBy != null) 'resolved_at': DateTime.now(),
      }).eq('id', flagId);
    } catch (e) {
      print('Error updating compliance flag: $e');
      throw e;
    }
  }

  // Compliance Scores
  Stream<List<ComplianceScore>> getComplianceScoresByCarer(String carerId) {
    return _client
        .from('compliance_scores')
        .select()
        .eq('carer_id', carerId)
        .order('score_date', ascending: false)
        .execute()
        .asStream()
        .map((response) {
      if (response.error != null) {
        print('Error fetching compliance scores: ${response.error}');
        return [];
      }
      return (response.data as List)
          .map((score) => ComplianceScore.fromMap(score as Map<String, dynamic>))
          .toList();
    });
  }

  // Teaching Moments
  Stream<List<TeachingMoment>> getTeachingMomentsByUser(String userId) {
    return _client
        .from('teaching_moments')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .execute()
        .asStream()
        .map((response) {
      if (response.error != null) {
        print('Error fetching teaching moments: ${response.error}');
        return [];
      }
      return (response.data as List)
          .map((moment) => TeachingMoment.fromMap(moment as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> updateTeachingMoment(
    String momentId, 
    bool quizPassed, 
    DateTime? viewedAt, 
    DateTime? completedAt
  ) async {
    try {
      await _client.from('teaching_moments').update({
        'quiz_passed': quizPassed,
        if (viewedAt != null) 'viewed_at': viewedAt,
        if (completedAt != null) 'completed_at': completedAt,
      }).eq('id', momentId);
    } catch (e) {
      print('Error updating teaching moment: $e');
      throw e;
    }
  }

  // Compliance Insights (using database function)
  Future<Map<String, dynamic>?> getComplianceInsights() async {
    try {
      final response = await _client.rpc('generate_compliance_insights');
      
      if (response.error != null) {
        print('Error fetching compliance insights: ${response.error}');
        return null;
      }
      
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting compliance insights: $e');
      return null;
    }
  }

  // Compliance Settings
  Future<Map<String, dynamic>?> getComplianceSettings() async {
    try {
      final response = await _client.rpc('get_compliance_settings');
      
      if (response.error != null) {
        print('Error fetching compliance settings: ${response.error}');
        return null;
      }
      
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting compliance settings: $e');
      return null;
    }
  }
}