// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Route _$RouteFromJson(Map<String, dynamic> json) => Route(
      id: json['id'] as String,
      clientOrganisationId: json['client_organisation_id'] as String,
      serviceUserId: json['service_user_id'] as String,
      carerId: json['carer_id'] as String?,
      proposedStartTime: DateTime.parse(json['proposed_start_time'] as String),
      proposedEndTime: DateTime.parse(json['proposed_end_time'] as String),
      actualStartTime: json['actual_start_time'] == null
          ? null
          : DateTime.parse(json['actual_start_time'] as String),
      actualEndTime: json['actual_end_time'] == null
          ? null
          : DateTime.parse(json['actual_end_time'] as String),
      respite: json['respite'] as bool? ?? false,
      callNumber: json['call_number'] as int,
      status: $enumDecode(_$RouteStatusEnumMap, json['status']),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$RouteToJson(Route instance) => <String, dynamic>{
      'id': instance.id,
      'client_organisation_id': instance.clientOrganisationId,
      'service_user_id': instance.serviceUserId,
      'carer_id': instance.carerId,
      'proposed_start_time': instance.proposedStartTime.toIso8601String(),
      'proposed_end_time': instance.proposedEndTime.toIso8601String(),
      'actual_start_time': instance.actualStartTime?.toIso8601String(),
      'actual_end_time': instance.actualEndTime?.toIso8601String(),
      'respite': instance.respite,
      'call_number': instance.callNumber,
      'status': _$RouteStatusEnumMap[instance.status]!,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$RouteStatusEnumMap = {
  RouteStatus.scheduled: 'scheduled',
  RouteStatus.inProgress: 'in_progress',
  RouteStatus.completed: 'completed',
  RouteStatus.cancelled: 'cancelled',
};