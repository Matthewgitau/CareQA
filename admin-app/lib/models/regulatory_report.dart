import 'package:supabase_flutter/supabase_flutter.dart';

class RegulatoryReport {
  final String id;
  final String reportType;
  final DateTime reportingPeriodStart;
  final DateTime reportingPeriodEnd;
  final Map<String, dynamic> reportData;
  final DateTime generatedAt;
  final String? generatedBy;
  final bool submitted;
  final DateTime? submittedAt;

  RegulatoryReport({
    required this.id,
    required this.reportType,
    required this.reportingPeriodStart,
    required this.reportingPeriodEnd,
    required this.reportData,
    required this.generatedAt,
    this.generatedBy,
    required this.submitted,
    this.submittedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'report_type': reportType,
      'reporting_period_start': reportingPeriodStart,
      'reporting_period_end': reportingPeriodEnd,
      'report_data': reportData,
      'generated_at': generatedAt,
      'generated_by': generatedBy,
      'submitted': submitted,
      'submitted_at': submittedAt,
    };
  }

  factory RegulatoryReport.fromMap(Map<String, dynamic> map) {
    return RegulatoryReport(
      id: map['id'] ?? '',
      reportType: map['report_type'] ?? '',
      reportingPeriodStart: (map['reporting_period_start'] as DateTime?) ?? DateTime.now(),
      reportingPeriodEnd: (map['reporting_period_end'] as DateTime?) ?? DateTime.now(),
      reportData: map['report_data'] as Map<String, dynamic> ?? {},
      generatedAt: (map['generated_at'] as DateTime?) ?? DateTime.now(),
      generatedBy: map['generated_by'],
      submitted: map['submitted'] ?? false,
      submittedAt: map['submitted_at'] as DateTime?,
    );
  }
}