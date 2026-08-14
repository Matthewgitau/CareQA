import 'package:flutter/material.dart';

class DiabetesAssessment {
  final String? id;
  final String serviceUserId;
  final String? assessorId;
  
  // Diabetes Information
  final String diabetesType;
  final String? diabetesTypeOther;
  final DateTime? diagnosisDate;
  final double? lastHba1cValue;
  final DateTime? lastHba1cDate;
  final double? hba1cTarget;
  
  // Blood Glucose Monitoring
  final String bgMonitoringFrequency;
  final String? bgMonitoringMethod;
  final String? cgmDeviceName;
  final double? cgmTargetRangeLow;
  final double? cgmTargetRangeHigh;
  
  // Medication Information
  final String? insulinRegime;
  final String? insulinType;
  final String? insulinDoseDetails;
  final List<String> oralMedications;
  final List<String> otherMedications;
  
  // Hypoglycaemia Assessment
  final String? hypoglycaemiaFrequency;
  final bool hypoglycaemiaSymptomsRecognized;
  final int? hypoglycaemiaSevereEpisodes;
  final bool hypoglycaemiaUnawareness;
  
  // Hyperglycaemia Assessment
  final String? hyperglycaemiaEpisodes;
  final bool hyperglycaemiaKetoacidosis;
  final bool hyperglycaemiaHyperosmolar;
  
  // Foot Care Assessment
  final DateTime? footCareAssessmentDate;
  final String? footCareAssessmentResult;
  final String? footCareAssessmentDetails;
  final DateTime? footCareReminderDate;
  final bool footwearAssessment;
  final bool nailCareAssessment;
  
  // Eye Screening
  final DateTime? eyeScreeningDate;
  final String? eyeScreeningResult;
  final String? eyeScreeningDetails;
  
  // Lifestyle
  final String? dietaryManagement;
  final String? dietaryManagementDetails;
  final String? exerciseLevel;
  final String? exerciseFrequency;
  final String? smokingStatus;
  final String? alcoholConsumption;
  
  // Hospital Admissions
  final int hospitalAdmissionsLastYear;
  final List<String> hospitalAdmissionReasons;
  
  // Complications
  final List<String> diabetesComplications;
  final List<String> otherHealthConditions;
  
  // Self-Management
  final bool sickDayRulesKnowledge;
  final bool sickDayRulesDocumented;
  final String? sickDayRulesDetails;
  final bool ketoneTestingKnowledge;
  final String? whenToSeekMedicalHelp;
  
  // Assessment Outcome
  final String? overallRiskLevel;
  final List<String> riskFactorsIdentified;
  final String? monitoringRequirements;
  final DateTime? nextReviewDate;
  
