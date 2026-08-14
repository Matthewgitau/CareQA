import 'package:supabase_flutter/supabase_flutter.dart';

class Profile {
  final String id;
  final String email;
  final String? fullName;
  final String role;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'phone': phone,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['full_name'],
      role: map['role'] ?? 'carer',
      phone: map['phone'],
      createdAt: (map['created_at'] as DateTime?) ?? DateTime.now(),
      updatedAt: (map['updated_at'] as DateTime?) ?? DateTime.now(),
    );
  }
}