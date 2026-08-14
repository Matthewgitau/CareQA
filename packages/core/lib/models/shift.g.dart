// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Shift _$ShiftFromJson(Map<String, dynamic> json) => Shift(
      id: json['id'] as String,
      clientId: json['client_id'] as String? ?? '',
      clientOrganisationId: json['client_organisation_id'] as String?,
      serviceUserId: json['service_user_id'] as String? ?? '',
      serviceUserName: json['service_users']?['name'] as String?,
      carerId: json['carer_id'] as String?,
      carerName: json['carers']?['name'] as String?,
      scheduledDate: json['scheduled_date'] == null
          ? DateTime.now()
          : DateTime.parse(json['scheduled_date'] as String),
      startTime: _parseTime(json['start_time'] as String?),
      endTime: _parseTime(json['end_time'] as String?),
      shiftType: ShiftType.fromString(json['shift_type'] as String? ?? 'care'),
      status: ShiftStatus.fromString(json['status'] as String? ?? 'scheduled'),
      location: json['location'] as String?,
      staffRequired: json['staff_required'] as int?,
      staffType: json['staff_type'] as String?,
      notes: json['notes'] as String?,
      rate: (json['rate'] as num?)?.toDouble(),
      recurring: json['recurring'] as bool? ?? false,
      recurringPattern: json['recurring_pattern'] as Map<String, dynamic>?,
      createdBy: json['created_by'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      organisationId: json['organisation_id'] as String?,
      agencyClientId: json['agency_client_id'] as String?,
      agencyBillingRate: (json['agency_billing_rate'] as num?)?.toDouble(),
      broadcastType: json['broadcast_type'] == null
          ? null
          : BroadcastType.fromString(json['broadcast_type'] as String),
      broadcastAgencyIds: json['broadcast_agency_ids'] == null
          ? null
          : (json['broadcast_agency_ids'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
    );

DateTime _parseTime(String? time) {
  if (time == null || time.isEmpty) return DateTime(2000, 1, 1);
  final parts = time.split(':');
  if (parts.length >= 2) {
    return DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  }
  return DateTime(2000, 1, 1);
}

Map<String, dynamic> _$ShiftToJson(Shift instance) => <String, dynamic>{
      'id': instance.id,
      'client_id': instance.clientId,
      'client_organisation_id': instance.clientOrganisationId,
      'service_user_id': instance.serviceUserId,
      'service_users': instance.serviceUserName == null
          ? null
          : {'name': instance.serviceUserName},
      'carer_id': instance.carerId,
      'carers': instance.carerName == null
          ? null
          : {'name': instance.carerName},
      'scheduled_date': instance.scheduledDate.toIso8601String().split('T')[0],
      'start_time': instance.startTime.toIso8601String(),
      'end_time': instance.endTime.toIso8601String(),
      'shift_type': instance.shiftType.value,
      'status': instance.status.value,
      'location': instance.location,
      'staff_required': instance.staffRequired,
      'staff_type': instance.staffType,
      'notes': instance.notes,
      'rate': instance.rate,
      'recurring': instance.recurring,
      'recurring_pattern': instance.recurringPattern,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'organisation_id': instance.organisationId,
      'agency_client_id': instance.agencyClientId,
      'agency_billing_rate': instance.agencyBillingRate,
      'broadcast_type': instance.broadcastType?.value,
      'broadcast_agency_ids': instance.broadcastAgencyIds,
    };
