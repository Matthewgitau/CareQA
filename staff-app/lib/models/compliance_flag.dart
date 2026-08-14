import 'package:supabase_flutter/supabase_flutter.dart';

class ComplianceFlag {
  final String id;
  final String? visitId;
  final String? carerId;
  final String? shiftId;
  final String? documentId;
  final String ruleId;
  final String ruleName;
  final String severity;
  final String status;
  final String message;
  final String? regulationReference;
  final String? suggestedAction;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  ComplianceFlag({
    required this.id,
    this.visitId,
    this.carerId,
    this.shiftId,
    this.documentId,
    required this.ruleId,
    required this.ruleName,
    required this.severity,
    required this.status,
    required this.message,
    this.regulationReference,
    this.suggestedAction,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'visit_id': visitId,
      'carer_id': carerId,
      'shift_id': shiftId,
      'document_id': documentId,
      'rule_id': ruleId,
      'rule_name': ruleName,
      'severity': severity,
      'status': status,
      'message': message,
      'regulation_reference': regulationReference,
      'suggested_action': suggestedAction,
      'acknowledged_by': acknowledgedBy,
      'acknowledged_at': acknowledgedAt,
      'resolved_by': resolvedBy,
      'resolved_at': resolvedAt,
      'created_at': createdAt,
    };
  }

  factory ComplianceFlag.fromMap(Map<String, dynamic> map) {
    return ComplianceFlag(
      id: map['id'] ?? '',
      visitId: map['visit_id'],
      carerId: map['carer_id'],
      shiftId: map['shift_id'],
      documentId: map['document_id'],
      ruleId: map['rule_id'] ?? '',
      ruleName: map['rule_name'] ?? '',
      severity: map['severity'] ?? 'INFO',
      status: map['status'] ?? 'active',
      message: map['message'] ?? '',
      regulationReference: map['regulation_reference'],
      suggestedAction: map['suggested_action'],
      acknowledgedBy: map['acknowledged_by'],
      acknowledgedAt: map['acknowledged_at'] as DateTime?,
      resolvedBy: map['resolved_by'],
      resolvedAt: map['resolved_at'] as DateTime?,
      createdAt: (map['created_at'] as DateTime?) ?? DateTime.now(),
    );
  }
}