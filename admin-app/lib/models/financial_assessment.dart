import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';

class FinancialAssessment {
  final String? id;
  final String? serviceUserId;
  final DateTime assessmentDate;
  final String financialCapacity;
  final DateTime? mentalCapacityAssessmentDate;
  final bool appointeeDeputyAppointed;
  final String? appointeeName;
  final String? appointeeContact;
  final String managingOwnFinances;
  final List<String> benefitsClaimed;
  final double? savingsAndAssets;
  final String debtManagement;
  final String billsPaid;
  final String financialDecisionMaking;
  final bool signsOfFinancialAbuse;
  final bool unusualTransactions;
  final bool missingMoney;
  final bool pressureFromOthers;
  final bool gamblingConcerns;
  final bool scamsTargeted;
  final bool financialSupportWorkerInvolved;
  final bool safeguardingReferralMade;
  final String? actionPlan;
  final DateTime? reviewDate;
  final String assessorName;
  final String? assessorSignature;
  final DateTime createdAt;
  final DateTime updatedAt;

  FinancialAssessment({
    this.id,
    this.serviceUserId,
    required this.assessmentDate,
    required this.financialCapacity,
    this.mentalCapacityAssessmentDate,
    required this.appointeeDeputyAppointed,
    this.appointeeName,
    this.appointeeContact,
    required this.managingOwnFinances,
    required this.benefitsClaimed,
    this.savingsAndAssets,
    required this.debtManagement,
    required this.billsPaid,
    required this.financialDecisionMaking,
    required this.signsOfFinancialAbuse,
    required this.unusualTransactions,
    required this.missingMoney,
    required this.pressureFromOthers,
    required this.gamblingConcerns,
    required this.scamsTargeted,
    required this.financialSupportWorkerInvolved,
    required this.safeguardingReferralMade,
    this.actionPlan,
    this.reviewDate,
    required this.assessorName,
    this.assessorSignature,
    required this.createdAt,
    required this.updatedAt,
  });

  // Getters for display formatting
  String get financialCapacityText {
    switch (financialCapacity) {
      case 'full': return 'Full Capacity';
      case 'partial': return 'Partial Capacity';
      case 'none': return 'No Capacity';
      default: return financialCapacity;
    }
  }

  String get managingOwnFinancesText {
    switch (managingOwnFinances) {
      case 'yes': return 'Yes - Fully Independent';
      case 'no': return 'No - Requires Full Support';
      case 'partial': return 'Partial - Some Support Needed';
      default: return managingOwnFinances;
    }
  }

  String get debtManagementText {
    switch (debtManagement) {
      case 'none': return 'No Debt';
      case 'manageable': return 'Manageable Debt';
      case 'struggling': return 'Struggling with Debt';
      default: return debtManagement;
    }
  }

  String get billsPaidText {
    switch (billsPaid) {
      case 'on_time': return 'On Time';
      case 'late': return 'Late';
      case 'unsure': return 'Unsure';
      default: return billsPaid;
    }
  }

  String get financialDecisionMakingText {
    switch (financialDecisionMaking) {
      case 'independent': return 'Independent';
      case 'supported': return 'Supported';
      case 'unable': return 'Unable';
      default: return financialDecisionMaking;
    }
  }

  String get benefitsClaimedText {
    if (benefitsClaimed.isEmpty) return 'No Benefits Claimed';
    return benefitsClaimed.join(', ');
  }

  String get savingsAndAssetsText {
    if (savingsAndAssets == null || savingsAndAssets == 0) {
      return 'No Savings/Assets';
    }
    return '£${savingsAndAssets!.toStringAsFixed(2)}';
  }

