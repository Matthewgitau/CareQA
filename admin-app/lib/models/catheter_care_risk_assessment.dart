import 'package:flutter/material.dart';

class CatheterCareRiskAssessment {
  final String? id;
  final String serviceUserId;
  final String? assessorId;
  final DateTime assessmentDate;

  // Catheter Information
  final String? catheterType;
  final DateTime? insertionDate;
  final DateTime? nextChangeDate;
  final int? catheterSize;
  final int? balloonVolume;

  // Urine Monitoring
  final int? urineOutputMl;
  final String? urineAppearance;
  final String? urineOdour;

  // Infection Signs
  final double? feverCelsius;
  final int? painLevel;
  final String? painLocation;

  // Skin Condition
  final String? skinCondition;
  final String? skinConditionNotes;

  // Drainage System
  final String? drainageBagPosition;
  final bool? drainageBagSecure;

  // Risk Assessment
  final String? infectionRisk;
  final String? blockageRisk;
  final String? dislodgementRisk;
  final String? overallRiskLevel;

  // Patient Comfort
  final int? comfortLevel;
  final String? patientConcerns;

  // Staff & Review
  final bool? staffCompetencyVerified;
  final DateTime? reviewDate;
  final String? actionPlan;

  // Metadata
  final String? createdBy;
  final DateTime createdAt;
  final String? updatedBy;
  final DateTime updatedAt;

  CatheterCareRiskAssessment({
    this.id,
    required this.serviceUserId,
    this.assessorId,
    required this.assessmentDate,
    this.catheterType,
    this.insertionDate,
    this.nextChangeDate,
    this.catheterSize,
    this.balloonVolume,
    this.urineOutputMl,
    this.urineAppearance,
    this.urineOdour,
    this.feverCelsius,
    this.painLevel,
    this.painLocation,
    this.skinCondition,
    this.skinConditionNotes,
    this.drainageBagPosition,
    this.drainageBagSecure,
    this.infectionRisk,
    this.blockageRisk,
    this.dislodgementRisk,
    this.overallRiskLevel,
    this.comfortLevel,
    this.patientConcerns,
    this.staffCompetencyVerified,
    this.reviewDate,
    this.actionPlan,
    this.createdBy,
    required this.createdAt,
    this.updatedBy,
    required this.updatedAt,
  });

