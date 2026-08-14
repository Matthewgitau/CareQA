import 'package:flutter/material.dart';

enum AssessmentStatus {
  good,
  poor,
  requiresAttention,
  adequate,
  inadequate,
  safe,
  tripHazard,
  uneven,
  clear,
  obstructed,
  accessible,
  blocked,
  working,
  notTested,
  patTested,
  damaged,
  secure,
  insecure,
  appropriate,
  inappropriate,
  disposal,
  unsafe,
}

enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

class EnvironmentalAssessment {
  final String? id;
  final String? serviceUserId;
  final DateTime assessmentDate;
  final String assessorName;
  final String location;
  final AssessmentStatus lightingAdequacy;
  final AssessmentStatus ventilation;
  final AssessmentStatus temperatureControl;
  final AssessmentStatus flooringCondition;
  final AssessmentStatus walkways;
  final AssessmentStatus stairs;
  final AssessmentStatus doorsExits;
  final AssessmentStatus fireExits;
  final AssessmentStatus emergencyLighting;
  final AssessmentStatus electricalSafety;
  final AssessmentStatus waterSafety;
  final AssessmentStatus coshhStorage;
  final AssessmentStatus wasteManagement;
  final AssessmentStatus security;
  final AssessmentStatus outdoorAreas;
  final AssessmentStatus equipmentStorage;
  final RiskLevel riskLevel;
  final String? actionPlan;
  final DateTime? reviewDate;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  EnvironmentalAssessment({
    this.id,
    this.serviceUserId,
    required this.assessmentDate,
    required this.assessorName,
    required this.location,
    required this.lightingAdequacy,
    required this.ventilation,
    required this.temperatureControl,
    required this.flooringCondition,
    required this.walkways,
    required this.stairs,
    required this.doorsExits,
    required this.fireExits,
    required this.emergencyLighting,
    required this.electricalSafety,
    required this.waterSafety,
    required this.coshhStorage,
    required this.wasteManagement,
    required this.security,
    required this.outdoorAreas,
    required this.equipmentStorage,
    required this.riskLevel,
    this.actionPlan,
    this.reviewDate,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'service_user_id': serviceUserId,
      'assessment_date': assessmentDate.toIso8601String(),
      'assessor_name': assessorName,
      'location': location,
      'lighting_adequacy': lightingAdequacy.name,
      'ventilation': ventilation.name,
      'temperature_control': temperatureControl.name,
      'flooring_condition': flooringCondition.name,
      'walkways': walkways.name,
      'stairs': stairs.name,
      'doors_exits': doorsExits.name,
      'fire_exits': fireExits.name,
      'emergency_lighting': emergencyLighting.name,
      'electrical_safety': electricalSafety.name,
      'water_safety': waterSafety.name,
      'coshh_storage': coshhStorage.name,
      'waste_management': wasteManagement.name,
      'security': security.name,
      'outdoor_areas': outdoorAreas.name,
      'equipment_storage': equipmentStorage.name,
      'risk_level': riskLevel.name,
      'action_plan': actionPlan,
      'review_date': reviewDate?.toIso8601String(),
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory EnvironmentalAssessment.fromMap(Map<String, dynamic> map) {
    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value.toLocal();
      return DateTime.parse(value).toLocal();
    }

    return EnvironmentalAssessment(
      id: map['id'],
      serviceUserId: map['service_user_id'],
      assessmentDate: _parseDate(map['assessment_date']),
      assessorName: map['assessor_name'] as String? ?? '',
      location: map['location'] as String? ?? '',
      lightingAdequacy: AssessmentStatus.values.firstWhere(
        (e) => e.name == map['lighting_adequacy'],
        orElse: () => AssessmentStatus.good,
      ),
      ventilation: AssessmentStatus.values.firstWhere(
        (e) => e.name == map['ventilation'],
        orElse: () => AssessmentStatus.good,
      ),
      temperatureControl: AssessmentStatus.values.firstWhere(
        (e) => e.name == map['temperature_control'],
        orElse: () => AssessmentStatus.adequate,
      ),
      flooringCondition: AssessmentStatus.values.firstWhere(
        (e) => e.name == map['flooring_condition'],
        orElse: () => AssessmentStatus.safe,
      ),
      walkways: AssessmentStatus.values.firstWhere(
        (e) => e.name == map['walkways'],
        orElse: () => AssessmentStatus.clear,
      ),
      stairs: AssessmentStatus.values.firstWhere(
        (e) => e.name == map['stairs'],
        orElse: () => AssessmentStatus.good,
      ),
      doorsExits: AssessmentStatus.values.firstWhere(
        (e) => e.name == map['doors_exits'],
        orElse: () => AssessmentStatus.accessible,
      ),
      fireExits: AssessmentStatus.values.firstWhere(
        (e) => e.name == map['fire_exits'],
        orElse: () => AssessmentStatus.clear,
      ),
      emergencyLighting: AssessmentStatus.values.firstWhere(
        (e) => e.name == map['emergency_lighting'],
        orElse: () => AssessmentStatus.working,
      ),
      electricalSafety: AssessmentStatus.values.firstWhere(
        (e) => e.name == map['electrical_safety'],
        orElse: () => AssessmentStatus.patTested,
      ),
      waterSafety: AssessmentStatus.values.firstWhere(
        (e) => e.name == map['water_safety'],
        orElse: () => AssessmentStatus.adequate,
      ),
      coshhStorage: AssessmentStatus.values.firstWhere(
        (e) => e.name == map['coshh_storage'],
        orElse: () => AssessmentStatus.secure,
      ),
      wasteManagement: AssessmentStatus.values.firstWhere(
        (e) => e.name == map['waste_management'],
        orElse: () => AssessmentStatus.appropriate,
      ),
      security: AssessmentStatus.values.firstWhere(
        (e) => e.name == map['security'],
        orElse: () => AssessmentStatus.secure,
      ),
      outdoorAreas: AssessmentStatus.values.firstWhere(
        (e) => e.name == map['outdoor_areas'],
        orElse: () => AssessmentStatus.safe,
      ),
      equipmentStorage: AssessmentStatus.values.firstWhere(
        (e) => e.name == map['equipment_storage'],
        orElse: () => AssessmentStatus.safe,
      ),
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == map['risk_level'],
        orElse: () => RiskLevel.low,
      ),
      actionPlan: map['action_plan'],
      reviewDate: map['review_date'] != null ? _parseDate(map['review_date']) : null,
      photoUrl: map['photo_url'],
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }
}