  // Risk calculation methods
  String get riskLevel {
    int riskScore = 0;
    
    // Base risk based on financial capacity
    switch (financialCapacity) {
      case 'none': riskScore += 3; break;
      case 'partial': riskScore += 2; break;
      case 'full': riskScore += 0; break;
    }
    
    // Risk factors
    if (signsOfFinancialAbuse) riskScore += 4;
    if (unusualTransactions) riskScore += 3;
    if (missingMoney) riskScore += 3;
    if (pressureFromOthers) riskScore += 2;
    if (gamblingConcerns) riskScore += 3;
    if (scamsTargeted) riskScore += 3;
    
    // Debt and bill management
    switch (debtManagement) {
      case 'struggling': riskScore += 3; break;
      case 'manageable': riskScore += 1; break;
      case 'none': riskScore += 0; break;
    }
    
    switch (billsPaid) {
      case 'late': riskScore += 2; break;
      case 'unsure': riskScore += 1; break;
      case 'on_time': riskScore += 0; break;
    }
    
    // Determine risk level
    if (riskScore >= 10) return 'high';
    if (riskScore >= 5) return 'medium';
    return 'low';
  }

  String get riskLevelText {
    switch (riskLevel) {
      case 'high': return 'High Risk';
      case 'medium': return 'Medium Risk';
      case 'low': return 'Low Risk';
      default: return 'Unknown';
    }
  }

  String get riskLevelEmoji {
    switch (riskLevel) {
      case 'high': return '🔴';
      case 'medium': return '🟡';
      case 'low': return '🟢';
      default: return '⚪';
    }
  }

