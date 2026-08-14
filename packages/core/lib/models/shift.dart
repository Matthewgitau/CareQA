import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'shift.g.dart';

enum ShiftStatus {
  scheduled('scheduled'),
  pending('pending'),
  assigned('assigned'),
  confirmed('confirmed'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled'),
  declined('declined');

  final String value;

  const ShiftStatus(this.value);

  factory ShiftStatus.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'scheduled':
        return ShiftStatus.scheduled;
      case 'pending':
        return ShiftStatus.pending;
      case 'assigned':
        return ShiftStatus.assigned;
      case 'confirmed':
        return ShiftStatus.confirmed;
      case 'in_progress':
        return ShiftStatus.inProgress;
      case 'completed':
        return ShiftStatus.completed;
      case 'cancelled':
        return ShiftStatus.cancelled;
      case 'declined':
        return ShiftStatus.declined;
      default:
        throw ArgumentError('Invalid shift status: $value');
    }
  }

  @override
  String toString() => value;
}

enum ShiftType {
  care('care'),
  warehouse('warehouse'),
  transport('transport'),
  admin('admin'),
  training('training');

  final String value;

  const ShiftType(this.value);

  factory ShiftType.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'care':
        return ShiftType.care;
      case 'warehouse':
        return ShiftType.warehouse;
      case 'transport':
        return ShiftType.transport;
      case 'admin':
        return ShiftType.admin;
      case 'training':
        return ShiftType.training;
      default:
        throw ArgumentError('Invalid shift type: $value');
    }
  }

  @override
  String toString() => value;
}

enum BroadcastType {
  single('single'),
  multiple('multiple'),
  all('all');

  final String value;

  const BroadcastType(this.value);

  factory BroadcastType.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'single':
        return BroadcastType.single;
      case 'multiple':
        return BroadcastType.multiple;
      case 'all':
        return BroadcastType.all;
      default:
        return BroadcastType.single;
    }
  }

  @override
  String toString() => value;
}

@JsonSerializable()
class Shift extends Equatable {
  final String id;
  final String clientId;
  final String? clientOrganisationId;
  final String serviceUserId;
  final String? serviceUserName;
  final String? carerId;
  final String? carerName;
  final DateTime scheduledDate;
  final DateTime startTime;
  final DateTime endTime;
  final ShiftType shiftType;
  final ShiftStatus status;
  final String? location;
  final int? staffRequired;
  final String? staffType;
  final String? notes;
  final double? rate;
  final bool recurring;
  final Map<String, dynamic>? recurringPattern;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? organisationId;
  final String? agencyClientId;
  final double? agencyBillingRate;
  final BroadcastType? broadcastType;
  final List<String>? broadcastAgencyIds;

  const Shift({
    required this.id,
    required this.clientId,
    this.clientOrganisationId,
    required this.serviceUserId,
    this.serviceUserName,
    this.carerId,
    this.carerName,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
    required this.shiftType,
    this.status = ShiftStatus.scheduled,
    this.location,
    this.staffRequired = 1,
    this.staffType,
    this.notes,
    this.rate,
    this.recurring = false,
    this.recurringPattern,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.organisationId,
    this.agencyClientId,
    this.agencyBillingRate,
    this.broadcastType,
    this.broadcastAgencyIds,
  });

  factory Shift.fromJson(Map<String, dynamic> json) => _$ShiftFromJson(json);

  Map<String, dynamic> toJson() => _$ShiftToJson(this);

  Shift copyWith({
    String? id,
    String? clientId,
    String? clientOrganisationId,
    String? serviceUserId,
    String? serviceUserName,
    String? carerId,
    String? carerName,
    DateTime? scheduledDate,
    DateTime? startTime,
    DateTime? endTime,
    ShiftType? shiftType,
    ShiftStatus? status,
    String? location,
    int? staffRequired,
    String? staffType,
    String? notes,
    double? rate,
    bool? recurring,
    Map<String, dynamic>? recurringPattern,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? organisationId,
    String? agencyClientId,
    double? agencyBillingRate,
    BroadcastType? broadcastType,
    List<String>? broadcastAgencyIds,
  }) {
    return Shift(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientOrganisationId: clientOrganisationId ?? this.clientOrganisationId,
      serviceUserId: serviceUserId ?? this.serviceUserId,
      serviceUserName: serviceUserName ?? this.serviceUserName,
      carerId: carerId ?? this.carerId,
      carerName: carerName ?? this.carerName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      shiftType: shiftType ?? this.shiftType,
      status: status ?? this.status,
      location: location ?? this.location,
      staffRequired: staffRequired ?? this.staffRequired,
      staffType: staffType ?? this.staffType,
      notes: notes ?? this.notes,
      rate: rate ?? this.rate,
      recurring: recurring ?? this.recurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      organisationId: organisationId ?? this.organisationId,
      agencyClientId: agencyClientId ?? this.agencyClientId,
      agencyBillingRate: agencyBillingRate ?? this.agencyBillingRate,
      broadcastType: broadcastType ?? this.broadcastType,
      broadcastAgencyIds: broadcastAgencyIds ?? this.broadcastAgencyIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clientId,
        clientOrganisationId,
        serviceUserId,
        serviceUserName,
        carerId,
        carerName,
        scheduledDate,
        startTime,
        endTime,
        shiftType,
        status,
        location,
        staffRequired,
        staffType,
        notes,
        rate,
        recurring,
        recurringPattern,
        createdBy,
        createdAt,
        updatedAt,
        organisationId,
        agencyClientId,
        agencyBillingRate,
        broadcastType,
        broadcastAgencyIds,
      ];

  Duration get duration => endTime.difference(startTime);

  bool get isPending => status == ShiftStatus.pending;
  bool get isAssigned => status == ShiftStatus.assigned;
  bool get isConfirmed => status == ShiftStatus.confirmed;
  bool get isInProgress => status == ShiftStatus.inProgress;
  bool get isCompleted => status == ShiftStatus.completed;
  bool get isCancelled => status == ShiftStatus.cancelled;
  bool get isDeclined => status == ShiftStatus.declined;

  bool get isActive => isAssigned || isConfirmed || isInProgress;
  bool get isPast => endTime.isBefore(DateTime.now());
  bool get isFuture => startTime.isAfter(DateTime.now());
  bool get isCurrent => !isPast && !isFuture;
}