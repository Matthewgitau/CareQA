import 'package:supabase/supabase.dart';
import 'package:staff_app/models/anaphylaxis_assessment.dart';

class AnaphylaxisService {
  final SupabaseClient _client;

  AnaphylaxisService(this._client);

  // Create a new anaphylaxis assessment
  Future<String> createAssessment(AnaphylaxisAssessment assessment) async {
    try {
      final data = assessment.toJson();
      data.remove('id'); // Remove ID for insert, it will be auto-generated
      data.remove('created_at'); // Remove created_at for insert, it will be auto-generated
      data.remove('updated_at'); // Remove updated_at for insert, it will be auto-generated
      
      final response = await _client
          .from('anaphylaxis_risk_assessments')
          .insert(data)
          .select()
          .single();
      
      return response['id'] as String;
    } on PostgrestException catch (e) {
      throw Exception('Failed to create anaphylaxis assessment: ${e.message}');
    }
  }

  // Update an existing anaphylaxis assessment
  Future<void> updateAssessment(AnaphylaxisAssessment assessment) async {
    try {
      final data = assessment.toJson();
      data.remove('id'); // Remove ID from update data
      data.remove('created_at'); // Remove created_at from update data
      
      await _client
          .from('anaphylaxis_risk_assessments')
          .update(data)
          .eq('id', assessment.id!);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update anaphylaxis assessment: ${e.message}');
    }
  }

  // Get an anaphylaxis assessment by ID
  Future<AnaphylaxisAssessment?> getAssessmentById(String id) async {
    try {
      final response = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .eq('id', id)
          .single();
      
      return AnaphylaxisAssessment.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch anaphylaxis assessment: ${e.message}');
    }
  }

  // Get all anaphylaxis assessments for a service user
  Future<List<AnaphylaxisAssessment>> getAssessmentsByServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch anaphylaxis assessments: ${e.message}');
    }
  }

  // Get all anaphylaxis assessments for a specific assessor
  Future<List<AnaphylaxisAssessment>> getAssessmentsByAssessor(String assessorId) async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .eq('assessor_id', assessorId)
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch anaphylaxis assessments: ${e.message}');
    }
  }

  // Get all anaphylaxis assessments
  Future<List<AnaphylaxisAssessment>> getAllAssessments() async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch anaphylaxis assessments: ${e.message}');
    }
  }

  // Submit an assessment (calculate risk level and set status)
  Future<void> submitAssessment(String assessmentId, String? reviewerId) async {
    try {
      final assessment = await getAssessmentById(assessmentId);
      if (assessment == null) {
        throw Exception('Assessment not found');
      }

      final riskLevel = assessment.calculateRiskLevel();
      final autoinjectorStatus = assessment.getAutoinjectorStatus();
      final needsEscalation = assessment.needsEscalation();

      await _client
          .from('anaphylaxis_risk_assessments')
          .update({
            'risk_level': riskLevel,
            'status': needsEscalation ? 'escalated' : 'completed',
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': reviewerId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assessmentId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to submit anaphylaxis assessment: ${e.message}');
    }
  }

  // Get assessments that need review (escalated or overdue)
  Future<List<AnaphylaxisAssessment>> getAssessmentsNeedingReview() async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .or('status.eq.escalated,status.eq.pending_review')
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch assessments needing review: ${e.message}');
    }
  }

  // Get high-risk assessments
  Future<List<AnaphylaxisAssessment>> getHighRiskAssessments() async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .or('risk_level.eq.high,risk_level.eq.extreme')
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch high-risk assessments: ${e.message}');
    }
  }

  // Get assessments by status
  Future<List<AnaphylaxisAssessment>> getAssessmentsByStatus(String status) async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .eq('status', status)
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch assessments by status: ${e.message}');
    }
  }

  // Get assessments by risk level
  Future<List<AnaphylaxisAssessment>> getAssessmentsByRiskLevel(String riskLevel) async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .eq('risk_level', riskLevel)
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch assessments by risk level: ${e.message}');
    }
  }

  // Delete an assessment
  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _client
          .from('anaphylaxis_risk_assessments')
          .delete()
          .eq('id', assessmentId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete anaphylaxis assessment: ${e.message}');
    }
  }

  // Get assessments with auto-injector expiry warnings
  Future<List<AnaphylaxisAssessment>> getAssessmentsWithExpiryWarnings() async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .eq('autoinjector_prescribed', true)
          .lt('autoinjector_expiry_date', DateTime.now().add(Duration(days: 90)).toIso8601String())
          .order('autoinjector_expiry_date', ascending: true);
      
      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch assessments with expiry warnings: ${e.message}');
    }
  }

  // Get assessments that need review based on review date
  Future<List<AnaphylaxisAssessment>> getAssessmentsOverdueForReview() async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .lt('next_review_date', DateTime.now().toIso8601String())
          .order('next_review_date', ascending: true);
      
      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch assessments overdue for review: ${e.message}');
    }
  }

  // Get assessments for a specific date range
  Future<List<AnaphylaxisAssessment>> getAssessmentsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch assessments by date range: ${e.message}');
    }
  }

  // Get latest assessment for a service user
  Future<AnaphylaxisAssessment?> getLatestAssessmentForServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('created_at', ascending: false)
          .limit(1);
      
      if (data.isEmpty) {
        return null;
      }
      
      return AnaphylaxisAssessment.fromJson(data.first as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch latest assessment: ${e.message}');
    }
  }

  // Check if a service user has any active anaphylaxis assessments
  Future<bool> hasActiveAssessment(String serviceUserId) async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select('id')
          .eq('service_user_id', serviceUserId)
          .or('status.eq.pending,status.eq.escalated,status.eq.completed');
      
      return data.isNotEmpty;
    } on PostgrestException catch (e) {
      throw Exception('Failed to check active assessments: ${e.message}');
    }
  }

  // Get assessments with specific allergens
  Future<List<AnaphylaxisAssessment>> getAssessmentsByAllergens(List<String> allergens) async {
    try {
      final data = await _client
          .from('anaphylaxis_risk_assessments')
          .select()
          .overlaps('allergens', allergens)
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((item) => AnaphylaxisAssessment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch assessments by allergens: ${e.message}');
    }
  }

  // Update assessment review information
  Future<void> updateReviewInfo(
    String assessmentId,
    String reviewerId,
    String? reviewNotes,
    DateTime? nextReviewDate,
  ) async {
    try {
      await _client
          .from('anaphylaxis_risk_assessments')
          .update({
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': reviewerId,
            'assessment_notes': reviewNotes,
            'next_review_date': nextReviewDate?.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assessmentId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update review information: ${e.message}');
    }
  }
}
