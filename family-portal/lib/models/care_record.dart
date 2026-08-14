import 'package:flutter/material.dart';

class CareRecord {
  final String id;
  final String serviceUserId;
  final String type;
  final String title;
  final String? description;
  final DateTime date;
  final String? staffName;
  final String organisationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CareRecord({
    required this.id,
    required this.serviceUserId,
    required this.type,
    required this.title,
    this.description,
    required this.date,
    this.staffName,
    required this.organisationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CareRecord.fromJson(Map<String, dynamic> json) {
    return CareRecord(
      id: json['id'],
      serviceUserId: json['service_user_id'],
      type: json['type'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      staffName: json['staff_name'],
      organisationId: json['organisation_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_user_id': serviceUserId,
      'type': type,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'staff_name': staffName,
      'organisation_id': organisationId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}