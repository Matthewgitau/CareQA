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
  final String hypoglycaemiaFrequency;
  final bool hypoglycaemiaSymptomsRecognized;
  final int hypoglycaemiaSevereEpisodes;
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
  
  // Eye Care Assessment
  final DateTime? eyeScreeningDate;
  final String? eyeScreeningResult;
  final String? eyeScreeningDetails;
  
  // Lifestyle Assessment
  final String? dietaryManagement;
  final String? dietaryManagementDetails;
  final String? exerciseLevel;
  final String? exerciseFrequency;
  final String? smokingStatus;
  final String? alcoholConsumption;
  
  // Hospital and Complications
  final int hospitalAdmissionsLastYear;
  final List<String> hospitalAdmissionReasons;
  final List<String> diabetesComplications;
  final List<String> otherHealthConditions;
  
  // Sick Day Rules
  final bool sickDayRulesKnowledge;
  final bool sickDayRulesDocumented;
  final String? sickDayRulesDetails;
  final bool ketoneTestingKnowledge;
  final String? whenToSeekMedicalHelp;
  
  // Assessment Metadata
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
    required this.oralMedications,
    required this.otherMedications,
    required this.hypoglycaemiaFrequency,
    required this.hypoglycaemiaSymptomsRecognized,
    required this.hypoglycaemiaSevereEpisodes,
    required this.hypoglycaemiaUnawareness,
    this.hyperglycaemiaEpisodes,
    required this.hyperglycaemiaKetoacidosis,
    required this.hyperglycaemiaHyperosmolar,
    this.footCareAssessmentDate,
    this.footCareAssessmentResult,
    this.footCareAssessmentDetails,
    this.footCareReminderDate,
    required this.footwearAssessment,
    required this.nailCareAssessment,
    this.eyeScreeningDate,
    this.eyeScreeningResult,
    this.eyeScreeningDetails,
    this.dietaryManagement,
    this.dietaryManagementDetails,
    this.exerciseLevel,
    this.exerciseFrequency,
    this.smokingStatus,
    this.alcoholConsumption,
    required this.hospitalAdmissionsLastYear,
    required this.hospitalAdmissionReasons,
    required this.diabetesComplications,
    required this.otherHealthConditions,
    required this.sickDayRulesKnowledge,
    required this.sickDayRulesDocumented,
    this.sickDayRulesDetails,
    required this.ketoneTestingKnowledge,
    this.whenToSeekMedicalHelp,
    this.overallRiskLevel,
    required this.riskFactorsIdentified,
    this.monitoringRequirements,
    this.nextReviewDate,
    required this.status,
    this.signature,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiabetesAssessment.fromJson(Map<String, dynamic> json) {
    return DiabetesAssessment(
      id: json['id'],
      serviceUserId: json['service_user_id'],
      assessorId: json['assessor_id'],
      diabetesType: json['diabetes_type'],
      diabetesTypeOther: json['diabetes_type_other'],
      diagnosisDate: json['diagnosis_date'] != null ? DateTime.parse(json['diagnosis_date']) : null,
      lastHba1cValue: json['last_hba1c_value'],
      lastHba1cDate: json['last_hba1c_date'] != null ? DateTime.parse(json['last_hba1c_date']) : null,
      hba1cTarget: json['hba1c_target'],
      bgMonitoringFrequency: json['bg_monitoring_frequency'],
      bgMonitoringMethod: json['bg_monitoring_method'],
      cgmDeviceName: json['cgm_device_name'],
      cgmTargetRangeLow: json['cgm_target_range_low'],
      cgmTargetRangeHigh: json['cgm_target_range_high'],
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
      footCareAssessmentDate: json['foot_care_assessment_date'] != null ? DateTime.parse(json['foot_care_assessment_date']) : null,
      footCareAssessmentResult: json['foot_care_assessment_result'],
      footCareAssessmentDetails: json['foot_care_assessment_details'],
      footCareReminderDate: json['foot_care_reminder_date'] != null ? DateTime.parse(json['foot_care_reminder_date']) : null,
      footwearAssessment: json['footwear_assessment'] ?? false,
      nailCareAssessment: json['nail_care_assessment'] ?? false,
      eyeScreeningDate: json['eye_screening_date'] != null ? DateTime.parse(json['eye_screening_date']) : null,
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
      nextReviewDate: json['next_review_date'] != null ? DateTime.parse(json['next_review_date']) : null,
      status: json['status'] ?? 'draft',
      signature: json['signature'],
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_user_id': serviceUserId,
      'assessor_id': assessorId,
      'diabetes_type': diabetesType,
      'diabetes_type_other': diabetesTypeOther,
      'diagnosis_date': diagnosisDate?.toIso8601String(),
      'last_hba1c_value': lastHba1cValue,
      'last_hba1c_date': lastHba1cDate?.toIso8601String(),
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
      'foot_care_assessment_date': footCareAssessmentDate?.toIso8601String(),
      'foot_care_assessment_result': footCareAssessmentResult,
      'foot_care_assessment_details': footCareAssessmentDetails,
      'foot_care_reminder_date': footCareReminderDate?.toIso8601String(),
      'footwear_assessment': footwearAssessment,
      'nail_care_assessment': nailCareAssessment,
      'eye_screening_date': eyeScreeningDate?.toIso8601String(),
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
      'next_review_date': nextReviewDate?.toIso8601String(),
      'status': status,
      'signature': signature,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods for business logic
  String getDiabetesTypeDisplay() {
    switch (diabetesType) {
      case 'type1':
        return 'Type 1 Diabetes';
      case 'type2':
        return 'Type 2 Diabetes';
      case 'gestational':
        return 'Gestational Diabetes';
      case 'other':
        return diabetesTypeOther ?? 'Other Type';
      default:
        return 'Unknown';
    }
  }

  String getBgMonitoringFrequencyDisplay() {
    switch (bgMonitoringFrequency) {
      case 'multiple_daily':
        return 'Multiple times daily';
      case 'once_daily':
        return 'Once daily';
      case 'few_times_week':
        return 'Few times per week';
      case 'occasionally':
        return 'Occasionally';
      case 'none':
        return 'None';
      default:
        return 'Unknown';
    }
  }

  String getInsulinRegimeDisplay() {
    switch (insulinRegime) {
      case 'basal_bolus':
        return 'Basal-Bolus (Multiple Daily Injections)';
      case 'premixed':
        return 'Premixed Insulin';
      case 'basal_only':
        return 'Basal Only';
      case 'pump':
        return 'Insulin Pump';
      case 'none':
        return 'No Insulin';
      default:
        return 'Unknown';
    }
  }

  String getHypoglycaemiaFrequencyDisplay() {
    switch (hypoglycaemiaFrequency) {
      case 'none':
        return 'None';
      case 'monthly':
        return 'Monthly';
      case 'weekly':
        return 'Weekly';
      case 'daily':
        return 'Daily';
      case 'multiple_daily':
        return 'Multiple times daily';
      default:
        return 'Unknown';
    }
  }

  String getFootCareResultDisplay() {
    switch (footCareAssessmentResult) {
      case 'normal':
        return 'Normal';
      case 'reduced_sensation':
        return 'Reduced Sensation';
      case 'ulceration':
        return 'Ulceration';
      case 'amputation':
        return 'Amputation';
      case 'other':
        return 'Other';
      default:
        return 'Unknown';
    }
  }

  String getEyeScreeningResultDisplay() {
    switch (eyeScreeningResult) {
      case 'normal':
        return 'Normal';
      case 'background_retinopathy':
        return 'Background Retinopathy';
      case 'preproliferative':
        return 'Preproliferative';
      case 'proliferative':
        return 'Proliferative';
      case 'maculopathy':
        return 'Maculopathy';
      case 'other':
        return 'Other';
      default:
        return 'Unknown';
    }
  }

  String getExerciseLevelDisplay() {
    switch (exerciseLevel) {
      case 'sedentary':
        return 'Sedentary';
      case 'light':
        return 'Light Activity';
      case 'moderate':
        return 'Moderate Activity';
      case 'active':
        return 'Active';
      case 'very_active':
        return 'Very Active';
      default:
        return 'Unknown';
    }
  }

  String getSmokingStatusDisplay() {
    switch (smokingStatus) {
      case 'non_smoker':
        return 'Non-smoker';
      case 'current_smoker':
        return 'Current Smoker';
      case 'ex_smoker':
        return 'Ex-smoker';
      default:
        return 'Unknown';
    }
  }

  String getAlcoholConsumptionDisplay() {
    switch (alcoholConsumption) {
      case 'none':
        return 'None';
      case 'occasional':
        return 'Occasional';
      case 'moderate':
        return 'Moderate';
      case 'heavy':
        return 'Heavy';
      default:
        return 'Unknown';
    }
  }

  // Risk calculation methods
  bool get isHighRiskHba1c => lastHba1cValue != null && lastHba1cValue! > 58.0;
  bool get isModerateRiskHba1c => lastHba1cValue != null && lastHba1cValue! > 53.0 && lastHba1cValue! <= 58.0;
  bool get isFrequentHypoglycaemia => hypoglycaemiaFrequency == 'daily' || hypoglycaemiaFrequency == 'multiple_daily';
  bool get hasFootComplications => footCareAssessmentResult != null && 
      ['reduced_sensation', 'ulceration', 'amputation'].contains(footCareAssessmentResult);
  bool get hasEyeComplications => eyeScreeningResult != null && 
      ['preproliferative', 'proliferative', 'maculopathy'].contains(eyeScreeningResult);
  bool get hasFrequentHospitalAdmissions => hospitalAdmissionsLastYear > 2;

  // Validation methods
  bool get isComplete {
    return diabetesType.isNotEmpty &&
           bgMonitoringFrequency.isNotEmpty &&
           hypoglycaemiaFrequency.isNotEmpty &&
           overallRiskLevel != null &&
           nextReviewDate != null;
  }

  String getCompletionStatus() {
    if (isComplete) return 'Complete';
    return 'Incomplete';
  }

  // Common options for dropdowns
  static List<String> getDiabetesTypes() => ['type1', 'type2', 'gestational', 'other'];
  static List<String> getBgMonitoringFrequencies() => ['multiple_daily', 'once_daily', 'few_times_week', 'occasionally', 'none'];
  static List<String> getBgMonitoringMethods() => ['finger_prick', 'cgm', 'both'];
  static List<String> getInsulinRegimes() => ['basal_bolus', 'premixed', 'basal_only', 'pump', 'none'];
  static List<String> getHypoglycaemiaFrequencies() => ['none', 'monthly', 'weekly', 'daily', 'multiple_daily'];
  static List<String> getHyperglycaemiaEpisodes() => ['none', 'occasional', 'frequent', 'always'];
  static List<String> getFootCareResults() => ['normal', 'reduced_sensation', 'ulceration', 'amputation', 'other'];
  static List<String> getEyeScreeningResults() => ['normal', 'background_retinopathy', 'preproliferative', 'proliferative', 'maculopathy', 'other'];
  static List<String> getDietaryManagements() => ['diet_controlled', 'carb_counting', 'meal_planning', 'dietitian_input', 'other'];
  static List<String> getExerciseLevels() => ['sedentary', 'light', 'moderate', 'active', 'very_active'];
  static List<String> getSmokingStatuses() => ['non_smoker', 'current_smoker', 'ex_smoker'];
  static List<String> getAlcoholConsumptions() => ['none', 'occasional', 'moderate', 'heavy'];
  static List<String> getRiskLevels() => ['low', 'medium', 'high'];
  static List<String> getDiabetesComplications() => [
    'neuropathy', 'retinopathy', 'nephropathy', 'cardiovascular_disease', 
    'stroke', 'peripheral_vascular_disease', 'foot_ulcers', 'infections'
  ];

  // Factory method for creating a new assessment
  static DiabetesAssessment createNew(String serviceUserId, String? assessorId) {
    return DiabetesAssessment(
      serviceUserId: serviceUserId,
      assessorId: assessorId,
      diabetesType: 'type2', // Default to type 2
      bgMonitoringFrequency: 'multiple_daily', // Default to multiple daily
      hypoglycaemiaFrequency: 'none', // Default to none
      oralMedications: [],
      otherMedications: [],
      hypoglycaemiaSymptomsRecognized: true,
      hypoglycaemiaSevereEpisodes: 0,
      hypoglycaemiaUnawareness: false,
      hyperglycaemiaKetoacidosis: false,
      hyperglycaemiaHyperosmolar: false,
      footwearAssessment: false,
      nailCareAssessment: false,
      hospitalAdmissionsLastYear: 0,
      hospitalAdmissionReasons: [],
      diabetesComplications: [],
      otherHealthConditions: [],
      sickDayRulesKnowledge: false,
      sickDayRulesDocumented: false,
      ketoneTestingKnowledge: false,
      riskFactorsIdentified: [],
      status: 'draft',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}