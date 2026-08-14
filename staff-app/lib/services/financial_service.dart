import 'package:supabase/supabase.dart';
import 'package:staff_app/models/financial_assessment.dart';

class FinancialService {
  final SupabaseClient _supabase;

  FinancialService(this._supabase);

  // Create a new financial risk assessment
  Future<FinancialAssessment> createAssessment(FinancialAssessment assessment) async {
    try {
      final response = await _supabase
          .from('financial_risk_assessments')
          .insert(assessment.toJson())
          .select()
          .single();

      return FinancialAssessment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create financial assessment: $e');
    }
  }

  // Get a specific financial risk assessment by ID
  Future<FinancialAssessment> getAssessment(String id) async {
    try {
      final response = await _supabase
          .from('financial_risk_assessments')
          .select()
          .eq('id', id)
          .single();

      return FinancialAssessment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get financial assessment: $e');
    }
  }

  // Get all financial risk assessments for a service user
  Future<List<FinancialAssessment>> getAssessments({
    String? serviceUserId,
    String? financialCapacity,
    bool? signsOfFinancialAbuse,
    bool? appointeeDeputyAppointed,
    bool? safeguardingReferralMade,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase.from('financial_risk_assessments').select();

      if (serviceUserId != null) {
        query = query.eq('service_user_id', serviceUserId);
      }

      if (financialCapacity != null) {
        query = query.eq('financial_capacity', financialCapacity);
      }

      if (signsOfFinancialAbuse != null) {
        query = query.eq('signs_of_financial_abuse', signsOfFinancialAbuse);
      }

      if (appointeeDeputyAppointed != null) {
        query = query.eq('appointee_deputy_appointed', appointeeDeputyAppointed);
      }

      if (safeguardingReferralMade != null) {
        query = query.eq('safeguarding_referral_made', safeguardingReferralMade);
      }

      if (startDate != null && endDate != null) {
        query = query.gte('assessment_date', startDate.toIso8601String().split('T').first)
                   .lte('assessment_date', endDate.toIso8601String().split('T').first);
      }

      final response = await query.order('assessment_date', ascending: false);

      return response.map((item) => FinancialAssessment.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get financial assessments: $e');
    }
  }

  // Update a financial risk assessment
  Future<FinancialAssessment> updateAssessment(String id, FinancialAssessment assessment) async {
    try {
      final response = await _supabase
          .from('financial_risk_assessments')
          .update(assessment.toJson())
          .eq('id', id)
          .select()
          .single();

      return FinancialAssessment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update financial assessment: $e');
    }
  }

  // Delete a financial risk assessment
  Future<void> deleteAssessment(String id) async {
    try {
      await _supabase
          .from('financial_risk_assessments')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete financial assessment: $e');
    }
  }

  // Get high-risk financial assessments (for monitoring)
  Future<List<FinancialAssessment>> getHighRiskAssessments({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('financial_risk_assessments')
          .select()
          .or([
            'signs_of_financial_abuse.eq.true',
            'unusual_transactions.eq.true',
            'missing_money.eq.true',
            'pressure_from_others.eq.true',
            'gambling_concerns.eq.true',
            'scams_targeted.eq.true',
            'financial_capacity.eq.none',
            'debt_management.eq.struggling',
            'bills_paid.eq.late'
          ]);

      if (serviceUserId != null) {
        query = query.eq('service_user_id', serviceUserId);
      }

      if (startDate != null && endDate != null) {
        query = query.gte('assessment_date', startDate.toIso8601String().split('T').first)
                   .lte('assessment_date', endDate.toIso8601String().split('T').first);
      }

      final response = await query.order('assessment_date', ascending: false);

      return response.map((item) => FinancialAssessment.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get high-risk financial assessments: $e');
    }
  }

  // Get assessments requiring safeguarding referrals
  Future<List<FinancialAssessment>> getAssessmentsRequiringSafeguarding({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('financial_risk_assessments')
          .select()
          .or([
            'signs_of_financial_abuse.eq.true',
            'unusual_transactions.eq.true',
            'missing_money.eq.true',
            'pressure_from_others.eq.true',
            'scams_targeted.eq.true'
          ])
          .eq('safeguarding_referral_made', false);

      if (serviceUserId != null) {
        query = query.eq('service_user_id', serviceUserId);
      }

      if (startDate != null && endDate != null) {
        query = query.gte('assessment_date', startDate.toIso8601String().split('T').first)
                   .lte('assessment_date', endDate.toIso8601String().split('T').first);
      }

      final response = await query.order('assessment_date', ascending: false);

      return response.map((item) => FinancialAssessment.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get assessments requiring safeguarding: $e');
    }
  }

  // Get assessments requiring appointee referrals
  Future<List<FinancialAssessment>> getAssessmentsRequiringAppointee({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('financial_risk_assessments')
          .select()
          .or([
            'financial_capacity.eq.none',
            'managing_own_finances.eq.no'
          ])
          .eq('appointee_deputy_appointed', false);

      if (serviceUserId != null) {
        query = query.eq('service_user_id', serviceUserId);
      }

      if (startDate != null && endDate != null) {
        query = query.gte('assessment_date', startDate.toIso8601String().split('T').first)
                   .lte('assessment_date', endDate.toIso8601String().split('T').first);
      }

      final response = await query.order('assessment_date', ascending: false);

      return response.map((item) => FinancialAssessment.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get assessments requiring appointee: $e');
    }
  }

  // Get assessments due for review
  Future<List<FinancialAssessment>> getAssessmentsDueForReview({
    String? serviceUserId,
  }) async {
    try {
      var query = _supabase
          .from('financial_risk_assessments')
          .select()
          .or([
            'review_date.lte.now()',
            'and(assessment_date.lte.now().sub(180).days(),review_date.is.null)'
          ]);

      if (serviceUserId != null) {
        query = query.eq('service_user_id', serviceUserId);
      }

      final response = await query.order('assessment_date', ascending: false);

      return response.map((item) => FinancialAssessment.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get assessments due for review: $e');
    }
  }

  // Get financial risk statistics
  Future<Map<String, dynamic>> getFinancialRiskStatistics({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('financial_risk_assessments')
          .select('''
            count(*),
            count(case when financial_capacity = 'none' then 1 end) as no_capacity_count,
            count(case when financial_capacity = 'partial' then 1 end) as partial_capacity_count,
            count(case when signs_of_financial_abuse = true then 1 end) as abuse_cases_count,
            count(case when safeguarding_referral_made = true then 1 end) as safeguarding_referrals_count,
            count(case when appointee_deputy_appointed = true then 1 end) as appointee_count,
            count(case when scams_targeted = true then 1 end) as scam_cases_count,
            count(case when gambling_concerns = true then 1 end) as gambling_cases_count
          ''');

      if (serviceUserId != null) {
        query = query.eq('service_user_id', serviceUserId);
      }

      if (startDate != null && endDate != null) {
        query = query.gte('assessment_date', startDate.toIso8601String().split('T').first)
                   .lte('assessment_date', endDate.toIso8601String().split('T').first);
      }

      final response = await query;
      
      if (response.isNotEmpty) {
        final stats = response.first;
        return {
          'total_assessments': stats['count'],
          'no_capacity_count': stats['no_capacity_count'],
          'partial_capacity_count': stats['partial_capacity_count'],
          'abuse_cases_count': stats['abuse_cases_count'],
          'safeguarding_referrals_count': stats['safeguarding_referrals_count'],
          'appointee_count': stats['appointee_count'],
          'scam_cases_count': stats['scam_cases_count'],
          'gambling_cases_count': stats['gambling_cases_count'],
        };
      }
      
      return {};
    } catch (e) {
      throw Exception('Failed to get financial risk statistics: $e');
    }
  }

  // Get financial capacity distribution
  Future<Map<String, int>> getFinancialCapacityDistribution({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('financial_risk_assessments')
          .select('financial_capacity, count(*)')
          .group('financial_capacity');

      if (serviceUserId != null) {
        query = query.eq('service_user_id', serviceUserId);
      }

      if (startDate != null && endDate != null) {
        query = query.gte('assessment_date', startDate.toIso8601String().split('T').first)
                   .lte('assessment_date', endDate.toIso8601String().split('T').first);
      }

      final response = await query;
      
      return Map.fromIterable(
        response,
        key: (item) => item['financial_capacity'],
        value: (item) => item['count'],
      );
    } catch (e) {
      throw Exception('Failed to get financial capacity distribution: $e');
    }
  }

  // Get debt management distribution
  Future<Map<String, int>> getDebtManagementDistribution({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('financial_risk_assessments')
          .select('debt_management, count(*)')
          .group('debt_management');

      if (serviceUserId != null) {
        query = query.eq('service_user_id', serviceUserId);
      }

      if (startDate != null && endDate != null) {
        query = query.gte('assessment_date', startDate.toIso8601String().split('T').first)
                   .lte('assessment_date', endDate.toIso8601String().split('T').first);
      }

      final response = await query;
      
      return Map.fromIterable(
        response,
        key: (item) => item['debt_management'],
        value: (item) => item['count'],
      );
    } catch (e) {
      throw Exception('Failed to get debt management distribution: $e');
    }
  }

  // Get benefits claimed distribution
  Future<Map<String, int>> getBenefitsClaimedDistribution({
    String? serviceUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('financial_risk_assessments')
          .select('benefits_claimed');

      if (serviceUserId != null) {
        query = query.eq('service_user_id', serviceUserId);
      }

      if (startDate != null && endDate != null) {
        query = query.gte('assessment_date', startDate.toIso8601String().split('T').first)
                   .lte('assessment_date', endDate.toIso8601String().split('T').first);
      }

      final response = await query;
      
      final benefitsCount = <String, int>{};
      
      for (final item in response) {
        final benefits = item['benefits_claimed'] as List<dynamic>?;
        if (benefits != null) {
          for (final benefit in benefits) {
            final benefitStr = benefit.toString();
            benefitsCount[benefitStr] = (benefitsCount[benefitStr] ?? 0) + 1;
          }
        }
      }
      
      return benefitsCount;
    } catch (e) {
      throw Exception('Failed to get benefits claimed distribution: $e');
    }
  }

  // Mark safeguarding referral as made
  Future<void> markSafeguardingReferral(String id) async {
    try {
      await _supabase
          .from('financial_risk_assessments')
          .update({'safeguarding_referral_made': true})
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to mark safeguarding referral: $e');
    }
  }

  // Mark appointee/deputy as appointed
  Future<void> markAppointeeAppointed(String id, {String? appointeeName, String? appointeeContact}) async {
    try {
      final updateData = {
        'appointee_deputy_appointed': true,
      };
      
      if (appointeeName != null) {
        updateData['appointee_name'] = appointeeName;
      }
      
      if (appointeeContact != null) {
        updateData['appointee_contact'] = appointeeContact;
      }
      
      await _supabase
          .from('financial_risk_assessments')
          .update(updateData)
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to mark appointee as appointed: $e');
    }
  }

  // Mark financial support worker as involved
  Future<void> markFinancialSupportWorkerInvolved(String id) async {
    try {
      await _supabase
          .from('financial_risk_assessments')
          .update({'financial_support_worker_involved': true})
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to mark financial support worker as involved: $e');
    }
  }

  // Get recent financial assessments for dashboard
  Future<List<FinancialAssessment>> getRecentAssessments({
    String? serviceUserId,
    int limit = 10,
  }) async {
    try {
      var query = _supabase
          .from('financial_risk_assessments')
          .select()
          .order('assessment_date', ascending: false)
          .limit(limit);

      if (serviceUserId != null) {
        query = query.eq('service_user_id', serviceUserId);
      }

      final response = await query;

      return response.map((item) => FinancialAssessment.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get recent financial assessments: $e');
    }
  }
}