import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';

class AnaphylaxisAssessment {
  final String? id;
  final String serviceUserId;
  final String assessorId;
  
  // Allergy identification
  final List<String> allergens;
  final String? allergenDetails;
  
  // Reaction history
  final String? previousReactionSeverity;
  final DateTime? previousReactionDate;
  final String? previousReactionDetails;
  
  // Auto-injector management
  final bool autoinjectorPrescribed;
  final String? autoinjectorType;
  final String? autoinjectorLocation;
  final DateTime? autoinjectorExpiryDate;
  final bool autoinjectorInDate;
  final DateTime? autoinjectorCheckDate;
  
  // Emergency preparedness
  final bool emergencyActionPlan;
  final String? actionPlanLocation;
  final DateTime? actionPlanReviewDate;
  
  // Staff training and awareness
  final bool staffTrainedAutoinjector;
  final DateTime? staffTrainingDate;
  final DateTime? staffTrainingExpiryDate;
  final bool serviceUserSelfAdminister;
  
  // Allergy awareness
  final bool allergyAlertVisible;
  final String? allergyAlertLocation;
  final bool medicalIdJewellery;
  final String? medicalIdDetails;
  
  // Specialist care
  final bool allergySpecialistReferral;
  final String? specialistName;
  final DateTime? lastAppointmentDate;
  final DateTime? nextAppointmentDate;
  
  // Risk management
  final List<String> crossReactivityRisks;
  final String? crossReactivityDetails;
  final List<String> dietaryRestrictions;
  final String? dietaryDetails;
  
  // Assessment metadata
  final String? riskLevel;
  final String? status;
  final bool reviewRequired;
  final DateTime? nextReviewDate;
  
