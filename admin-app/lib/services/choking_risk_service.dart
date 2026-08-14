import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/choking_risk_assessment.dart';
import 'dart:async';

class ChokingRiskService {
  final SupabaseClient _client;

  ChokingRiskService(this._client);

  // Get all risk factors
  Future<List<ChokingRiskFactor>> getRiskFactors() async {
    try {
      final data = await _client
          .from('choking_risk_factors')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);
      
      return (data as List)
          .map((factor) => ChokingRiskFactor.fromMap(factor as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<ChokingRiskFactor>> getRiskFactorsOnce() async {
    try {
      final data = await _client
          .from('choking_risk_factors')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true) as List;
      
      return data
          .map((factor) => ChokingRiskFactor.fromMap(factor as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error fetching choking risk factors: ${e.message}');
    }
  }

  // Create new assessment
  Future<String> createAssessment({
    required String serviceUserId,
    required String assessorName,
    required DateTime assessmentDate,
    required String assessmentTime,
  }) async {
    try {
      final data = await _client.from('choking_risk_assessments').insert({
        'service_user_id': serviceUserId,
        'assessor_name': assessorName,
        'assessment_date': assessmentDate.toIso8601String(),
        'assessment_time': assessmentTime,
        'created_by': _client.auth.currentUser?.id,
        'status': 'draft',
        'risk_factors': {},
      }).select().single();
      
      return data['id'] as String;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Save risk factors as JSONB (36 questions)
  Future<void> saveRiskFactors({
    required String assessmentId,
    required Map<String, int> riskFactors,
  }) async {
    try {
      await _client.from('choking_risk_assessments').update({
        'risk_factors': riskFactors,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', assessmentId);
    } on PostgrestException catch (e) {
      throw Exception('Error saving risk factors: ${e.message}');
    }
  }

  // Save scores (legacy)
  Future<void> saveScores({
    required String assessmentId,
    required Map<int, int> scores,
    required Map<int, String> notes,
  }) async {
    try {
      // Delete existing scores
      await _client
          .from('choking_risk_scores')
          .delete()
          .eq('assessment_id', assessmentId);
      
      // Insert new scores
      if (scores.isNotEmpty) {
        final scoreEntries = scores.entries.map((e) => {
          'assessment_id': assessmentId,
          'risk_factor_id': e.key,
          'score': e.value,
          'notes': notes[e.key] ?? '',
        }).toList();
        
        await _client.from('choking_risk_scores').insert(scoreEntries);
      }
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Complete assessment with signature
  Future<void> completeAssessment({
    required String assessmentId,
    required String signatureData,
  }) async {
    try {
      await _client.from('choking_risk_assessments').update({
        'sfarr_signature': signatureData,
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', assessmentId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get assessment with scores
  Future<ChokingRiskAssessment> getAssessmentWithScores(String assessmentId) async {
    try {
      final data = await _client.rpc('get_choking_assessment_with_scores', params: {
        'assessment_id': assessmentId,
      });
      
      final assessmentData = data['assessment_data'] as Map<String, dynamic>;
      final scoresData = data['scores_data'] as List<dynamic>;
      
      return ChokingRiskAssessment.fromAssessmentWithScores(
        assessmentData,
        scoresData.cast<Map<String, dynamic>>(),
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get assessment summary
  Future<ChokingRiskSummary?> getAssessmentSummary(String assessmentId) async {
    try {
      final data = await _client.rpc('get_choking_risk_summary', params: {
        'assessment_id': assessmentId,
      });
      
      if (data == null) {
        return null;
      }
      
      return ChokingRiskSummary.fromMap(data);
    } on PostgrestException catch (e) {
      print('Error fetching assessment summary: ${e.message}');
      return null;
    }
  }

  // Validate assessment completeness
  Future<ChokingRiskValidation> validateAssessmentCompleteness(String assessmentId) async {
    try {
      final data = await _client.rpc('validate_choking_risk_completeness', params: {
        'assessment_id': assessmentId,
      });
      
      return ChokingRiskValidation.fromMap(data);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Submit assessment
  Future<bool> submitAssessment(String assessmentId, String signatureData) async {
    try {
      final data = await _client.rpc('submit_choking_risk_assessment', params: {
        'assessment_id': assessmentId,
        'signature_data': signatureData,
      });
      
      return data as bool;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get assessments for service user
  Future<List<ChokingRiskHistoryItem>> getAssessmentsForServiceUser(String serviceUserId) async {
    try {
      final data = await _client
          .from('choking_risk_totals')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => ChokingRiskHistoryItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<ChokingRiskHistoryItem>> getAssessmentsForServiceUserOnce(String serviceUserId) async {
    try {
      final data = await _client
          .from('choking_risk_totals')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => ChokingRiskHistoryItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get all assessments for a specific service user (full assessment objects)
  Future<List<ChokingRiskAssessment>> getAssessmentsByServiceUser(String serviceUserId) async {
    try {
      final response = await _client
          .from('choking_risk_assessments')
          .select('*')
          .eq('service_user_id', serviceUserId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((a) => ChokingRiskAssessment.fromMap(a as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get latest assessment for service user
  Future<ChokingRiskAssessment?> getLatestAssessment(String serviceUserId) async {
    try {
      final data = await _client
          .from('choking_risk_totals')
          .select()
          .eq('service_user_id', serviceUserId)
          .order('assessment_date', ascending: false)
          .limit(1)
          .single();
      
      return getAssessmentWithScores(data['assessment_id'] as String);
    } on PostgrestException catch (_) {
      return null;
    }
  }

  // Search assessments
  Future<List<ChokingRiskHistoryItem>> searchAssessments({
    String? serviceUserName,
    String? assessorName,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? riskLevel,
    String? status,
  }) async {
    try {
      var query = _client.from('choking_risk_totals').select();

      if (serviceUserName != null && serviceUserName.isNotEmpty) {
        query = query.ilike('service_user_name', '%$serviceUserName%');
      }

      if (assessorName != null && assessorName.isNotEmpty) {
        query = query.ilike('assessor_name', '%$assessorName%');
      }

      if (riskLevel != null) {
        query = query.eq('risk_level', riskLevel);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      if (dateFrom != null) {
        query = query.gte('assessment_date', dateFrom.toIso8601String());
      }

      if (dateTo != null) {
        query = query.lte('assessment_date', dateTo.toIso8601String());
      }

      final data = await query.order('assessment_date', ascending: false);
      
      return (data as List)
          .map((item) => ChokingRiskHistoryItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Delete assessment
  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _client
          .from('choking_risk_assessments')
          .delete()
          .eq('id', assessmentId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get risk factors by category
  Future<Map<String, List<ChokingRiskFactor>>> getRiskFactorsByCategory() async {
    final factors = await getRiskFactorsOnce();
    
    final Map<String, List<ChokingRiskFactor>> result = <String, List<ChokingRiskFactor>>{};
    
    for (final factor in factors) {
      final category = factor.category ?? 'Other';
      if (!result.containsKey(category)) {
        result[category] = [];
      }
      result[category]!.add(factor);
    }
    
    return result;
  }

  // Extended questions methods (migration 057)

  // Get extended questions by category
  Future<Map<String, List<Map<String, dynamic>>>> getExtendedQuestionsByCategory() async {
    try {
      final data = await _client
          .from('choking_extended_questions')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      final Map<String, List<Map<String, dynamic>>> result = <String, List<Map<String, dynamic>>>{};

      for (final question in data as List) {
        final category = question['category'] as String;
        if (!result.containsKey(category)) {
          result[category] = [];
        }
        result[category]!.add(question as Map<String, dynamic>);
      }

      return result;
    } on PostgrestException catch (e) {
      throw Exception('Error fetching extended questions: ${e.message}');
    }
  }

  // Save extended questions answers
  Future<void> saveExtendedQuestions({
    required String assessmentId,
    required Map<String, dynamic> answers,
  }) async {
    try {
      await _client.from('choking_risk_assessments').update({
        'extended_questions': answers,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', assessmentId);
    } on PostgrestException catch (e) {
      throw Exception('Error saving extended questions: ${e.message}');
    }
  }

  // Update assessment with extended fields
  Future<void> updateAssessmentExtendedFields({
    required String assessmentId,
    int? totalScore,
    String? riskCategory,
    DateTime? reviewDate,
    bool? sltReviewRequired,
    bool? dietModificationRequired,
    bool? fluidModificationRequired,
    bool? feedingAidRequired,
    String? supervisionLevel,
    Map<String, dynamic>? extendedQuestions,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (totalScore != null) updateData['total_score'] = totalScore;
      if (riskCategory != null) updateData['risk_category'] = riskCategory;
      if (reviewDate != null) updateData['review_date'] = reviewDate.toIso8601String();
      if (sltReviewRequired != null) updateData['slt_review_required'] = sltReviewRequired;
      if (dietModificationRequired != null) updateData['diet_modification_required'] = dietModificationRequired;
      if (fluidModificationRequired != null) updateData['fluid_modification_required'] = fluidModificationRequired;
      if (feedingAidRequired != null) updateData['feeding_aid_required'] = feedingAidRequired;
      if (supervisionLevel != null) updateData['supervision_level'] = supervisionLevel;
      if (extendedQuestions != null) updateData['extended_questions'] = extendedQuestions;

      await _client.from('choking_risk_assessments').update(updateData).eq('id', assessmentId);
    } on PostgrestException catch (e) {
      throw Exception('Error updating assessment: ${e.message}');
    }
  }

  // Calculate comprehensive risk score
  Future<Map<String, dynamic>?> calculateComprehensiveRisk(String assessmentId) async {
    try {
      final data = await _client.rpc('calculate_comprehensive_choking_risk', params: {
        'assessment_id': assessmentId,
      });

      if (data == null || (data as List).isEmpty) {
        return null;
      }

      return {
        'total_score': data[0]['total_score'] as int,
        'risk_level': data[0]['risk_level'] as String,
        'recommendations': List<String>.from(data[0]['recommendations'] ?? []),
      };
    } on PostgrestException catch (e) {
      print('Error calculating comprehensive risk: ${e.message}');
      return null;
    }
  }

  // Get assessments requiring SLT review
  Future<List<ChokingRiskHistoryItem>> getAssessmentsRequiringSltReview() async {
    try {
      final data = await _client
          .from('choking_risk_assessments')
          .select()
          .eq('slt_review_required', true)
          .eq('status', 'completed')
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => ChokingRiskHistoryItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // Get assessments with diet modifications
  Future<List<ChokingRiskHistoryItem>> getAssessmentsWithDietModifications() async {
    try {
      final data = await _client
          .from('choking_risk_assessments')
          .select()
          .eq('diet_modification_required', true)
          .eq('status', 'completed')
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => ChokingRiskHistoryItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}
