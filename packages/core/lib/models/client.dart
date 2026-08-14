import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'client.g.dart';

@JsonSerializable()
class Client extends Equatable {
  final String id;
  final String userId; // References profile
  final String companyName;
  final String? tradingName;
  final String? registrationNumber;
  final String? vatNumber;
  final String? address;
  final String? phone;
  final String? email;
  final bool isActive;
  final String? industry; // care, warehouse, logistics, childcare
  final DateTime createdAt;
  final DateTime updatedAt;

  const Client({
    required this.id,
    required this.userId,
    required this.companyName,
    this.tradingName,
    this.registrationNumber,
    this.vatNumber,
    this.address,
    this.phone,
    this.email,
    this.isActive = true,
    this.industry,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) => _$ClientFromJson(json);
  Map<String, dynamic> toJson() => _$ClientToJson(this);

  Client copyWith({
    String? id,
    String? userId,
    String? companyName,
    String? tradingName,
    String? registrationNumber,
    String? vatNumber,
    String? address,
    String? phone,
    String? email,
    bool? isActive,
    String? industry,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      tradingName: tradingName ?? this.tradingName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      vatNumber: vatNumber ?? this.vatNumber,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      industry: industry ?? this.industry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, companyName, isActive];

  String get displayName => tradingName ?? companyName;

  bool get hasVatNumber => vatNumber != null && vatNumber!.isNotEmpty;
  bool get hasRegistrationNumber => registrationNumber != null && registrationNumber!.isNotEmpty;
}