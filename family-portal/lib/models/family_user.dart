import 'package:flutter/material.dart';

class FamilyUser {
  final String id;
  final String fullName;
  final String email;
  final String serviceUserId;
  final String organisationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  FamilyUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.serviceUserId,
    required this.organisationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FamilyUser.fromJson(Map<String, dynamic> json) {
    return FamilyUser(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      serviceUserId: json['service_user_id'],
      organisationId: json['organisation_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'service_user_id': serviceUserId,
      'organisation_id': organisationId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}