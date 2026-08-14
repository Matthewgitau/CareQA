import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'carer.g.dart';

@JsonSerializable()
class Carer extends Equatable {
  final String id;
  final String userId; // References profile
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? address;
  final bool isActive;
  final List<String>? qualifications;
  final List<String>? certifications;
  final Map<String, dynamic>? availability;
  final double? hourlyRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Carer({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.dateOfBirth,
    this.address,
    this.isActive = true,
    this.qualifications,
    this.certifications,
    this.availability,
    this.hourlyRate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Carer.fromJson(Map<String, dynamic> json) => _$CarerFromJson(json);
  Map<String, dynamic> toJson() => _$CarerToJson(this);

  Carer copyWith({
    String? id,
    String? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? address,
    bool? isActive,
    List<String>? qualifications,
    List<String>? certifications,
    Map<String, dynamic>? availability,
    double? hourlyRate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Carer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      qualifications: qualifications ?? this.qualifications,
      certifications: certifications ?? this.certifications,
      availability: availability ?? this.availability,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, firstName, lastName, isActive];

  String get fullName => '$firstName $lastName';

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  bool get hasQualifications => qualifications != null && qualifications!.isNotEmpty;
  bool get hasCertifications => certifications != null && certifications!.isNotEmpty;
  bool get hasAvailability => availability != null && availability!.isNotEmpty;
}