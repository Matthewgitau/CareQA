import 'package:supabase_flutter/supabase_flutter.dart';

class ComplianceScore {
  final String id;
  final String carerId;
  final String? careHomeId;
  final DateTime scoreDate;
  final double? overallScore;
  final double? durationCompliance;
  final double? documentationCompliance;
  final double? medicationCompliance;
  final double? incidentReportingCompliance;
  final int? flagsCount;
  final DateTime createdAt;

  ComplianceScore({
    required this.id,
    required this.carerId,
    this.careHomeId,
    required this.scoreDate,
    this.overallScore,
    this.durationCompliance,
    this.documentationCompliance,
    this.medicationCompliance,
    this.incidentReportingCompliance,
    this.flagsCount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'carer_id': carerId,
      'care_home_id': careHomeId,
      'score_date': scoreDate,
      'overall_score': overallScore,
      'duration_compliance': durationCompliance,
      'documentation_compliance': documentationCompliance,
      'medication_compliance': medicationCompliance,
      'incident_reporting_compliance': incidentReportingCompliance,
      'flags_count': flagsCount,
      'created_at': createdAt,
    };
  }

  factory ComplianceScore.fromMap(Map<String, dynamic> map) {
    return ComplianceScore(
      id: map['id'] ?? '',
      carerId: map['carer_id'] ?? '',
      careHomeId: map['care_home_id'],
      scoreDate: (map['score_date'] as DateTime?) ?? DateTime.now(),
      overallScore: (map['overall_score'] as num?)?.toDouble(),
      durationCompliance: (map['duration_compliance'] as num?)?.toDouble(),
      documentationCompliance: (map['documentation_compliance'] as num?)?.toDouble(),
      medicationCompliance: (map['medication_compliance'] as num?)?.toDouble(),
      incidentReportingCompliance: (map['incident_reporting_compliance'] as num?)?.toDouble(),
      flagsCount: map['flags_count'] as int?,
      createdAt: (map['created_at'] as DateTime?) ?? DateTime.now(),
    );
  }
}