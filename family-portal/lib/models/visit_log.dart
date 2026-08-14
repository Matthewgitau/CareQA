import 'package:flutter/material.dart';
import 'service_user.dart';

class VisitLog {
  final String id;
  final String serviceUserId;
  final ServiceUser serviceUser;
  final String carerId;
  final String carerName;
  final DateTime visitStart;
  final DateTime visitEnd;
  final String? notes;
  final String organisationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  VisitLog({
    required this.id,
    required this.serviceUserId,
    required this.serviceUser,
    required this.carerId,
    required this.carerName,
    required this.visitStart,
    required this.visitEnd,
    this.notes,
    required this.organisationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VisitLog.fromJson(Map<String, dynamic> json) {
    return VisitLog(
      id: json['id'],
      serviceUserId: json['service_user_id'],
      serviceUser: ServiceUser.fromJson(json['service_user'] ?? {}),
      carerId: json['carer_id'],
      carerName: json['carer_name'],
      visitStart: DateTime.parse(json['visit_start']),
      visitEnd: DateTime.parse(json['visit_end']),
      notes: json['notes'],
      organisationId: json['organisation_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_user_id': serviceUserId,
      'service_user': serviceUser.toJson(),
      'carer_id': carerId,
      'carer_name': carerName,
      'visit_start': visitStart.toIso8601String(),
      'visit_end': visitEnd.toIso8601String(),
      'notes': notes,
      'organisation_id': organisationId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
