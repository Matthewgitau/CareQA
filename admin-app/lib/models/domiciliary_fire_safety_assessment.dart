class DomiciliaryFireSafetyAssessment {
  final String? id;
  final String? serviceUserId;
  final String? serviceUserName;
  final String? assessorName;
  final DateTime? assessmentDate;
  final String? riskLevel;
  final String? recommendedActions;
  final String? signature;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Section 1: Electrical Safety
  final bool? hasElectricalEquipment;
  final bool? patTestVisible;
  final String? operatesEquipmentSelf;
  final bool? visibleDamage;

  // Section 2: Fire Prevention
  final bool? workingSmokeAlarms;
  final bool? smokes;
  final String? escapeRoutesClear;
  final bool? hasFireBlanketOrExtinguisher;

  // Section 3: Emergency Response
  final String? canExitIndependently;
  final String? hasCapacityToUnderstand;
  final bool? nameAddressVisible;

  DomiciliaryFireSafetyAssessment({
    this.id,
    this.serviceUserId,
    this.serviceUserName,
    this.assessorName,
    this.assessmentDate,
    this.riskLevel,
    this.recommendedActions,
    this.signature,
    this.status = 'draft',
    this.createdAt,
    this.updatedAt,
    this.hasElectricalEquipment,
    this.patTestVisible,
    this.operatesEquipmentSelf,
    this.visibleDamage,
    this.workingSmokeAlarms,
    this.smokes,
    this.escapeRoutesClear,
    this.hasFireBlanketOrExtinguisher,
    this.canExitIndependently,
    this.hasCapacityToUnderstand,
    this.nameAddressVisible,
  });

  int get noCount {
    int count = 0;
    if (hasElectricalEquipment == true) {
      if (patTestVisible == false) count++;
      if (operatesEquipmentSelf == 'yes' && patTestVisible == false) count++;
      if (visibleDamage == true) count++;
    }
    if (workingSmokeAlarms == false) count++;
    if (escapeRoutesClear == 'no') count++;
    if (canExitIndependently == 'no') count++;
    if (hasCapacityToUnderstand == 'no') count++;
    if (nameAddressVisible == false) count++;
    return count;
  }

  bool get hasDangerousCondition {
    return visibleDamage == true || workingSmokeAlarms == false;
  }

  String get calculatedRiskLevel {
    if (hasDangerousCondition || noCount >= 3) return 'high';
    if (noCount >= 1) return 'medium';
    return 'low';
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'service_user_id': serviceUserId,
      'service_user_name': serviceUserName,
      'assessor_name': assessorName,
      'assessment_date': assessmentDate?.toIso8601String(),
      'risk_level': riskLevel ?? calculatedRiskLevel,
      'has_electrical_equipment': hasElectricalEquipment,
      'pat_test_visible': patTestVisible,
      'operates_equipment_self': operatesEquipmentSelf,
      'visible_damage': visibleDamage,
      'working_smoke_alarms': workingSmokeAlarms,
      'smokes': smokes,
      'escape_routes_clear': escapeRoutesClear,
      'has_fire_blanket_or_extinguisher': hasFireBlanketOrExtinguisher,
      'can_exit_independently': canExitIndependently,
      'has_capacity_to_understand': hasCapacityToUnderstand,
      'name_address_visible': nameAddressVisible,
      'recommended_actions': recommendedActions,
      'signature': signature,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory DomiciliaryFireSafetyAssessment.fromJson(Map<String, dynamic> json) {
    return DomiciliaryFireSafetyAssessment(
      id: json['id'],
      serviceUserId: json['service_user_id'],
      serviceUserName: json['service_user_name'],
      assessorName: json['assessor_name'],
      assessmentDate: json['assessment_date'] != null ? DateTime.parse(json['assessment_date']) : null,
      riskLevel: json['risk_level'],
      hasElectricalEquipment: json['has_electrical_equipment'],
      patTestVisible: json['pat_test_visible'],
      operatesEquipmentSelf: json['operates_equipment_self'],
      visibleDamage: json['visible_damage'],
      workingSmokeAlarms: json['working_smoke_alarms'],
      smokes: json['smokes'],
      escapeRoutesClear: json['escape_routes_clear'],
      hasFireBlanketOrExtinguisher: json['has_fire_blanket_or_extinguisher'],
      canExitIndependently: json['can_exit_independently'],
      hasCapacityToUnderstand: json['has_capacity_to_understand'],
      nameAddressVisible: json['name_address_visible'],
      recommendedActions: json['recommended_actions'],
      signature: json['signature'],
      status: json['status'] ?? 'draft',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  DomiciliaryFireSafetyAssessment copyWith({
    String? id,
    String? serviceUserId,
    String? serviceUserName,
    String? assessorName,
    DateTime? assessmentDate,
    String? riskLevel,
    String? recommendedActions,
    String? signature,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasElectricalEquipment,
    bool? patTestVisible,
    String? operatesEquipmentSelf,
    bool? visibleDamage,
    bool? workingSmokeAlarms,
    bool? smokes,
    String? escapeRoutesClear,
    bool? hasFireBlanketOrExtinguisher,
    String? canExitIndependently,
    String? hasCapacityToUnderstand,
    bool? nameAddressVisible,
  }) {
    return DomiciliaryFireSafetyAssessment(
      id: id ?? this.id,
      serviceUserId: serviceUserId ?? this.serviceUserId,
      serviceUserName: serviceUserName ?? this.serviceUserName,
      assessorName: assessorName ?? this.assessorName,
      assessmentDate: assessmentDate ?? this.assessmentDate,
      riskLevel: riskLevel ?? this.riskLevel,
      recommendedActions: recommendedActions ?? this.recommendedActions,
      signature: signature ?? this.signature,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasElectricalEquipment: hasElectricalEquipment ?? this.hasElectricalEquipment,
      patTestVisible: patTestVisible ?? this.patTestVisible,
      operatesEquipmentSelf: operatesEquipmentSelf ?? this.operatesEquipmentSelf,
      visibleDamage: visibleDamage ?? this.visibleDamage,
      workingSmokeAlarms: workingSmokeAlarms ?? this.workingSmokeAlarms,
      smokes: smokes ?? this.smokes,
      escapeRoutesClear: escapeRoutesClear ?? this.escapeRoutesClear,
      hasFireBlanketOrExtinguisher: hasFireBlanketOrExtinguisher ?? this.hasFireBlanketOrExtinguisher,
      canExitIndependently: canExitIndependently ?? this.canExitIndependently,
      hasCapacityToUnderstand: hasCapacityToUnderstand ?? this.hasCapacityToUnderstand,
      nameAddressVisible: nameAddressVisible ?? this.nameAddressVisible,
    );
  }

  // Helper to convert UI string to bool? for boolean fields that support 'Unknown'
  static bool? stringToBool(String? value) {
    if (value == null) return null;
    if (value == 'yes') return true;
    if (value == 'no') return false;
    return null; // 'unknown' or any other value maps to null
  }

  // Helper to convert bool? back to UI string
  static String boolToString(bool? value) {
    if (value == true) return 'yes';
    if (value == false) return 'no';
    return 'unknown';
  }
}