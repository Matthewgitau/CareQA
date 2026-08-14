// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Carer _$CarerFromJson(Map<String, dynamic> json) => Carer(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.parse(json['date_of_birth'] as String),
      address: json['address'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      qualifications: (json['qualifications'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      certifications: (json['certifications'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      availability: json['availability'] as Map<String, dynamic>?,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$CarerToJson(Carer instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'phone': instance.phone,
      'date_of_birth': instance.dateOfBirth?.toIso8601String(),
      'address': instance.address,
      'is_active': instance.isActive,
      'qualifications': instance.qualifications,
      'certifications': instance.certifications,
      'availability': instance.availability,
      'hourly_rate': instance.hourlyRate,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };