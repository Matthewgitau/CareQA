// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceUser _$ServiceUserFromJson(Map<String, dynamic> json) => ServiceUser(
      id: json['id'] as String,
      clientOrganisationId: json['client_organisation_id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      address: json['address'] as String?,
      carePlan: json['care_plan'] as String?,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ServiceUserToJson(ServiceUser instance) => <String, dynamic>{
      'id': instance.id,
      'client_organisation_id': instance.clientOrganisationId,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'address': instance.address,
      'care_plan': instance.carePlan,
      'notes': instance.notes,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };