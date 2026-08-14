import 'package:flutter/material.dart';

class ServiceUser {
  final String id;
  final String name;
  final String? address;
  final String? contactNumber;
  final String organisationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceUser({
    required this.id,
    required this.name,
    this.address,
    this.contactNumber,
    required this.organisationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceUser.fromJson(Map<String, dynamic> json) {
    return ServiceUser(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      contactNumber: json['contact_number'],
      organisationId: json['organisation_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'contact_number': contactNumber,
      'organisation_id': organisationId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}