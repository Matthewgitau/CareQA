import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'route.g.dart';

enum RouteStatus {
  scheduled('scheduled'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled');

  final String value;

  const RouteStatus(this.value);

  factory RouteStatus.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'scheduled':
        return RouteStatus.scheduled;
      case 'in_progress':
        return RouteStatus.inProgress;
      case 'completed':
        return RouteStatus.completed;
      case 'cancelled':
        return RouteStatus.cancelled;
      default:
        throw ArgumentError('Invalid route status: $value');
    }
  }

  @override
  String toString() => value;
}

@JsonSerializable()
class Route extends Equatable {
  final String id;
  final String clientOrganisationId;
  final String serviceUserId;
  final String? carerId;
  final DateTime proposedStartTime;
  final DateTime proposedEndTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final bool respite;
  final int callNumber;
  final RouteStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Route({
    required this.id,
    required this.clientOrganisationId,
    required this.serviceUserId,
    this.carerId,
    required this.proposedStartTime,
    required this.proposedEndTime,
    this.actualStartTime,
    this.actualEndTime,
    this.respite = false,
    required this.callNumber,
    this.status = RouteStatus.scheduled,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Route.fromJson(Map<String, dynamic> json) => _$RouteFromJson(json);
  Map<String, dynamic> toJson() => _$RouteToJson(this);

  Route copyWith({
    String? id,
    String? clientOrganisationId,
    String? serviceUserId,
    String? carerId,
    DateTime? proposedStartTime,
    DateTime? proposedEndTime,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    bool? respite,
    int? callNumber,
    RouteStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Route(
      id: id ?? this.id,
      clientOrganisationId: clientOrganisationId ?? this.clientOrganisationId,
      serviceUserId: serviceUserId ?? this.serviceUserId,
      carerId: carerId ?? this.carerId,
      proposedStartTime: proposedStartTime ?? this.proposedStartTime,
      proposedEndTime: proposedEndTime ?? this.proposedEndTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      respite: respite ?? this.respite,
      callNumber: callNumber ?? this.callNumber,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clientOrganisationId,
        serviceUserId,
        carerId,
        proposedStartTime,
        proposedEndTime,
        actualStartTime,
        actualEndTime,
        respite,
        callNumber,
        status,
        notes,
        createdAt,
        updatedAt,
      ];

  bool get isScheduled => status == RouteStatus.scheduled;
  bool get isInProgress => status == RouteStatus.inProgress;
  bool get isCompleted => status == RouteStatus.completed;
  bool get isCancelled => status == RouteStatus.cancelled;
  bool get isRespite => respite;
}