  factory CatheterCareRiskAssessment.fromJson(Map<String, dynamic> json) {
    return CatheterCareRiskAssessment(
      id: json['id'],
      serviceUserId: json['service_user_id'],
      assessorId: json['assessor_id'],
      assessmentDate: DateTime.parse(json['assessment_date']),
      catheterType: json['catheter_type'],
      insertionDate: json['insertion_date'] != null ? DateTime.parse(json['insertion_date']) : null,
      nextChangeDate: json['next_change_date'] != null ? DateTime.parse(json['next_change_date']) : null,
      catheterSize: json['catheter_size'],
      balloonVolume: json['balloon_volume'],
      urineOutputMl: json['urine_output_ml'],
      urineAppearance: json['urine_appearance'],
      urineOdour: json['urine_odour'],
      feverCelsius: json['fever_celsius'] != null ? double.tryParse(json['fever_celsius'].toString()) : null,
      painLevel: json['pain_level'],
      painLocation: json['pain_location'],
      skinCondition: json['skin_condition'],
      skinConditionNotes: json['skin_condition_notes'],
      drainageBagPosition: json['drainage_bag_position'],
      drainageBagSecure: json['drainage_bag_secure'],
      infectionRisk: json['infection_risk'],
      blockageRisk: json['blockage_risk'],
      dislodgementRisk: json['dislodgement_risk'],
      overallRiskLevel: json['overall_risk_level'],
      comfortLevel: json['comfort_level'],
      patientConcerns: json['patient_concerns'],
      staffCompetencyVerified: json['staff_competency_verified'],
      reviewDate: json['review_date'] != null ? DateTime.parse(json['review_date']) : null,
      actionPlan: json['action_plan'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedBy: json['updated_by'],
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'service_user_id': serviceUserId,
      'assessor_id': assessorId,
      'assessment_date': assessmentDate.toIso8601String().split('T')[0],
      'catheter_type': catheterType,
      'insertion_date': insertionDate?.toIso8601String().split('T')[0],
      'next_change_date': nextChangeDate?.toIso8601String().split('T')[0],
      'catheter_size': catheterSize,
      'balloon_volume': balloonVolume,
      'urine_output_ml': urineOutputMl,
      'urine_appearance': urineAppearance,
      'urine_odour': urineOdour,
      'fever_celsius': feverCelsius,
      'pain_level': painLevel,
      'pain_location': painLocation,
      'skin_condition': skinCondition,
      'skin_condition_notes': skinConditionNotes,
      'drainage_bag_position': drainageBagPosition,
      'drainage_bag_secure': drainageBagSecure,
      'infection_risk': infectionRisk,
      'blockage_risk': blockageRisk,
      'dislodgement_risk': dislodgementRisk,
      'overall_risk_level': overallRiskLevel,
      'comfort_level': comfortLevel,
      'patient_concerns': patientConcerns,
      'staff_competency_verified': staffCompetencyVerified,
      'review_date': reviewDate?.toIso8601String().split('T')[0],
      'action_plan': actionPlan,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'updated_at': updatedAt.toIso8601String(),
    };
    
    // Only include id for updates (not inserts)
    if (id != null && id!.isNotEmpty) {
      map['id'] = id;
    }
    
    return map;
  }

  // Helper methods for display
  String getCatheterTypeDisplay() {
    switch (catheterType) {
      case 'indwelling':
        return 'Indwelling (Foley)';
      case 'suprapubic':
        return 'Suprapubic';
      case 'intermittent':
        return 'Intermittent (CIC)';
      default:
        return 'Not specified';
    }
  }

  String getUrineAppearanceDisplay() {
    switch (urineAppearance) {
      case 'clear':
        return 'Clear';
      case 'cloudy':
        return 'Cloudy';
      case 'blood_stained':
        return 'Blood-stained';
      case 'dark':
        return 'Dark';
      default:
        return 'Not specified';
    }
  }

  String getUrineOdourDisplay() {
    switch (urineOdour) {
      case 'normal':
        return 'Normal';
      case 'foul':
        return 'Foul';
      case 'sweet':
        return 'Sweet';
      default:
        return 'Not specified';
    }
  }

  String getSkinConditionDisplay() {
    switch (skinCondition) {
      case 'intact':
        return 'Intact';
      case 'redness':
        return 'Redness';
      case 'rash':
        return 'Rash';
      case 'broken':
        return 'Broken';
      case 'infected':
        return 'Infected';
      default:
        return 'Not specified';
    }
  }

  String getDrainageBagPositionDisplay() {
    switch (drainageBagPosition) {
      case 'below_bladder':
        return 'Below Bladder (Correct)';
      case 'above_bladder':
        return 'Above Bladder (Incorrect)';
      case 'floor':
        return 'On Floor (Incorrect)';
      default:
        return 'Not specified';
    }
  }

  String getRiskLevelDisplay(String? risk) {
    switch (risk) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'critical':
        return 'Critical';
      default:
        return 'Not assessed';
    }
  }

  String getComfortLevelDisplay() {
    if (comfortLevel == null) return 'Not assessed';
    switch (comfortLevel) {
      case 1:
        return '1 - Very Uncomfortable';
      case 2:
        return '2 - Uncomfortable';
      case 3:
        return '3 - Neutral';
      case 4:
        return '4 - Comfortable';
      case 5:
        return '5 - Very Comfortable';
      default:
        return 'Not assessed';
    }
  }

  // Risk calculation methods
  bool get hasInfectionSigns {
    return (feverCelsius != null && feverCelsius! > 37.5) ||
        urineAppearance == 'cloudy' ||
        urineOdour == 'foul' ||
        skinCondition == 'infected';
  }

  bool get hasBlockageRisk {
    return urineOutputMl != null && urineOutputMl! < 400 ||
        catheterSize != null && catheterSize! > 16;
  }

  bool get hasDislodgementRisk {
    return drainageBagSecure == false ||
        drainageBagPosition == 'above_bladder' ||
        drainageBagPosition == 'floor';
  }

  bool get isHighRisk {
    return overallRiskLevel == 'high' || overallRiskLevel == 'critical';
  }

