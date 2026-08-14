import 'package:flutter/material.dart';

class BowelBladderChart {
  final String? id;
  final String serviceUserId;
  final String assessorId;
  final DateTime assessmentDate;
  final Map<String, dynamic> responses;  // Will store all bowel/bladder data
  final List<Map<String, dynamic>> actionPlan;
  final String? signature;
  final String status;
  final DateTime? createdAt;

  BowelBladderChart({
    this.id,
    required this.serviceUserId,
    required this.assessorId,
    required this.assessmentDate,
    this.responses = const {},
    this.actionPlan = const [],
    this.signature,
    this.status = 'draft',
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'service_user_id': serviceUserId,
    'assessor_id': assessorId,
    'assessment_date': assessmentDate.toIso8601String(),
    'responses': responses,
    'action_plan': actionPlan,
    'signature': signature,
    'status': status,
  };

  factory BowelBladderChart.fromJson(Map<String, dynamic> json) => BowelBladderChart(
    id: json['id'],
    serviceUserId: json['service_user_id'],
    assessorId: json['assessor_id'],
    assessmentDate: DateTime.parse(json['assessment_date']),
    responses: Map<String, dynamic>.from(json['responses'] ?? {}),
    actionPlan: List<Map<String, dynamic>>.from(json['action_plan'] ?? []),
    signature: json['signature'],
    status: json['status'] ?? 'draft',
    createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : null,
  );
}