  Color get riskLevelColor {
    switch (riskLevel) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  // Safeguarding and referral logic
  bool get needsSafeguardingReferral {
    return signsOfFinancialAbuse || 
           unusualTransactions || 
           missingMoney || 
           pressureFromOthers || 
           scamsTargeted;
  }

  bool get needsAppointeeReferral {
    return (financialCapacity == 'none' || managingOwnFinances == 'no') && 
           !appointeeDeputyAppointed;
  }

  bool get needsFinancialSupportWorker {
    return (financialCapacity != 'full' || signsOfFinancialAbuse) && 
           !financialSupportWorkerInvolved;
  }

  // Review and monitoring
  bool get isReviewDue {
    if (reviewDate != null) {
      return reviewDate!.isBefore(DateTime.now());
    }
    return assessmentDate.isBefore(DateTime.now().subtract(const Duration(days: 180)));
  }

  String get reviewStatus {
    if (isReviewDue) return 'Review Due';
    if (reviewDate != null) {
      return 'Next Review: ${reviewDate!.toIso8601String().split('T').first}';
    }
    return 'Review in 6 months';
  }

  String get reviewFrequencyRecommendation {
    if (signsOfFinancialAbuse || financialCapacity == 'none' || debtManagement == 'struggling') {
      return 'Monthly review recommended';
    }
    if (financialCapacity == 'partial' || billsPaid == 'late') {
      return 'Quarterly review recommended';
    }
    return 'Annual review recommended';
  }

  // Support recommendations
  String get supportRecommendations {
    List<String> recommendations = [];
    
    if (financialCapacity == 'none' && !appointeeDeputyAppointed) {
      recommendations.add('Appointee/Deputy required');
    }
    
    if (managingOwnFinances == 'no' && !appointeeDeputyAppointed) {
      recommendations.add('Financial management support needed');
    }
    
    if (signsOfFinancialAbuse) {
      recommendations.add('Enhanced monitoring and safeguarding measures required');
    }
    
    if (needsFinancialSupportWorker) {
      recommendations.add('Financial support worker involvement recommended');
    }
    
    if (recommendations.isEmpty) {
      return 'Continue current monitoring approach';
    }
    
    return recommendations.join('. ');
  }

  // Abuse indicators summary
  String get abuseIndicatorsSummary {
    List<String> indicators = [];
    
    if (signsOfFinancialAbuse) indicators.add('Signs of financial abuse detected');
    if (unusualTransactions) indicators.add('Unusual financial transactions');
    if (missingMoney) indicators.add('Missing money reported');
    if (pressureFromOthers) indicators.add('Pressure from others regarding finances');
    if (gamblingConcerns) indicators.add('Gambling concerns identified');
    if (scamsTargeted) indicators.add('Potential scam targeting');
    
    if (indicators.isEmpty) {
      return 'No specific abuse indicators detected';
    }
    
    return indicators.join('. ');
  }

  // Benefits summary
  String get benefitsSummary {
    if (benefitsClaimed.isEmpty) return 'No benefits claimed';
    
    List<String> benefitTypes = [];
    benefitsClaimed.forEach((benefit) {
      switch (benefit.toLowerCase()) {
        case 'pip':
          benefitTypes.add('Personal Independence Payment');
          break;
        case 'aa':
          benefitTypes.add('Attendance Allowance');
          break;
        case 'uc':
          benefitTypes.add('Universal Credit');
          break;
        case 'state pension':
          benefitTypes.add('State Pension');
          break;
        default:
          benefitTypes.add(benefit);
      }
    });
    
    return benefitTypes.join(', ');
  }

  // Capacity summary
  String get capacitySummary {
    List<String> capacityInfo = [];
    
    capacityInfo.add('Financial Capacity: $financialCapacityText');
    if (mentalCapacityAssessmentDate != null) {
      capacityInfo.add('Mental Capacity Assessment: ${mentalCapacityAssessmentDate!.toIso8601String().split('T').first}');
    }
    capacityInfo.add('Managing Own Finances: $managingOwnFinancesText');
    capacityInfo.add('Financial Decision Making: $financialDecisionMakingText');
    
    return capacityInfo.join('. ');
  }

  // Appointee/Deputy status
  String get appointeeStatus {
    if (!appointeeDeputyAppointed) {
      return 'No appointee/deputy appointed';
    }
    
    List<String> status = ['Appointee/Deputy appointed'];
    if (appointeeName != null && appointeeName!.isNotEmpty) {
      status.add('Name: $appointeeName');
    }
    if (appointeeContact != null && appointeeContact!.isNotEmpty) {
      status.add('Contact: $appointeeContact');
    }
    
    return status.join('. ');
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_user_id': serviceUserId,
      'assessment_date': assessmentDate.toIso8601String(),
      'financial_capacity': financialCapacity,
      'mental_capacity_assessment_date': mentalCapacityAssessmentDate?.toIso8601String(),
      'appointee_deputy_appointed': appointeeDeputyAppointed,
      'appointee_name': appointeeName,
      'appointee_contact': appointeeContact,
      'managing_own_finances': managingOwnFinances,
      'benefits_claimed': benefitsClaimed,
      'savings_and_assets': savingsAndAssets,
      'debt_management': debtManagement,
      'bills_paid': billsPaid,
      'financial_decision_making': financialDecisionMaking,
      'signs_of_financial_abuse': signsOfFinancialAbuse,
      'unusual_transactions': unusualTransactions,
      'missing_money': missingMoney,
      'pressure_from_others': pressureFromOthers,
      'gambling_concerns': gamblingConcerns,
      'scams_targeted': scamsTargeted,
      'financial_support_worker_involved': financialSupportWorkerInvolved,
      'safeguarding_referral_made': safeguardingReferralMade,
      'action_plan': actionPlan,
      'review_date': reviewDate?.toIso8601String(),
      'assessor_name': assessorName,
      'assessor_signature': assessorSignature,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // From JSON factory
  factory FinancialAssessment.fromJson(Map<String, dynamic> json) {
    return FinancialAssessment(
      id: json['id'],
      serviceUserId: json['service_user_id'],
      assessmentDate: DateTime.parse(json['assessment_date']),
      financialCapacity: json['financial_capacity'],
      mentalCapacityAssessmentDate: json['mental_capacity_assessment_date'] != null 
          ? DateTime.parse(json['mental_capacity_assessment_date']) 
          : null,
      appointeeDeputyAppointed: json['appointee_deputy_appointed'],
      appointeeName: json['appointee_name'],
      appointeeContact: json['appointee_contact'],
      managingOwnFinances: json['managing_own_finances'],
      benefitsClaimed: List<String>.from(json['benefits_claimed'] ?? []),
      savingsAndAssets: json['savings_and_assets'],
      debtManagement: json['debt_management'],
      billsPaid: json['bills_paid'],
      financialDecisionMaking: json['financial_decision_making'],
      signsOfFinancialAbuse: json['signs_of_financial_abuse'],
      unusualTransactions: json['unusual_transactions'],
      missingMoney: json['missing_money'],
      pressureFromOthers: json['pressure_from_others'],
      gamblingConcerns: json['gambling_concerns'],
      scamsTargeted: json['scams_targeted'],
      financialSupportWorkerInvolved: json['financial_support_worker_involved'],
      safeguardingReferralMade: json['safeguarding_referral_made'],
      actionPlan: json['action_plan'],
      reviewDate: json['review_date'] != null ? DateTime.parse(json['review_date']) : null,
      assessorName: json['assessor_name'],
      assessorSignature: json['assessor_signature'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Copy with method for updates
  FinancialAssessment copyWith({
    String? id,
    String? serviceUserId,
    DateTime? assessmentDate,
    String? financialCapacity,
    DateTime? mentalCapacityAssessmentDate,
    bool? appointeeDeputyAppointed,
    String? appointeeName,
    String? appointeeContact,
    String? managingOwnFinances,
    List<String>? benefitsClaimed,
    double? savingsAndAssets,
    String? debtManagement,
    String? billsPaid,
    String? financialDecisionMaking,
    bool? signsOfFinancialAbuse,
    bool? unusualTransactions,
    bool? missingMoney,
    bool? pressureFromOthers,
    bool? gamblingConcerns,
    bool? scamsTargeted,
    bool? financialSupportWorkerInvolved,
    bool? safeguardingReferralMade,
    String? actionPlan,
    DateTime? reviewDate,
    String? assessorName,
    String? assessorSignature,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinancialAssessment(
      id: id ?? this.id,
      serviceUserId: serviceUserId ?? this.serviceUserId,
      assessmentDate: assessmentDate ?? this.assessmentDate,
      financialCapacity: financialCapacity ?? this.financialCapacity,
      mentalCapacityAssessmentDate: mentalCapacityAssessmentDate ?? this.mentalCapacityAssessmentDate,
      appointeeDeputyAppointed: appointeeDeputyAppointed ?? this.appointeeDeputyAppointed,
      appointeeName: appointeeName ?? this.appointeeName,
      appointeeContact: appointeeContact ?? this.appointeeContact,
      managingOwnFinances: managingOwnFinances ?? this.managingOwnFinances,
      benefitsClaimed: benefitsClaimed ?? this.benefitsClaimed,
      savingsAndAssets: savingsAndAssets ?? this.savingsAndAssets,
      debtManagement: debtManagement ?? this.debtManagement,
      billsPaid: billsPaid ?? this.billsPaid,
      financialDecisionMaking: financialDecisionMaking ?? this.financialDecisionMaking,
      signsOfFinancialAbuse: signsOfFinancialAbuse ?? this.signsOfFinancialAbuse,
      unusualTransactions: unusualTransactions ?? this.unusualTransactions,
      missingMoney: missingMoney ?? this.missingMoney,
      pressureFromOthers: pressureFromOthers ?? this.pressureFromOthers,
      gamblingConcerns: gamblingConcerns ?? this.gamblingConcerns,
      scamsTargeted: scamsTargeted ?? this.scamsTargeted,
      financialSupportWorkerInvolved: financialSupportWorkerInvolved ?? this.financialSupportWorkerInvolved,
      safeguardingReferralMade: safeguardingReferralMade ?? this.safeguardingReferralMade,
      actionPlan: actionPlan ?? this.actionPlan,
      reviewDate: reviewDate ?? this.reviewDate,
      assessorName: assessorName ?? this.assessorName,
      assessorSignature: assessorSignature ?? this.assessorSignature,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}