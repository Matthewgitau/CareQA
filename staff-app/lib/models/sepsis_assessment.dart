import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class SepsisAssessment {
  final String? id;
  final String serviceUserId;
  final String? assessorId;
  final DateTime assessmentDate;
  final TimeOfDay assessmentTime;
  final double temperature;
  final int heartRate;
  final int respiratoryRate;
  final double oxygenSaturation;
  final int systolicBp;
  final ConsciousnessLevel consciousnessLevel;
  final int news2Score;
  final bool newConfusion;
  final List<String> signsOfInfection;
  final String? infectionSource;
  final bool patientUnwell;
  final bool familyConcerned;
  final SepsisRiskLevel sepsisRiskLevel;
  final ActionTaken actionTaken;
  final List<bool> sepsisSixCompleted;
  final Map<String, dynamic> sepsisSixDetails;
  final bool referralToHospital;
  final DateTime? referralTime;
  final String? hospitalOutcome;
  final String? assessorSignature;
  final DateTime? reviewTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  SepsisAssessment({
    this.id,
    required this.serviceUserId,
    this.assessorId,
    required this.assessmentDate,
    required this.assessmentTime,
    required this.temperature,
    required this.heartRate,
    required this.respiratoryRate,
    required this.oxygenSaturation,
    required this.systolicBp,
    required this.consciousnessLevel,
    required this.news2Score,
    required this.newConfusion,
    required this.signsOfInfection,
    this.infectionSource,
    required this.patientUnwell,
    required this.familyConcerned,
    required this.sepsisRiskLevel,
    required this.actionTaken,
    required this.sepsisSixCompleted,
    required this.sepsisSixDetails,
    required this.referralToHospital,
    this.referralTime,
    this.hospitalOutcome,
    this.assessorSignature,
    this.reviewTime,
    required this.createdAt,
    required this.updatedAt,
  });

  SepsisAssessment copyWith({
    String? id,
    String? serviceUserId,
    String? assessorId,
    DateTime? assessmentDate,
    TimeOfDay? assessmentTime,
    double? temperature,
    int? heartRate,
    int? respiratoryRate,
    double? oxygenSaturation,
    int? systolicBp,
    ConsciousnessLevel? consciousnessLevel,
    int? news2Score,
    bool? newConfusion,
    List<String>? signsOfInfection,
    String? infectionSource,
    bool? patientUnwell,
    bool? familyConcerned,
    SepsisRiskLevel? sepsisRiskLevel,
    ActionTaken? actionTaken,
    List<bool>? sepsisSixCompleted,
    Map<String, dynamic>? sepsisSixDetails,
    bool? referralToHospital,
    DateTime? referralTime,
    String? hospitalOutcome,
    String? assessorSignature,
    DateTime? reviewTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SepsisAssessment(
      id: id ?? this.id,
      serviceUserId: serviceUserId ?? this.serviceUserId,
      assessorId: assessorId ?? this.assessorId,
      assessmentDate: assessmentDate ?? this.assessmentDate,
      assessmentTime: assessmentTime ?? this.assessmentTime,
      temperature: temperature ?? this.temperature,
      heartRate: heartRate ?? this.heartRate,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      oxygenSaturation: oxygenSaturation ?? this.oxygenSaturation,
      systolicBp: systolicBp ?? this.systolicBp,
      consciousnessLevel: consciousnessLevel ?? this.consciousnessLevel,
      news2Score: news2Score ?? this.news2Score,
      newConfusion: newConfusion ?? this.newConfusion,
      signsOfInfection: signsOfInfection ?? this.signsOfInfection,
      infectionSource: infectionSource ?? this.infectionSource,
      patientUnwell: patientUnwell ?? this.patientUnwell,
      familyConcerned: familyConcerned ?? this.familyConcerned,
      sepsisRiskLevel: sepsisRiskLevel ?? this.sepsisRiskLevel,
      actionTaken: actionTaken ?? this.actionTaken,
      sepsisSixCompleted: sepsisSixCompleted ?? this.sepsisSixCompleted,
      sepsisSixDetails: sepsisSixDetails ?? this.sepsisSixDetails,
      referralToHospital: referralToHospital ?? this.referralToHospital,
      referralTime: referralTime ?? this.referralTime,
      hospitalOutcome: hospitalOutcome ?? this.hospitalOutcome,
      assessorSignature: assessorSignature ?? this.assessorSignature,
      reviewTime: reviewTime ?? this.reviewTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_user_id': serviceUserId,
      'assessor_id': assessorId,
      'assessment_date': assessmentDate.toIso8601String(),
      'assessment_time': assessmentTime.hour.toString().padLeft(2, '0') + ':' + assessmentTime.minute.toString().padLeft(2, '0'),
      'temperature': temperature,
      'heart_rate': heartRate,
      'respiratory_rate': respiratoryRate,
      'oxygen_saturation': oxygenSaturation,
      'systolic_bp': systolicBp,
      'consciousness_level': consciousnessLevel.toString().split('.').last,
      'news2_score': news2Score,
      'new_confusion': newConfusion,
      'signs_of_infection': signsOfInfection,
      'infection_source': infectionSource,
      'patient_unwell': patientUnwell,
      'family_concerned': familyConcerned,
      'sepsis_risk_level': sepsisRiskLevel.toString().split('.').last,
      'action_taken': actionTaken.toString().split('.').last,
      'sepsis_six_completed': sepsisSixCompleted,
      'sepsis_six_details': jsonEncode(sepsisSixDetails),
      'referral_to_hospital': referralToHospital,
      'referral_time': referralTime?.toIso8601String(),
      'hospital_outcome': hospitalOutcome,
      'assessor_signature': assessorSignature,
      'review_time': reviewTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SepsisAssessment.fromMap(Map<String, dynamic> map) {
    return SepsisAssessment(
      id: map['id'],
      serviceUserId: map['service_user_id'] ?? '',
      assessorId: map['assessor_id'],
      assessmentDate: DateTime.parse(map['assessment_date']),
      assessmentTime: TimeOfDay.fromDateTime(DateTime.parse(map['assessment_date'])),
      temperature: map['temperature']?.toDouble() ?? 0.0,
      heartRate: map['heart_rate']?.toInt() ?? 0,
      respiratoryRate: map['respiratory_rate']?.toInt() ?? 0,
      oxygenSaturation: map['oxygen_saturation']?.toDouble() ?? 0.0,
      systolicBp: map['systolic_bp']?.toInt() ?? 0,
      consciousnessLevel: _parseConsciousnessLevel(map['consciousness_level']),
      news2Score: map['news2_score']?.toInt() ?? 0,
      newConfusion: map['new_confusion'] ?? false,
      signsOfInfection: List<String>.from(map['signs_of_infection'] ?? []),
      infectionSource: map['infection_source'],
      patientUnwell: map['patient_unwell'] ?? false,
      familyConcerned: map['family_concerned'] ?? false,
      sepsisRiskLevel: _parseSepsisRiskLevel(map['sepsis_risk_level']),
      actionTaken: _parseActionTaken(map['action_taken']),
      sepsisSixCompleted: List<bool>.from(map['sepsis_six_completed'] ?? []),
      sepsisSixDetails: map['sepsis_six_details'] != null 
          ? jsonDecode(map['sepsis_six_details']) 
          : {},
      referralToHospital: map['referral_to_hospital'] ?? false,
      referralTime: map['referral_time'] != null ? DateTime.parse(map['referral_time']) : null,
      hospitalOutcome: map['hospital_outcome'],
      assessorSignature: map['assessor_signature'],
      reviewTime: map['review_time'] != null ? DateTime.parse(map['review_time']) : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  String toJson() => json.encode(toMap());

  factory SepsisAssessment.fromJson(String source) => SepsisAssessment.fromMap(json.decode(source));

  @override
  String toString() => 'SepsisAssessment(id: $id, serviceUserId: $serviceUserId, assessorId: $assessorId, assessmentDate: $assessmentDate, assessmentTime: $assessmentTime, temperature: $temperature, heartRate: $heartRate, respiratoryRate: $respiratoryRate, oxygenSaturation: $oxygenSaturation, systolicBp: $systolicBp, consciousnessLevel: $consciousnessLevel, news2Score: $news2Score, newConfusion: $newConfusion, signsOfInfection: $signsOfInfection, infectionSource: $infectionSource, patientUnwell: $patientUnwell, familyConcerned: $familyConcerned, sepsisRiskLevel: $sepsisRiskLevel, actionTaken: $actionTaken, sepsisSixCompleted: $sepsisSixCompleted, sepsisSixDetails: $sepsisSixDetails, referralToHospital: $referralToHospital, referralTime: $referralTime, hospitalOutcome: $hospitalOutcome, assessorSignature: $assessorSignature, reviewTime: $reviewTime, createdAt: $createdAt, updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is SepsisAssessment &&
      other.id == id &&
      other.serviceUserId == serviceUserId &&
      other.assessorId == assessorId &&
      other.assessmentDate == assessmentDate &&
      other.assessmentTime == assessmentTime &&
      other.temperature == temperature &&
      other.heartRate == heartRate &&
      other.respiratoryRate == respiratoryRate &&
      other.oxygenSaturation == oxygenSaturation &&
      other.systolicBp == systolicBp &&
      other.consciousnessLevel == consciousnessLevel &&
      other.news2Score == news2Score &&
      other.newConfusion == newConfusion &&
      listEquals(other.signsOfInfection, signsOfInfection) &&
      other.infectionSource == infectionSource &&
      other.patientUnwell == patientUnwell &&
      other.familyConcerned == familyConcerned &&
      other.sepsisRiskLevel == sepsisRiskLevel &&
      other.actionTaken == actionTaken &&
      listEquals(other.sepsisSixCompleted, sepsisSixCompleted) &&
      mapEquals(other.sepsisSixDetails, sepsisSixDetails) &&
      other.referralToHospital == referralToHospital &&
      other.referralTime == referralTime &&
      other.hospitalOutcome == hospitalOutcome &&
      other.assessorSignature == assessorSignature &&
      other.reviewTime == reviewTime &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => id.hashCode ^ serviceUserId.hashCode ^ assessorId.hashCode ^ assessmentDate.hashCode ^ assessmentTime.hashCode ^ temperature.hashCode ^ heartRate.hashCode ^ respiratoryRate.hashCode ^ oxygenSaturation.hashCode ^ systolicBp.hashCode ^ consciousnessLevel.hashCode ^ news2Score.hashCode ^ newConfusion.hashCode ^ signsOfInfection.hashCode ^ infectionSource.hashCode ^ patientUnwell.hashCode ^ familyConcerned.hashCode ^ sepsisRiskLevel.hashCode ^ actionTaken.hashCode ^ sepsisSixCompleted.hashCode ^ sepsisSixDetails.hashCode ^ referralToHospital.hashCode ^ referralTime.hashCode ^ hospitalOutcome.hashCode ^ assessorSignature.hashCode ^ reviewTime.hashCode ^ createdAt.hashCode ^ updatedAt.hashCode;

  // Helper methods for NEWS2 score calculation
  int calculateTemperatureScore() {
    if (temperature >= 36.1 && temperature <= 38.0) return 0;
    if (temperature >= 38.1 && temperature <= 39.0) return 1;
    return 2; // < 36.1 or > 39.0
  }

  int calculateHeartRateScore() {
    if (heartRate >= 51 && heartRate <= 90) return 0;
    if ((heartRate >= 41 && heartRate <= 50) || (heartRate >= 91 && heartRate <= 110)) return 1;
    if ((heartRate >= 111 && heartRate <= 130) || heartRate <= 40) return 2;
    return 3; // > 130
  }

  int calculateRespiratoryRateScore() {
    if (respiratoryRate >= 12 && respiratoryRate <= 20) return 0;
    if ((respiratoryRate >= 21 && respiratoryRate <= 24) || respiratoryRate <= 11) return 1;
    return 2; // >= 25
  }

  int calculateOxygenSaturationScore() {
    if (oxygenSaturation >= 96.0) return 0;
    if (oxygenSaturation >= 94.0 && oxygenSaturation <= 95.0) return 1;
    if (oxygenSaturation >= 92.0 && oxygenSaturation <= 93.0) return 2;
    return 3; // < 92.0
  }

  int calculateSystolicBpScore() {
    if (systolicBp >= 111 && systolicBp <= 219) return 0;
    if ((systolicBp >= 101 && systolicBp <= 110) || (systolicBp >= 220 && systolicBp <= 239)) return 1;
    if ((systolicBp >= 91 && systolicBp <= 100) || (systolicBp >= 240 && systolicBp <= 250)) return 2;
    return 3; // <= 90 or > 250
  }

  int calculateConsciousnessScore() {
    return consciousnessLevel == ConsciousnessLevel.alert ? 0 : 3;
  }

  int calculateNews2Score() {
    return calculateTemperatureScore() + 
           calculateHeartRateScore() + 
           calculateRespiratoryRateScore() + 
           calculateOxygenSaturationScore() + 
           calculateSystolicBpScore() + 
           calculateConsciousnessScore();
  }

  SepsisRiskLevel calculateSepsisRiskLevel() {
    final news2Score = calculateNews2Score();
    final hasInfectionSigns = signsOfInfection.isNotEmpty;
    
    // Critical risk: NEWS2 >= 7
    if (news2Score >= 7) return SepsisRiskLevel.critical;
    
    // High risk: NEWS2 >= 5 OR (new confusion + signs of infection)
    if (news2Score >= 5 || (newConfusion && hasInfectionSigns)) return SepsisRiskLevel.high;
    
    // Medium risk: NEWS2 = 3-4 OR patient looks unwell
    if (news2Score >= 3 || patientUnwell) return SepsisRiskLevel.medium;
    
    return SepsisRiskLevel.low;
  }

  ActionTaken determineActionTaken() {
    final riskLevel = calculateSepsisRiskLevel();
    if (riskLevel == SepsisRiskLevel.critical) return ActionTaken.call999;
    if (riskLevel == SepsisRiskLevel.high) return ActionTaken.escalate;
    return ActionTaken.monitor;
  }

  Map<String, dynamic> getSummary() {
    return {
      'assessment_date': assessmentDate,
      'assessment_time': assessmentTime.format(null),
      'news2_score': news2Score,
      'sepsis_risk_level': sepsisRiskLevel.toString().split('.').last,
      'action_taken': actionTaken.toString().split('.').last,
      'temperature': temperature,
      'heart_rate': heartRate,
      'respiratory_rate': respiratoryRate,
      'oxygen_saturation': oxygenSaturation,
      'systolic_bp': systolicBp,
      'consciousness_level': consciousnessLevel.toString().split('.').last,
      'new_confusion': newConfusion,
      'signs_of_infection': signsOfInfection,
      'infection_source': infectionSource,
      'patient_unwell': patientUnwell,
      'family_concerned': familyConcerned,
      'sepsis_six_completed': sepsisSixCompleted,
      'referral_to_hospital': referralToHospital,
      'hospital_outcome': hospitalOutcome,
    };
  }

  bool get isUrgent => news2Score >= 5;
  bool get isCritical => news2Score >= 7;
  bool get needsEscalation => news2Score >= 5 || (newConfusion && signsOfInfection.isNotEmpty);
  bool get needs999 => news2Score >= 7 || sepsisRiskLevel == SepsisRiskLevel.critical;

  static ConsciousnessLevel _parseConsciousnessLevel(String? value) {
    switch (value?.toLowerCase()) {
      case 'alert': return ConsciousnessLevel.alert;
      case 'voice': return ConsciousnessLevel.voice;
      case 'pain': return ConsciousnessLevel.pain;
      case 'unresponsive': return ConsciousnessLevel.unresponsive;
      default: return ConsciousnessLevel.alert;
    }
  }

  static SepsisRiskLevel _parseSepsisRiskLevel(String? value) {
    switch (value?.toLowerCase()) {
      case 'low': return SepsisRiskLevel.low;
      case 'medium': return SepsisRiskLevel.medium;
      case 'high': return SepsisRiskLevel.high;
      case 'critical': return SepsisRiskLevel.critical;
      default: return SepsisRiskLevel.low;
    }
  }

  static ActionTaken _parseActionTaken(String? value) {
    switch (value?.toLowerCase()) {
      case 'monitor': return ActionTaken.monitor;
      case 'escalate': return ActionTaken.escalate;
      case '999': return ActionTaken.call999;
      default: return ActionTaken.monitor;
    }
  }
}

enum ConsciousnessLevel {
  alert,
  voice,
  pain,
  unresponsive
}

enum SepsisRiskLevel {
  low,
  medium,
  high,
  critical
}

enum ActionTaken {
  monitor,
  escalate,
  call999
}