import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'service_user.g.dart';

@JsonSerializable()
class ServiceUser extends Equatable {
  final String id;
  final String clientOrganisationId;
  final String firstName;
  final String lastName;
  final String? address;
  final String? carePlan;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceUser({
    required this.id,
    required this.clientOrganisationId,
    required this.firstName,
    required this.lastName,
    this.address,
    this.carePlan,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceUser.fromJson(Map<String, dynamic> json) => _$ServiceUserFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceUserToJson(this);

  ServiceUser copyWith({
    String? id,
    String? clientOrganisationId,
    String? firstName,
    String? lastName,
    String? address,
    String? carePlan,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceUser(
      id: id ?? this.id,
      clientOrganisationId: clientOrganisationId ?? this.clientOrganisationId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      address: address ?? this.address,
      carePlan: carePlan ?? this.carePlan,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clientOrganisationId,
        firstName,
        lastName,
        address,
        carePlan,
        notes,
        isActive,
        createdAt,
        updatedAt,
      ];

  String get fullName => '$firstName $lastName';
}