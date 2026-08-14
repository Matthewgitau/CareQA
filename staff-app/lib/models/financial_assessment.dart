import 'dart:convert';

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
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.createdAt,
    this.updatedAt,
  });

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
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory FinancialAssessment.fromJson(Map<String, dynamic> json) {
    return FinancialAssessment(
      id: json['id'],
      serviceUserId: json['service_user_id'],
      assessmentDate: DateTime.parse(json['assessment_date']),
      financialCapacity: json['financial_capacity'],
      mentalCapacityAssessmentDate: json['mental_capacity_assessment_date'] != null 
          ? DateTime.parse(json['mental_capacity_assessment_date']) 
          : null,
      appointeeDeputyAppointed: json['appointee_deputy_appointed'] ?? false,
      appointeeName: json['appointee_name'],
      appointeeContact: json['appointee_contact'],
      managingOwnFinances: json['managing_own_finances'],
      benefitsClaimed: List<String>.from(json['benefits_claimed'] ?? []),
      savingsAndAssets: json['savings_and_assets'],
      debtManagement: json['debt_management'],
      billsPaid: json['bills_paid'],
      financialDecisionMaking: json['financial_decision_making'],
      signsOfFinancialAbuse: json['signs_of_financial_abuse'] ?? false,
      unusualTransactions: json['unusual_transactions'] ?? false,
      missingMoney: json['missing_money'] ?? false,
      pressureFromOthers: json['pressure_from_others'] ?? false,
      gamblingConcerns: json['gambling_concerns'] ?? false,
      scamsTargeted: json['scams_targeted'] ?? false,
      financialSupportWorkerInvolved: json['financial_support_worker_involved'] ?? false,
      safeguardingReferralMade: json['safeguarding_referral_made'] ?? false,
      actionPlan: json['action_plan'],
      reviewDate: json['review_date'] != null ? DateTime.parse(json['review_date']) : null,
      assessorName: json['assessor_name'],
      assessorSignature: json['assessor_signature'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

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

  @override
  String toString() {
    return 'FinancialAssessment(id: $id, serviceUserId: $serviceUserId, assessmentDate: $assessmentDate, financialCapacity: $financialCapacity, mentalCapacityAssessmentDate: $mentalCapacityAssessmentDate, appointeeDeputyAppointed: $appointeeDeputyAppointed, appointeeName: $appointeeName, appointeeContact: $appointeeContact, managingOwnFinances: $managingOwnFinances, benefitsClaimed: $benefitsClaimed, savingsAndAssets: $savingsAndAssets, debtManagement: $debtManagement, billsPaid: $billsPaid, financialDecisionMaking: $financialDecisionMaking, signsOfFinancialAbuse: $signsOfFinancialAbuse, unusualTransactions: $unusualTransactions, missingMoney: $missingMoney, pressureFromOthers: $pressureFromOthers, gamblingConcerns: $gamblingConcerns, scamsTargeted: $scamsTargeted, financialSupportWorkerInvolved: $financialSupportWorkerInvolved, safeguardingReferralMade: $safeguardingReferralMade, actionPlan: $actionPlan, reviewDate: $reviewDate, assessorName: $assessorName, assessorSignature: $assessorSignature, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is FinancialAssessment &&
      other.id == id &&
      other.serviceUserId == serviceUserId &&
      other.assessmentDate == assessmentDate &&
      other.financialCapacity == financialCapacity &&
      other.mentalCapacityAssessmentDate == mentalCapacityAssessmentDate &&
      other.appointeeDeputyAppointed == appointeeDeputyAppointed &&
      other.appointeeName == appointeeName &&
      other.appointeeContact == appointeeContact &&
      other.managingOwnFinances == managingOwnFinances &&
      listEquals(other.benefitsClaimed, benefitsClaimed) &&
      other.savingsAndAssets == savingsAndAssets &&
      other.debtManagement == debtManagement &&
      other.billsPaid == billsPaid &&
      other.financialDecisionMaking == financialDecisionMaking &&
      other.signsOfFinancialAbuse == signsOfFinancialAbuse &&
      other.unusualTransactions == unusualTransactions &&
      other.missingMoney == missingMoney &&
      other.pressureFromOthers == pressureFromOthers &&
      other.gamblingConcerns == gamblingConcerns &&
      other.scamsTargeted == scamsTargeted &&
      other.financialSupportWorkerInvolved == financialSupportWorkerInvolved &&
      other.safeguardingReferralMade == safeguardingReferralMade &&
      other.actionPlan == actionPlan &&
      other.reviewDate == reviewDate &&
      other.assessorName == assessorName &&
      other.assessorSignature == assessorSignature &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      serviceUserId.hashCode ^
      assessmentDate.hashCode ^
      financialCapacity.hashCode ^
      mentalCapacityAssessmentDate.hashCode ^
      appointeeDeputyAppointed.hashCode ^
      appointeeName.hashCode ^
      appointeeContact.hashCode ^
      managingOwnFinances.hashCode ^
      benefitsClaimed.hashCode ^
      savingsAndAssets.hashCode ^
      debtManagement.hashCode ^
      billsPaid.hashCode ^
      financialDecisionMaking.hashCode ^
      signsOfFinancialAbuse.hashCode ^
      unusualTransactions.hashCode ^
      missingMoney.hashCode ^
      pressureFromOthers.hashCode ^
      gamblingConcerns.hashCode ^
      scamsTargeted.hashCode ^
      financialSupportWorkerInvolved.hashCode ^
      safeguardingReferralMade.hashCode ^
      actionPlan.hashCode ^
      reviewDate.hashCode ^
      assessorName.hashCode ^
      assessorSignature.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
  }

  bool listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}