  // Status and Signatures
  final String status;
  final String? signature;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiabetesAssessment({
    this.id,
    required this.serviceUserId,
    this.assessorId,
    required this.diabetesType,
    this.diabetesTypeOther,
    this.diagnosisDate,
    this.lastHba1cValue,
    this.lastHba1cDate,
    this.hba1cTarget,
    required this.bgMonitoringFrequency,
    this.bgMonitoringMethod,
    this.cgmDeviceName,
    this.cgmTargetRangeLow,
    this.cgmTargetRangeHigh,
    this.insulinRegime,
    this.insulinType,
    this.insulinDoseDetails,
    this.oralMedications = const [],
    this.otherMedications = const [],
    this.hypoglycaemiaFrequency,
    this.hypoglycaemiaSymptomsRecognized = true,
    this.hypoglycaemiaSevereEpisodes = 0,
    this.hypoglycaemiaUnawareness = false,
    this.hyperglycaemiaEpisodes,
    this.hyperglycaemiaKetoacidosis = false,
    this.hyperglycaemiaHyperosmolar = false,
    this.footCareAssessmentDate,
    this.footCareAssessmentResult,
    this.footCareAssessmentDetails,
    this.footCareReminderDate,
    this.footwearAssessment = false,
    this.nailCareAssessment = false,
    this.eyeScreeningDate,
    this.eyeScreeningResult,
    this.eyeScreeningDetails,
    this.dietaryManagement,
    this.dietaryManagementDetails,
    this.exerciseLevel,
    this.exerciseFrequency,
    this.smokingStatus,
    this.alcoholConsumption,
    this.hospitalAdmissionsLastYear = 0,
    this.hospitalAdmissionReasons = const [],
    this.diabetesComplications = const [],
    this.otherHealthConditions = const [],
    this.sickDayRulesKnowledge = false,
    this.sickDayRulesDocumented = false,
    this.sickDayRulesDetails,
    this.ketoneTestingKnowledge = false,
    this.whenToSeekMedicalHelp,
    this.overallRiskLevel,
    this.riskFactorsIdentified = const [],
    this.monitoringRequirements,
    this.nextReviewDate,
    required this.status,
    this.signature,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // --- Factory: create new default assessment ---
  factory DiabetesAssessment.createNew(String serviceUserId, String? assessorId) {
    return DiabetesAssessment(
      serviceUserId: serviceUserId,
      assessorId: assessorId,
      diabetesType: 'type1',
      bgMonitoringFrequency: 'daily',
      oralMedications: [],
      otherMedications: [],
      hospitalAdmissionReasons: [],
      diabetesComplications: [],
      otherHealthConditions: [],
      riskFactorsIdentified: [],
      status: 'draft',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // --- Static helpers for dropdown options ---
  static List<String> getDiabetesTypes() => ['type1', 'type2', 'gestational', 'other', 'prediabetes'];
  static List<String> getBgMonitoringFrequencies() => ['multiple_daily', 'daily', 'weekly', 'occasionally', 'not_monitoring'];
  static List<String> getInsulinRegimes() => ['basal_bolus', 'basal_only', 'pump', 'mixed', 'none'];
  static List<String> getHypoglycaemiaFrequencies() => ['never', 'rarely', 'monthly', 'weekly', 'daily', 'multiple_daily'];
  static List<String> getHyperglycaemiaEpisodes() => ['never', 'rarely', 'monthly', 'weekly', 'daily'];
  static List<String> getFootCareResults() => ['normal', 'reduced_sensation', 'ulceration', 'amputation', 'deformity'];
  static List<String> getEyeScreeningResults() => ['normal', 'background', 'preproliferative', 'proliferative', 'maculopathy'];
  static List<String> getDietaryManagements() => ['unknown', 'carb_counting', 'fat_monitoring', 'protein_conscious', 'fluid_monitoring'];
  static List<String> getExerciseLevels() => ['sedentary', 'light', 'moderate', 'vigorous'];
  static List<String> getSmokingStatuses() => ['non_smoker', 'medium_smoker', 'chain_smoker', 'unknown'];
  static List<String> getAlcoholConsumptions() => ['none', 'occasional', 'moderate', 'heavy'];
  static List<String> getDiabetesComplications() => ['retinopathy', 'nephropathy', 'neuropathy', 'cardiovascular', 'foot_ulcer', 'gastroparesis', 'none'];
  static List<String> getRiskLevels() => ['low', 'medium', 'high', 'critical'];

  // --- Date parsing ---
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    if (value is String) return DateTime.parse(value).toLocal();
    return null;
  }

  factory DiabetesAssessment.fromJson(Map<String, dynamic> json) {
    return DiabetesAssessment(
      id: json['id'],
      serviceUserId: json['service_user_id'],
      assessorId: json['assessor_id'],
      diabetesType: json['diabetes_type'],
      diabetesTypeOther: json['diabetes_type_other'],
      diagnosisDate: _parseDate(json['diagnosis_date']),
      lastHba1cValue: (json['last_hba1c_value'] as num?)?.toDouble(),
      lastHba1cDate: _parseDate(json['last_hba1c_date']),
      hba1cTarget: (json['hba1c_target'] as num?)?.toDouble(),
      bgMonitoringFrequency: json['bg_monitoring_frequency'],
      bgMonitoringMethod: json['bg_monitoring_method'],
      cgmDeviceName: json['cgm_device_name'],
      cgmTargetRangeLow: (json['cgm_target_range_low'] as num?)?.toDouble(),
      cgmTargetRangeHigh: (json['cgm_target_range_high'] as num?)?.toDouble(),
      insulinRegime: json['insulin_regime'],
      insulinType: json['insulin_type'],
      insulinDoseDetails: json['insulin_dose_details'],
      oralMedications: List<String>.from(json['oral_medications'] ?? []),
      otherMedications: List<String>.from(json['other_medications'] ?? []),
      hypoglycaemiaFrequency: json['hypoglycaemia_frequency'],
      hypoglycaemiaSymptomsRecognized: json['hypoglycaemia_symptoms_recognized'] ?? true,
      hypoglycaemiaSevereEpisodes: json['hypoglycaemia_severe_episodes'] ?? 0,
      hypoglycaemiaUnawareness: json['hypoglycaemia_unawareness'] ?? false,
      hyperglycaemiaEpisodes: json['hyperglycaemia_episodes'],
      hyperglycaemiaKetoacidosis: json['hyperglycaemia_ketoacidosis'] ?? false,
      hyperglycaemiaHyperosmolar: json['hyperglycaemia_hyperosmolar'] ?? false,
      footCareAssessmentDate: _parseDate(json['foot_care_assessment_date']),
      footCareAssessmentResult: json['foot_care_assessment_result'],
      footCareAssessmentDetails: json['foot_care_assessment_details'],
      footCareReminderDate: _parseDate(json['foot_care_reminder_date']),
      footwearAssessment: json['footwear_assessment'] ?? false,
      nailCareAssessment: json['nail_care_assessment'] ?? false,
      eyeScreeningDate: _parseDate(json['eye_screening_date']),
      eyeScreeningResult: json['eye_screening_result'],
      eyeScreeningDetails: json['eye_screening_details'],
      dietaryManagement: json['dietary_management'],
      dietaryManagementDetails: json['dietary_management_details'],
      exerciseLevel: json['exercise_level'],
      exerciseFrequency: json['exercise_frequency'],
      smokingStatus: json['smoking_status'],
      alcoholConsumption: json['alcohol_consumption'],
      hospitalAdmissionsLastYear: json['hospital_admissions_last_year'] ?? 0,
      hospitalAdmissionReasons: List<String>.from(json['hospital_admission_reasons'] ?? []),
      diabetesComplications: List<String>.from(json['diabetes_complications'] ?? []),
      otherHealthConditions: List<String>.from(json['other_health_conditions'] ?? []),
      sickDayRulesKnowledge: json['sick_day_rules_knowledge'] ?? false,
      sickDayRulesDocumented: json['sick_day_rules_documented'] ?? false,
      sickDayRulesDetails: json['sick_day_rules_details'],
      ketoneTestingKnowledge: json['ketone_testing_knowledge'] ?? false,
      whenToSeekMedicalHelp: json['when_to_seek_medical_help'],
      overallRiskLevel: json['overall_risk_level'],
      riskFactorsIdentified: List<String>.from(json['risk_factors_identified'] ?? []),
      monitoringRequirements: json['monitoring_requirements'],
      nextReviewDate: _parseDate(json['next_review_date']),
      status: json['status'] ?? 'draft',
      signature: json['signature'],
      reviewedBy: json['reviewed_by'],
      reviewedAt: _parseDate(json['reviewed_at']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'service_user_id': serviceUserId,
      'assessor_id': assessorId,
      'diabetes_type': diabetesType,
      'diabetes_type_other': diabetesTypeOther,
      'diagnosis_date': diagnosisDate?.toIso8601String().split('T').first,
      'last_hba1c_value': lastHba1cValue,
      'last_hba1c_date': lastHba1cDate?.toIso8601String().split('T').first,
      'hba1c_target': hba1cTarget,
      'bg_monitoring_frequency': bgMonitoringFrequency,
      'bg_monitoring_method': bgMonitoringMethod,
      'cgm_device_name': cgmDeviceName,
      'cgm_target_range_low': cgmTargetRangeLow,
      'cgm_target_range_high': cgmTargetRangeHigh,
      'insulin_regime': insulinRegime,
      'insulin_type': insulinType,
      'insulin_dose_details': insulinDoseDetails,
      'oral_medications': oralMedications,
      'other_medications': otherMedications,
      'hypoglycaemia_frequency': hypoglycaemiaFrequency,
      'hypoglycaemia_symptoms_recognized': hypoglycaemiaSymptomsRecognized,
      'hypoglycaemia_severe_episodes': hypoglycaemiaSevereEpisodes,
      'hypoglycaemia_unawareness': hypoglycaemiaUnawareness,
      'hyperglycaemia_episodes': hyperglycaemiaEpisodes,
      'hyperglycaemia_ketoacidosis': hyperglycaemiaKetoacidosis,
      'hyperglycaemia_hyperosmolar': hyperglycaemiaHyperosmolar,
      'foot_care_assessment_date': footCareAssessmentDate?.toIso8601String().split('T').first,
      'foot_care_assessment_result': footCareAssessmentResult,
      'foot_care_assessment_details': footCareAssessmentDetails,
      'foot_care_reminder_date': footCareReminderDate?.toIso8601String().split('T').first,
      'footwear_assessment': footwearAssessment,
      'nail_care_assessment': nailCareAssessment,
      'eye_screening_date': eyeScreeningDate?.toIso8601String().split('T').first,
      'eye_screening_result': eyeScreeningResult,
      'eye_screening_details': eyeScreeningDetails,
      'dietary_management': dietaryManagement,
      'dietary_management_details': dietaryManagementDetails,
      'exercise_level': exerciseLevel,
      'exercise_frequency': exerciseFrequency,
      'smoking_status': smokingStatus,
      'alcohol_consumption': alcoholConsumption,
      'hospital_admissions_last_year': hospitalAdmissionsLastYear,
      'hospital_admission_reasons': hospitalAdmissionReasons,
      'diabetes_complications': diabetesComplications,
      'other_health_conditions': otherHealthConditions,
      'sick_day_rules_knowledge': sickDayRulesKnowledge,
      'sick_day_rules_documented': sickDayRulesDocumented,
      'sick_day_rules_details': sickDayRulesDetails,
      'ketone_testing_knowledge': ketoneTestingKnowledge,
      'when_to_seek_medical_help': whenToSeekMedicalHelp,
      'overall_risk_level': overallRiskLevel,
      'risk_factors_identified': riskFactorsIdentified,
      'monitoring_requirements': monitoringRequirements,
      'next_review_date': nextReviewDate?.toIso8601String().split('T').first,
      'status': status,
      'signature': signature,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
    
    if (id != null && id!.isNotEmpty) {
      map['id'] = id;
    }
    
    return map;
  }

  // --- Display helpers ---
  String getDiabetesTypeDisplay() {
    switch (diabetesType) {
      case 'type1': return 'Type 1';
      case 'type2': return 'Type 2';
      case 'gestational': return 'Gestational';
      case 'prediabetes': return 'Pre-diabetes';
      case 'other': return 'Other (${diabetesTypeOther ?? 'Unknown'})';
      default: return diabetesType;
    }
  }

  String getBgMonitoringFrequencyDisplay() {
    switch (bgMonitoringFrequency) {
      case 'multiple_daily': return 'Multiple times daily';
      case 'daily': return 'Daily';
      case 'weekly': return 'Weekly';
      case 'occasionally': return 'Occasionally';
      case 'not_monitoring': return 'Not monitoring';
      default: return bgMonitoringFrequency;
    }
  }

  String getHypoglycaemiaFrequencyDisplay() {
    switch (hypoglycaemiaFrequency) {
      case 'never': return 'Never';
      case 'rarely': return 'Rarely';
      case 'monthly': return 'Monthly';
      case 'weekly': return 'Weekly';
      case 'daily': return 'Daily';
      case 'multiple_daily': return 'Multiple times daily';
      default: return 'Not specified';
    }
  }

  String getRiskLevelDisplay() {
    switch (overallRiskLevel) {
      case 'low': return 'Low';
      case 'medium': return 'Medium';
      case 'high': return 'High';
      case 'critical': return 'Critical';
      default: return 'Not assessed';
    }
  }

  // --- Computed properties ---
  bool get isHighRisk => overallRiskLevel == 'high' || overallRiskLevel == 'critical';
  bool get isHighRiskHba1c => lastHba1cValue != null && lastHba1cValue! > 58;
  bool get isFrequentHypoglycaemia => hypoglycaemiaFrequency == 'daily' || hypoglycaemiaFrequency == 'multiple_daily';
  bool get hasFootComplications => footCareAssessmentResult == 'reduced_sensation' || footCareAssessmentResult == 'ulceration' || footCareAssessmentResult == 'amputation';
  bool get hasEyeComplications => eyeScreeningResult == 'preproliferative' || eyeScreeningResult == 'proliferative' || eyeScreeningResult == 'maculopathy';
  bool get hasFrequentHospitalAdmissions => hospitalAdmissionsLastYear > 2;
  bool get needsReview => nextReviewDate != null && nextReviewDate!.isBefore(DateTime.now());

  // --- copyWith ---
  DiabetesAssessment copyWith({
    String? id,
    String? serviceUserId,
    String? assessorId,
    String? diabetesType,
    String? diabetesTypeOther,
    DateTime? diagnosisDate,
    double? lastHba1cValue,
    DateTime? lastHba1cDate,
    double? hba1cTarget,
    String? bgMonitoringFrequency,
    String? bgMonitoringMethod,
    String? cgmDeviceName,
    double? cgmTargetRangeLow,
    double? cgmTargetRangeHigh,
    String? insulinRegime,
    String? insulinType,
    String? insulinDoseDetails,
    List<String>? oralMedications,
    List<String>? otherMedications,
    String? hypoglycaemiaFrequency,
    bool? hypoglycaemiaSymptomsRecognized,
    int? hypoglycaemiaSevereEpisodes,
    bool? hypoglycaemiaUnawareness,
    String? hyperglycaemiaEpisodes,
    bool? hyperglycaemiaKetoacidosis,
    bool? hyperglycaemiaHyperosmolar,
    DateTime? footCareAssessmentDate,
    String? footCareAssessmentResult,
    String? footCareAssessmentDetails,
    DateTime? footCareReminderDate,
    bool? footwearAssessment,
    bool? nailCareAssessment,
    DateTime? eyeScreeningDate,
    String? eyeScreeningResult,
    String? eyeScreeningDetails,
    String? dietaryManagement,
    String? dietaryManagementDetails,
    String? exerciseLevel,
    String? exerciseFrequency,
    String? smokingStatus,
    String? alcoholConsumption,
    int? hospitalAdmissionsLastYear,
    List<String>? hospitalAdmissionReasons,
    List<String>? diabetesComplications,
    List<String>? otherHealthConditions,
    bool? sickDayRulesKnowledge,
    bool? sickDayRulesDocumented,
    String? sickDayRulesDetails,
    bool? ketoneTestingKnowledge,
    String? whenToSeekMedicalHelp,
    String? overallRiskLevel,
    List<String>? riskFactorsIdentified,
    String? monitoringRequirements,
    DateTime? nextReviewDate,
    String? status,
    String? signature,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiabetesAssessment(
      id: id ?? this.id,
      serviceUserId: serviceUserId ?? this.serviceUserId,
      assessorId: assessorId ?? this.assessorId,
      diabetesType: diabetesType ?? this.diabetesType,
      diabetesTypeOther: diabetesTypeOther ?? this.diabetesTypeOther,
      diagnosisDate: diagnosisDate ?? this.diagnosisDate,
      lastHba1cValue: lastHba1cValue ?? this.lastHba1cValue,
      lastHba1cDate: lastHba1cDate ?? this.lastHba1cDate,
      hba1cTarget: hba1cTarget ?? this.hba1cTarget,
      bgMonitoringFrequency: bgMonitoringFrequency ?? this.bgMonitoringFrequency,
      bgMonitoringMethod: bgMonitoringMethod ?? this.bgMonitoringMethod,
      cgmDeviceName: cgmDeviceName ?? this.cgmDeviceName,
      cgmTargetRangeLow: cgmTargetRangeLow ?? this.cgmTargetRangeLow,
      cgmTargetRangeHigh: cgmTargetRangeHigh ?? this.cgmTargetRangeHigh,
      insulinRegime: insulinRegime ?? this.insulinRegime,
      insulinType: insulinType ?? this.insulinType,
      insulinDoseDetails: insulinDoseDetails ?? this.insulinDoseDetails,
      oralMedications: oralMedications ?? this.oralMedications,
      otherMedications: otherMedications ?? this.otherMedications,
      hypoglycaemiaFrequency: hypoglycaemiaFrequency ?? this.hypoglycaemiaFrequency,
      hypoglycaemiaSymptomsRecognized: hypoglycaemiaSymptomsRecognized ?? this.hypoglycaemiaSymptomsRecognized,
      hypoglycaemiaSevereEpisodes: hypoglycaemiaSevereEpisodes ?? this.hypoglycaemiaSevereEpisodes,
      hypoglycaemiaUnawareness: hypoglycaemiaUnawareness ?? this.hypoglycaemiaUnawareness,
      hyperglycaemiaEpisodes: hyperglycaemiaEpisodes ?? this.hyperglycaemiaEpisodes,
      hyperglycaemiaKetoacidosis: hyperglycaemiaKetoacidosis ?? this.hyperglycaemiaKetoacidosis,
      hyperglycaemiaHyperosmolar: hyperglycaemiaHyperosmolar ?? this.hyperglycaemiaHyperosmolar,
      footCareAssessmentDate: footCareAssessmentDate ?? this.footCareAssessmentDate,
      footCareAssessmentResult: footCareAssessmentResult ?? this.footCareAssessmentResult,
      footCareAssessmentDetails: footCareAssessmentDetails ?? this.footCareAssessmentDetails,
      footCareReminderDate: footCareReminderDate ?? this.footCareReminderDate,
      footwearAssessment: footwearAssessment ?? this.footwearAssessment,
      nailCareAssessment: nailCareAssessment ?? this.nailCareAssessment,
      eyeScreeningDate: eyeScreeningDate ?? this.eyeScreeningDate,
      eyeScreeningResult: eyeScreeningResult ?? this.eyeScreeningResult,
      eyeScreeningDetails: eyeScreeningDetails ?? this.eyeScreeningDetails,
      dietaryManagement: dietaryManagement ?? this.dietaryManagement,
      dietaryManagementDetails: dietaryManagementDetails ?? this.dietaryManagementDetails,
      exerciseLevel: exerciseLevel ?? this.exerciseLevel,
      exerciseFrequency: exerciseFrequency ?? this.exerciseFrequency,
      smokingStatus: smokingStatus ?? this.smokingStatus,
      alcoholConsumption: alcoholConsumption ?? this.alcoholConsumption,
      hospitalAdmissionsLastYear: hospitalAdmissionsLastYear ?? this.hospitalAdmissionsLastYear,
      hospitalAdmissionReasons: hospitalAdmissionReasons ?? this.hospitalAdmissionReasons,
      diabetesComplications: diabetesComplications ?? this.diabetesComplications,
      otherHealthConditions: otherHealthConditions ?? this.otherHealthConditions,
      sickDayRulesKnowledge: sickDayRulesKnowledge ?? this.sickDayRulesKnowledge,
      sickDayRulesDocumented: sickDayRulesDocumented ?? this.sickDayRulesDocumented,
      sickDayRulesDetails: sickDayRulesDetails ?? this.sickDayRulesDetails,
      ketoneTestingKnowledge: ketoneTestingKnowledge ?? this.ketoneTestingKnowledge,
      whenToSeekMedicalHelp: whenToSeekMedicalHelp ?? this.whenToSeekMedicalHelp,
      overallRiskLevel: overallRiskLevel ?? this.overallRiskLevel,
      riskFactorsIdentified: riskFactorsIdentified ?? this.riskFactorsIdentified,
      monitoringRequirements: monitoringRequirements ?? this.monitoringRequirements,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      status: status ?? this.status,
      signature: signature ?? this.signature,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Other helpers
  bool get isComplete {
    return diabetesType.isNotEmpty &&
        bgMonitoringFrequency.isNotEmpty &&
        overallRiskLevel != null &&
        status.isNotEmpty;
  }
}