  // Validation methods
  bool get isComplete {
    return catheterType != null &&
        overallRiskLevel != null &&
        infectionRisk != null &&
        blockageRisk != null &&
        dislodgementRisk != null;
  }

  String getCompletionStatus() {
    if (isComplete) return 'Complete';
    return 'Incomplete';
  }

  // Common options for dropdowns
  static List<String> getCatheterTypes() => ['indwelling', 'suprapubic', 'intermittent'];
  static List<String> getUrineAppearances() => ['clear', 'cloudy', 'blood_stained', 'dark'];
  static List<String> getUrineOdours() => ['normal', 'foul', 'sweet'];
  static List<String> getSkinConditions() => ['intact', 'redness', 'rash', 'broken', 'infected'];
  static List<String> getDrainageBagPositions() => ['below_bladder', 'above_bladder', 'floor'];
  static List<String> getRiskLevels() => ['low', 'medium', 'high'];
  static List<String> getOverallRiskLevels() => ['low', 'medium', 'high', 'critical'];

  // Factory method for creating a new assessment
  factory CatheterCareRiskAssessment.createNew(String serviceUserId, String? assessorId) {
    return CatheterCareRiskAssessment(
      serviceUserId: serviceUserId,
      assessorId: assessorId,
      assessmentDate: DateTime.now(),
      drainageBagSecure: true,
      staffCompetencyVerified: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // CopyWith method for updating specific fields
  CatheterCareRiskAssessment copyWith({
    String? id,
    String? serviceUserId,
    String? assessorId,
    DateTime? assessmentDate,
    String? catheterType,
    DateTime? insertionDate,
    DateTime? nextChangeDate,
    int? catheterSize,
    int? balloonVolume,
    int? urineOutputMl,
    String? urineAppearance,
    String? urineOdour,
    double? feverCelsius,
    int? painLevel,
    String? painLocation,
    String? skinCondition,
    String? skinConditionNotes,
    String? drainageBagPosition,
    bool? drainageBagSecure,
    String? infectionRisk,
    String? blockageRisk,
    String? dislodgementRisk,
    String? overallRiskLevel,
    int? comfortLevel,
    String? patientConcerns,
    bool? staffCompetencyVerified,
    DateTime? reviewDate,
    String? actionPlan,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return CatheterCareRiskAssessment(
      id: id ?? this.id,
      serviceUserId: serviceUserId ?? this.serviceUserId,
      assessorId: assessorId ?? this.assessorId,
      assessmentDate: assessmentDate ?? this.assessmentDate,
      catheterType: catheterType ?? this.catheterType,
      insertionDate: insertionDate ?? this.insertionDate,
      nextChangeDate: nextChangeDate ?? this.nextChangeDate,
      catheterSize: catheterSize ?? this.catheterSize,
      balloonVolume: balloonVolume ?? this.balloonVolume,
      urineOutputMl: urineOutputMl ?? this.urineOutputMl,
      urineAppearance: urineAppearance ?? this.urineAppearance,
      urineOdour: urineOdour ?? this.urineOdour,
      feverCelsius: feverCelsius ?? this.feverCelsius,
      painLevel: painLevel ?? this.painLevel,
      painLocation: painLocation ?? this.painLocation,
      skinCondition: skinCondition ?? this.skinCondition,
      skinConditionNotes: skinConditionNotes ?? this.skinConditionNotes,
      drainageBagPosition: drainageBagPosition ?? this.drainageBagPosition,
      drainageBagSecure: drainageBagSecure ?? this.drainageBagSecure,
      infectionRisk: infectionRisk ?? this.infectionRisk,
      blockageRisk: blockageRisk ?? this.blockageRisk,
      dislodgementRisk: dislodgementRisk ?? this.dislodgementRisk,
      overallRiskLevel: overallRiskLevel ?? this.overallRiskLevel,
      comfortLevel: comfortLevel ?? this.comfortLevel,
      patientConcerns: patientConcerns ?? this.patientConcerns,
      staffCompetencyVerified: staffCompetencyVerified ?? this.staffCompetencyVerified,
      reviewDate: reviewDate ?? this.reviewDate,
      actionPlan: actionPlan ?? this.actionPlan,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}