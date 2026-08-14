import 'package:supabase_flutter/supabase_flutter.dart';

class MentalCapacityAssessment {
  final String id;
  final String serviceUserId;
  final String assessorId;
  final DateTime assessmentDate;
  final Map<String, dynamic> functionalTest;
  final Map<String, dynamic> twoStageTest;
  final Map<String, dynamic> bestInterests;
  final Map<String, dynamic> imcaReferral;
  final String? signature;
  final String status;
  final String capacityLevel;
  final String? imcaDetails;

  MentalCapacityAssessment({
    required this.id,
    required this.serviceUserId,
    required this.assessorId,
    required this.assessmentDate,
    required this.functionalTest,
    required this.twoStageTest,
    required this.bestInterests,
    required this.imcaReferral,
    this.signature,
    required this.status,
    required this.capacityLevel,
    this.imcaDetails,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_user_id': serviceUserId,
      'assessor_id': assessorId,
      'assessment_date': assessmentDate,
      'functional_test': functionalTest,
      'two_stage_test': twoStageTest,
      'best_interests': bestInterests,
      'imca_referral': imcaReferral,
      'signature': signature,
      'status': status,
      'capacity_level': capacityLevel,
      'imca_details': imcaDetails,
      'created_at': DateTime.now(),
      'updated_at': DateTime.now(),
    };
  }

  factory MentalCapacityAssessment.fromMap(Map<String, dynamic> map) {
    return MentalCapacityAssessment(
      id: map['id'] ?? '',
      serviceUserId: map['service_user_id'] ?? '',
      assessorId: map['assessor_id'] ?? '',
      assessmentDate: (map['assessment_date'] as DateTime?) ?? DateTime.now(),
      functionalTest: map['functional_test'] ?? {},
      twoStageTest: map['two_stage_test'] ?? {},
      bestInterests: map['best_interests'] ?? {},
      imcaReferral: map['imca_referral'] ?? {},
      signature: map['signature'],
      status: map['status'] ?? 'draft',
      capacityLevel: map['capacity_level'] ?? 'Unknown',
      imcaDetails: map['imca_details'],
    );
  }

  String determineCapacityLevel() {
    // Logic to determine capacity level based on functional test results
    bool hasCapacity = true;
    
    // Check if person can understand, retain, use/weigh, and communicate
    if (functionalTest['understand'] == false || 
        functionalTest['retain'] == false || 
        functionalTest['weigh'] == false || 
        functionalTest['communicate'] == false) {
      hasCapacity = false;
    }
    
    // Check two-stage test
    if (twoStageTest['impairment'] == true && twoStageTest['inability'] == true) {
      hasCapacity = false;
    }
    
    return hasCapacity ? 'Has Capacity' : 'Lacks Capacity';
  }
}

class BestInterestsDecision {
  final String decision;
  final String reason;
  final String alternativesConsidered;
  final String consultationDetails;
  final DateTime decisionDate;

  BestInterestsDecision({
    required this.decision,
    required this.reason,
    required this.alternativesConsidered,
    required this.consultationDetails,
    required this.decisionDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'decision': decision,
      'reason': reason,
      'alternatives_considered': alternativesConsidered,
      'consultation_details': consultationDetails,
      'decision_date': decisionDate,
    };
  }
}

class ImcaReferral {
  final bool needsReferral;
  final String reason;
  final String referralDate;
  final String imcaName;
  final String contactDetails;
  final String status;

  ImcaReferral({
    required this.needsReferral,
    required this.reason,
    required this.referralDate,
    required this.imcaName,
    required this.contactDetails,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'needs_referral': needsReferral,
      'reason': reason,
      'referral_date': referralDate,
      'imca_name': imcaName,
      'contact_details': contactDetails,
      'status': status,
    };
  }
}

class MentalCapacitySummary {
  final int totalAssessments;
  final int hasCapacityCount;
  final int lacksCapacityCount;
  final DateTime? lastAssessmentDate;
  final int imcaReferralsCount;

  MentalCapacitySummary({
    required this.totalAssessments,
    required this.hasCapacityCount,
    required this.lacksCapacityCount,
    this.lastAssessmentDate,
    required this.imcaReferralsCount,
  });

  factory MentalCapacitySummary.fromMap(Map<String, dynamic> map) {
    return MentalCapacitySummary(
      totalAssessments: map['total_assessments'] as int,
      hasCapacityCount: map['has_capacity_count'] as int,
      lacksCapacityCount: map['lacks_capacity_count'] as int,
      lastAssessmentDate: map['last_assessment_date'] as DateTime?,
      imcaReferralsCount: map['imca_referrals_count'] as int,
    );
  }
}