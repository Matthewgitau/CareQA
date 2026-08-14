import 'package:flutter/material.dart';

class InspectorToken {
  final String id;
  final String serviceUserId;
  final String token;
  final DateTime expiresAt;
  final int maxViews;
  final int currentViews;
  final String organisationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  InspectorToken({
    required this.id,
    required this.serviceUserId,
    required this.token,
    required this.expiresAt,
    required this.maxViews,
    required this.currentViews,
    required this.organisationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InspectorToken.fromJson(Map<String, dynamic> json) {
    return InspectorToken(
      id: json['id'],
      serviceUserId: json['service_user_id'],
      token: json['token'],
      expiresAt: DateTime.parse(json['expires_at']),
      maxViews: json['max_views'],
      currentViews: json['current_views'],
      organisationId: json['organisation_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_user_id': serviceUserId,
      'token': token,
      'expires_at': expiresAt.toIso8601String(),
      'max_views': maxViews,
      'current_views': currentViews,
      'organisation_id': organisationId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}