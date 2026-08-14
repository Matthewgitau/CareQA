import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'organisation.g.dart';

@JsonSerializable()
class Organisation extends Equatable {
  final String id;
  final String name;
  final String? type;
  final String? address;
  final String? phone;
  final String? email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Organisation({
    required this.id,
    required this.name,
    this.type,
    this.address,
    this.phone,
    this.email,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Organisation.fromJson(Map<String, dynamic> json) => _$OrganisationFromJson(json);
  Map<String, dynamic> toJson() => _$OrganisationToJson(this);

  Organisation copyWith({
    String? id,
    String? name,
    String? type,
    String? address,
    String? phone,
    String? email,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Organisation(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        address,
        phone,
        email,
        isActive,
        createdAt,
        updatedAt,
      ];
}