  // Documentation
  final String? assessmentNotes;
  final String? signatureData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  AnaphylaxisAssessment({
    this.id,
    required this.serviceUserId,
    required this.assessorId,
    required this.allergens,
    this.allergenDetails,
    this.previousReactionSeverity,
    this.previousReactionDate,
    this.previousReactionDetails,
    required this.autoinjectorPrescribed,
    this.autoinjectorType,
    this.autoinjectorLocation,
    this.autoinjectorExpiryDate,
    required this.autoinjectorInDate,
    this.autoinjectorCheckDate,
    required this.emergencyActionPlan,
    this.actionPlanLocation,
    this.actionPlanReviewDate,
    required this.staffTrainedAutoinjector,
    this.staffTrainingDate,
    this.staffTrainingExpiryDate,
    required this.serviceUserSelfAdminister,
    required this.allergyAlertVisible,
    this.allergyAlertLocation,
    required this.medicalIdJewellery,
    this.medicalIdDetails,
    required this.allergySpecialistReferral,
    this.specialistName,
    this.lastAppointmentDate,
    this.nextAppointmentDate,
    required this.crossReactivityRisks,
    this.crossReactivityDetails,
    required this.dietaryRestrictions,
    this.dietaryDetails,
    this.riskLevel,
    this.status,
    required this.reviewRequired,
    this.nextReviewDate,
    this.assessmentNotes,
    this.signatureData,
    required this.createdAt,
    required this.updatedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory AnaphylaxisAssessment.fromJson(Map<String, dynamic> json) {
    return AnaphylaxisAssessment(
      id: json['id'],
      serviceUserId: json['service_user_id'],
      assessorId: json['assessor_id'],
      allergens: List<String>.from(json['allergens'] ?? []),
      allergenDetails: json['allergen_details'],
      previousReactionSeverity: json['previous_reaction_severity'],
      previousReactionDate: json['previous_reaction_date'] != null 
          ? DateTime.parse(json['previous_reaction_date'])
          : null,
      previousReactionDetails: json['previous_reaction_details'],
      autoinjectorPrescribed: json['autoinjector_prescribed'] ?? false,
      autoinjectorType: json['autoinjector_type'],
      autoinjectorLocation: json['autoinjector_location'],
      autoinjectorExpiryDate: json['autoinjector_expiry_date'] != null 
          ? DateTime.parse(json['autoinjector_expiry_date'])
          : null,
      autoinjectorInDate: json['autoinjector_in_date'] ?? true,
      autoinjectorCheckDate: json['autoinjector_check_date'] != null 
          ? DateTime.parse(json['autoinjector_check_date'])
          : null,
      emergencyActionPlan: json['emergency_action_plan'] ?? false,
      actionPlanLocation: json['action_plan_location'],
      actionPlanReviewDate: json['action_plan_review_date'] != null 
          ? DateTime.parse(json['action_plan_review_date'])
          : null,
      staffTrainedAutoinjector: json['staff_trained_autoinjector'] ?? false,
      staffTrainingDate: json['staff_training_date'] != null 
          ? DateTime.parse(json['staff_training_date'])
          : null,
      staffTrainingExpiryDate: json['staff_training_expiry_date'] != null 
          ? DateTime.parse(json['staff_training_expiry_date'])
          : null,
      serviceUserSelfAdminister: json['service_user_self_administer'] ?? false,
      allergyAlertVisible: json['allergy_alert_visible'] ?? false,
      allergyAlertLocation: json['allergy_alert_location'],
      medicalIdJewellery: json['medical_id_jewellery'] ?? false,
      medicalIdDetails: json['medical_id_details'],
      allergySpecialistReferral: json['allergy_specialist_referral'] ?? false,
      specialistName: json['specialist_name'],
      lastAppointmentDate: json['last_appointment_date'] != null 
          ? DateTime.parse(json['last_appointment_date'])
          : null,
      nextAppointmentDate: json['next_appointment_date'] != null 
          ? DateTime.parse(json['next_appointment_date'])
          : null,
      crossReactivityRisks: List<String>.from(json['cross_reactivity_risks'] ?? []),
      crossReactivityDetails: json['cross_reactivity_details'],
      dietaryRestrictions: List<String>.from(json['dietary_restrictions'] ?? []),
      dietaryDetails: json['dietary_details'],
      riskLevel: json['risk_level'],
      status: json['status'],
      reviewRequired: json['review_required'] ?? false,
      nextReviewDate: json['next_review_date'] != null 
          ? DateTime.parse(json['next_review_date'])
          : null,
      assessmentNotes: json['assessment_notes'],
      signatureData: json['signature_data'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      reviewedAt: json['reviewed_at'] != null 
          ? DateTime.parse(json['reviewed_at'])
          : null,
      reviewedBy: json['reviewed_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_user_id': serviceUserId,
      'assessor_id': assessorId,
      'allergens': allergens,
      'allergen_details': allergenDetails,
      'previous_reaction_severity': previousReactionSeverity,
      'previous_reaction_date': previousReactionDate?.toIso8601String(),
      'previous_reaction_details': previousReactionDetails,
      'autoinjector_prescribed': autoinjectorPrescribed,
      'autoinjector_type': autoinjectorType,
      'autoinjector_location': autoinjectorLocation,
      'autoinjector_expiry_date': autoinjectorExpiryDate?.toIso8601String(),
      'autoinjector_in_date': autoinjectorInDate,
      'autoinjector_check_date': autoinjectorCheckDate?.toIso8601String(),
      'emergency_action_plan': emergencyActionPlan,
      'action_plan_location': actionPlanLocation,
      'action_plan_review_date': actionPlanReviewDate?.toIso8601String(),
      'staff_trained_autoinjector': staffTrainedAutoinjector,
      'staff_training_date': staffTrainingDate?.toIso8601String(),
      'staff_training_expiry_date': staffTrainingExpiryDate?.toIso8601String(),
      'service_user_self_administer': serviceUserSelfAdminister,
      'allergy_alert_visible': allergyAlertVisible,
      'allergy_alert_location': allergyAlertLocation,
      'medical_id_jewellery': medicalIdJewellery,
      'medical_id_details': medicalIdDetails,
      'allergy_specialist_referral': allergySpecialistReferral,
      'specialist_name': specialistName,
      'last_appointment_date': lastAppointmentDate?.toIso8601String(),
      'next_appointment_date': nextAppointmentDate?.toIso8601String(),
      'cross_reactivity_risks': crossReactivityRisks,
      'cross_reactivity_details': crossReactivityDetails,
      'dietary_restrictions': dietaryRestrictions,
      'dietary_details': dietaryDetails,
      'risk_level': riskLevel,
      'status': status,
      'review_required': reviewRequired,
      'next_review_date': nextReviewDate?.toIso8601String(),
      'assessment_notes': assessmentNotes,
      'signature_data': signatureData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
    };
  }

  // Factory method to create a new assessment
  static AnaphylaxisAssessment createNew({
    required String serviceUserId,
    required String assessorId,
  }) {
    return AnaphylaxisAssessment(
      serviceUserId: serviceUserId,
      assessorId: assessorId,
      allergens: [],
      autoinjectorPrescribed: false,
      autoinjectorInDate: true,
      emergencyActionPlan: false,
      staffTrainedAutoinjector: false,
      serviceUserSelfAdminister: false,
      allergyAlertVisible: false,
      medicalIdJewellery: false,
      allergySpecialistReferral: false,
      crossReactivityRisks: [],
      dietaryRestrictions: [],
      reviewRequired: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Copy with method for updating assessment
  AnaphylaxisAssessment copyWith({
    String? id,
    String? serviceUserId,
    String? assessorId,
    List<String>? allergens,
    String? allergenDetails,
    String? previousReactionSeverity,
    DateTime? previousReactionDate,
    String? previousReactionDetails,
    bool? autoinjectorPrescribed,
    String? autoinjectorType,
    String? autoinjectorLocation,
    DateTime? autoinjectorExpiryDate,
    bool? autoinjectorInDate,
    DateTime? autoinjectorCheckDate,
    bool? emergencyActionPlan,
    String? actionPlanLocation,
    DateTime? actionPlanReviewDate,
    bool? staffTrainedAutoinjector,
    DateTime? staffTrainingDate,
    DateTime? staffTrainingExpiryDate,
    bool? serviceUserSelfAdminister,
    bool? allergyAlertVisible,
    String? allergyAlertLocation,
    bool? medicalIdJewellery,
    String? medicalIdDetails,
    bool? allergySpecialistReferral,
    String? specialistName,
    DateTime? lastAppointmentDate,
    DateTime? nextAppointmentDate,
    List<String>? crossReactivityRisks,
    String? crossReactivityDetails,
    List<String>? dietaryRestrictions,
    String? dietaryDetails,
    String? riskLevel,
    String? status,
    bool? reviewRequired,
    DateTime? nextReviewDate,
    String? assessmentNotes,
    String? signatureData,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    return AnaphylaxisAssessment(
      id: id ?? this.id,
      serviceUserId: serviceUserId ?? this.serviceUserId,
      assessorId: assessorId ?? this.assessorId,
      allergens: allergens ?? this.allergens,
      allergenDetails: allergenDetails ?? this.allergenDetails,
      previousReactionSeverity: previousReactionSeverity ?? this.previousReactionSeverity,
      previousReactionDate: previousReactionDate ?? this.previousReactionDate,
      previousReactionDetails: previousReactionDetails ?? this.previousReactionDetails,
      autoinjectorPrescribed: autoinjectorPrescribed ?? this.autoinjectorPrescribed,
      autoinjectorType: autoinjectorType ?? this.autoinjectorType,
      autoinjectorLocation: autoinjectorLocation ?? this.autoinjectorLocation,
      autoinjectorExpiryDate: autoinjectorExpiryDate ?? this.autoinjectorExpiryDate,
      autoinjectorInDate: autoinjectorInDate ?? this.autoinjectorInDate,
      autoinjectorCheckDate: autoinjectorCheckDate ?? this.autoinjectorCheckDate,
      emergencyActionPlan: emergencyActionPlan ?? this.emergencyActionPlan,
      actionPlanLocation: actionPlanLocation ?? this.actionPlanLocation,
      actionPlanReviewDate: actionPlanReviewDate ?? this.actionPlanReviewDate,
      staffTrainedAutoinjector: staffTrainedAutoinjector ?? this.staffTrainedAutoinjector,
      staffTrainingDate: staffTrainingDate ?? this.staffTrainingDate,
      staffTrainingExpiryDate: staffTrainingExpiryDate ?? this.staffTrainingExpiryDate,
      serviceUserSelfAdminister: serviceUserSelfAdminister ?? this.serviceUserSelfAdminister,
      allergyAlertVisible: allergyAlertVisible ?? this.allergyAlertVisible,
      allergyAlertLocation: allergyAlertLocation ?? this.allergyAlertLocation,
      medicalIdJewellery: medicalIdJewellery ?? this.medicalIdJewellery,
      medicalIdDetails: medicalIdDetails ?? this.medicalIdDetails,
      allergySpecialistReferral: allergySpecialistReferral ?? this.allergySpecialistReferral,
      specialistName: specialistName ?? this.specialistName,
      lastAppointmentDate: lastAppointmentDate ?? this.lastAppointmentDate,
      nextAppointmentDate: nextAppointmentDate ?? this.nextAppointmentDate,
      crossReactivityRisks: crossReactivityRisks ?? this.crossReactivityRisks,
      crossReactivityDetails: crossReactivityDetails ?? this.crossReactivityDetails,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      dietaryDetails: dietaryDetails ?? this.dietaryDetails,
      riskLevel: riskLevel ?? this.riskLevel,
      status: status ?? this.status,
      reviewRequired: reviewRequired ?? this.reviewRequired,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      assessmentNotes: assessmentNotes ?? this.assessmentNotes,
      signatureData: signatureData ?? this.signatureData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }

  // Calculate risk level based on assessment data
  String calculateRiskLevel() {
    int riskScore = 0;
    
    // Base risk from previous reaction severity
    switch (previousReactionSeverity) {
      case 'anaphylactic':
        riskScore += 4;
        break;
      case 'severe':
        riskScore += 3;
        break;
      case 'moderate':
        riskScore += 2;
        break;
      case 'mild':
        riskScore += 1;
        break;
      default:
        riskScore += 1;
    }
    
    // Risk reduction factors
    if (autoinjectorPrescribed && autoinjectorInDate) {
      riskScore -= 1;
    }
    
    if (emergencyActionPlan) {
      riskScore -= 1;
    }
    
    if (staffTrainedAutoinjector) {
      riskScore -= 1;
    }
    
    if (allergyAlertVisible) {
      riskScore -= 1;
    }
    
    // Determine risk level
    if (riskScore >= 4) return 'extreme';
    if (riskScore >= 3) return 'high';
    if (riskScore >= 2) return 'medium';
    return 'low';
  }

  // Check if auto-injector is expired or expiring soon
  String getAutoinjectorStatus() {
    if (!autoinjectorPrescribed) return 'not_prescribed';
    if (!autoinjectorInDate) return 'expired';
    if (autoinjectorExpiryDate != null && 
        autoinjectorExpiryDate!.isBefore(DateTime.now().add(Duration(days: 90)))) {
      return 'expiring_soon';
    }
    return 'current';
  }

  // Check if review is overdue
  String getReviewStatus() {
    if (nextReviewDate == null) return 'no_review_date';
    if (nextReviewDate!.isBefore(DateTime.now())) return 'overdue';
    if (nextReviewDate!.isBefore(DateTime.now().add(Duration(days: 30)))) return 'due_soon';
    return 'current';
  }

  // Get display text for previous reaction severity
  String getPreviousReactionSeverityDisplay() {
    switch (previousReactionSeverity) {
      case 'mild':
        return 'Mild Reaction';
      case 'moderate':
        return 'Moderate Reaction';
      case 'severe':
        return 'Severe Reaction';
      case 'anaphylactic':
        return 'Anaphylactic Reaction';
      default:
        return 'Unknown';
    }
  }

  // Get display text for auto-injector type
  String getAutoinjectorTypeDisplay() {
    switch (autoinjectorType) {
      case 'epipen':
        return 'EpiPen';
      case 'jext':
        return 'Jext';
      case 'emeras':
        return 'Emerade';
      default:
        return autoinjectorType ?? 'Unknown';
    }
  }

  // Check if assessment is complete
  bool isComplete() {
    return allergens.isNotEmpty && 
           previousReactionSeverity != null && 
           autoinjectorPrescribed != null;
  }

  // Get validation errors
  List<String> getValidationErrors() {
    List<String> errors = [];
    
    if (allergens.isEmpty) {
      errors.add('Allergens must be specified');
    }
    
    if (previousReactionSeverity == null) {
      errors.add('Previous reaction severity must be specified');
    }
    
    if (autoinjectorPrescribed == null) {
      errors.add('Auto-injector prescription status must be specified');
    }
    
    if (autoinjectorPrescribed && autoinjectorExpiryDate == null) {
      errors.add('Auto-injector expiry date is required when prescribed');
    }
    
    if (emergencyActionPlan && actionPlanLocation == null) {
      errors.add('Action plan location is required when plan exists');
    }
    
    if (staffTrainedAutoinjector && staffTrainingDate == null) {
      errors.add('Staff training date is required when trained');
    }
    
    return errors;
  }

  // Check if assessment needs escalation
  bool needsEscalation() {
    return calculateRiskLevel() == 'high' || calculateRiskLevel() == 'extreme';
  }

  // Get summary of key information
  Map<String, String> getSummary() {
    return {
      'Allergens': allergens.join(', '),
      'Previous Reaction': getPreviousReactionSeverityDisplay(),
      'Risk Level': calculateRiskLevel().toUpperCase(),
      'Auto-injector': getAutoinjectorStatus().toUpperCase(),
      'Emergency Plan': emergencyActionPlan ? 'YES' : 'NO',
      'Staff Trained': staffTrainedAutoinjector ? 'YES' : 'NO',
      'Allergy Alert': allergyAlertVisible ? 'VISIBLE' : 'NOT VISIBLE',
    };
  }

  @override
  String toString() {
    return 'AnaphylaxisAssessment(id: $id, serviceUserId: $serviceUserId, allergens: $allergens, riskLevel: $riskLevel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
  
    return other is AnaphylaxisAssessment &&
           other.id == id &&
           other.serviceUserId == serviceUserId &&
           other.assessorId == assessorId &&
           listEquals(other.allergens, allergens) &&
           other.allergenDetails == allergenDetails &&
           other.previousReactionSeverity == previousReactionSeverity &&
           other.previousReactionDate == previousReactionDate &&
           other.previousReactionDetails == previousReactionDetails &&
           other.autoinjectorPrescribed == autoinjectorPrescribed &&
           other.autoinjectorType == autoinjectorType &&
           other.autoinjectorLocation == autoinjectorLocation &&
           other.autoinjectorExpiryDate == autoinjectorExpiryDate &&
           other.autoinjectorInDate == autoinjectorInDate &&
           other.autoinjectorCheckDate == autoinjectorCheckDate &&
           other.emergencyActionPlan == emergencyActionPlan &&
           other.actionPlanLocation == actionPlanLocation &&
           other.actionPlanReviewDate == actionPlanReviewDate &&
           other.staffTrainedAutoinjector == staffTrainedAutoinjector &&
           other.staffTrainingDate == staffTrainingDate &&
           other.staffTrainingExpiryDate == staffTrainingExpiryDate &&
           other.serviceUserSelfAdminister == serviceUserSelfAdminister &&
           other.allergyAlertVisible == allergyAlertVisible &&
           other.allergyAlertLocation == allergyAlertLocation &&
           other.medicalIdJewellery == medicalIdJewellery &&
           other.medicalIdDetails == medicalIdDetails &&
           other.allergySpecialistReferral == allergySpecialistReferral &&
           other.specialistName == specialistName &&
           other.lastAppointmentDate == lastAppointmentDate &&
           other.nextAppointmentDate == nextAppointmentDate &&
           listEquals(other.crossReactivityRisks, crossReactivityRisks) &&
           other.crossReactivityDetails == crossReactivityDetails &&
           listEquals(other.dietaryRestrictions, dietaryRestrictions) &&
           other.dietaryDetails == dietaryDetails &&
           other.riskLevel == riskLevel &&
           other.status == status &&
           other.reviewRequired == reviewRequired &&
           other.nextReviewDate == nextReviewDate &&
           other.assessmentNotes == assessmentNotes &&
           other.signatureData == signatureData &&
           other.createdAt == createdAt &&
           other.updatedAt == updatedAt &&
           other.reviewedAt == reviewedAt &&
           other.reviewedBy == reviewedBy;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      serviceUserId,
      assessorId,
      allergens,
      allergenDetails,
      previousReactionSeverity,
      previousReactionDate,
      previousReactionDetails,
      autoinjectorPrescribed,
      autoinjectorType,
      autoinjectorLocation,
      autoinjectorExpiryDate,
      autoinjectorInDate,
      autoinjectorCheckDate,
      emergencyActionPlan,
      actionPlanLocation,
      actionPlanReviewDate,
      staffTrainedAutoinjector,
      staffTrainingDate,
      staffTrainingExpiryDate,
      serviceUserSelfAdminister,
      allergyAlertVisible,
      allergyAlertLocation,
      medicalIdJewellery,
      medicalIdDetails,
      allergySpecialistReferral,
      specialistName,
      lastAppointmentDate,
      nextAppointmentDate,
      crossReactivityRisks,
      crossReactivityDetails,
      dietaryRestrictions,
      dietaryDetails,
      riskLevel,
      status,
      reviewRequired,
      nextReviewDate,
      assessmentNotes,
      signatureData,
      createdAt,
      updatedAt,
      reviewedAt,
      reviewedBy,
    );
  }
}