import 'dart:convert';

class FireHazardAssessment {
  final String? id;
  final String? serviceUserId;
  final DateTime assessmentDate;
  final String? assessorName;
  
  // Section 1: Fire Detection & Warning (6 fields)
  final String? smokeDetectorsPresent;
  final DateTime? smokeDetectorTestDate;
  final bool? heatDetectorsInKitchens;
  final String? fireAlarmSystemType;
  final DateTime? fireAlarmTestDate;
  final bool? fireAlarmWeeklyTestRecorded;
  
  // Section 2: Fire Fighting Equipment (8 fields)
  final List<String>? fireExtinguisherTypes;
  final bool? fireExtinguisherLocationsDocumented;
  final DateTime? fireExtinguisherServiceDate;
  final DateTime? fireExtinguisherNextServiceDue;
  final bool? fireBlanketInKitchen;
  final DateTime? fireBlanketServiceDate;
  final bool? fireHoseReelPresent;
  final bool? equipmentInspectedMonthly;
  
  // Section 3: Means of Escape (8 fields)
  final bool? emergencyExitsClearlyMarked;
  final bool? exitDoorsOpenEasily;
  final bool? exitRoutesUnobstructed;
  final bool? emergencyLightingWorking;
  final DateTime? emergencyLightingTestDate;
  final bool? fireExitSignsIlluminated;
  final bool? finalExitsOpenOutward;
  final bool? escapeRoutesSuitableForMobilityAids;
  
  // Section 4: Fire Doors & Compartmentation (6 fields)
  final bool? fireDoorsSelfClosing;
  final bool? fireDoorGapsLessThan4mm;
  final bool? fireDoorSealsIntact;
  final DateTime? fireDoorInspectionDate;
  final bool? compartmentWallsIntact;
  final bool? ceilingFloorPenetrationsSealed;
  
  // Section 5: PEEPs & Evacuation (8 fields)
  final String? peepsInPlaceForAllServiceUsers;
  final bool? peepsReviewedAnnually;
  final bool? staffKnowPeepsForAssignedServiceUsers;
  final bool? evacuationPlanDisplayed;
  final bool? evacuationPlanRehearsed;
  final bool? visitorsSignedInOut;
  final bool? nightStaffNumbersAdequate;
  final bool? disabledRefugePointsIdentified;
  
  // Section 6: Training & Drills (6 fields)
  final bool? staffFireTrainingCompleted;
  final DateTime? staffTrainingDate;
  final DateTime? staffTrainingNextDue;
  final bool? fireDrillConducted;
  final DateTime? fireDrillDate;
  final String? fireDrillFrequency;
  
  // Section 7: Management & Records (6 fields)
  final bool? fireLogBookMaintained;
  final DateTime? fireRiskAssessmentReviewDate;
  final bool? fireWardenAppointed;
  final String? fireWardenName;
  final bool? weeklyChecksRecorded;
  final bool? monthlyChecksRecorded;
  
  // Section 8: Kitchen & High Risk Areas (4 fields)
  final bool? kitchenExtractorHoodCleaned;
  final DateTime? extractorCleaningDate;
  final bool? cookerIsolatorSwitchAccessible;
  final bool? laundryDryerLintFilterCleaned;
  
  // Section 9: Electrical Fire Risks (4 fields)
  final bool? patTestingUpToDate;
  final DateTime? patTestExpiryDate;
  final bool? electricalEquipmentNotOverloaded;
  final bool? chargingDevicesOnNonFlammableSurface;
  
  // Section 10: Arson Prevention (4 fields)
  final bool? externalWasteBinsAwayFromBuilding;
  final bool? binStoresLocked;
  final bool? externalLightingWorking;
  final bool? intruderAlarmWorking;
  
  // Calculated fields
  final int? totalScore;
  final String? riskLevel;
  final String? actionRequired;
  
  // Action plan
  final List<Map<String, dynamic>>? actionItems;
  final String? responsiblePerson;
  final DateTime? completionDeadline;
  final DateTime? reviewDate;
  
  // Audit fields
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  FireHazardAssessment({
    this.id,
    this.serviceUserId,
    required this.assessmentDate,
    this.assessorName,
    
    // Section 1: Fire Detection & Warning
    this.smokeDetectorsPresent,
    this.smokeDetectorTestDate,
    this.heatDetectorsInKitchens,
    this.fireAlarmSystemType,
    this.fireAlarmTestDate,
    this.fireAlarmWeeklyTestRecorded,
    
    // Section 2: Fire Fighting Equipment
    this.fireExtinguisherTypes,
    this.fireExtinguisherLocationsDocumented,
    this.fireExtinguisherServiceDate,
    this.fireExtinguisherNextServiceDue,
    this.fireBlanketInKitchen,
    this.fireBlanketServiceDate,
    this.fireHoseReelPresent,
    this.equipmentInspectedMonthly,
    
    // Section 3: Means of Escape
    this.emergencyExitsClearlyMarked,
    this.exitDoorsOpenEasily,
    this.exitRoutesUnobstructed,
    this.emergencyLightingWorking,
    this.emergencyLightingTestDate,
    this.fireExitSignsIlluminated,
    this.finalExitsOpenOutward,
    this.escapeRoutesSuitableForMobilityAids,
    
    // Section 4: Fire Doors & Compartmentation
    this.fireDoorsSelfClosing,
    this.fireDoorGapsLessThan4mm,
    this.fireDoorSealsIntact,
    this.fireDoorInspectionDate,
    this.compartmentWallsIntact,
    this.ceilingFloorPenetrationsSealed,
    
    // Section 5: PEEPs & Evacuation
    this.peepsInPlaceForAllServiceUsers,
    this.peepsReviewedAnnually,
    this.staffKnowPeepsForAssignedServiceUsers,
    this.evacuationPlanDisplayed,
    this.evacuationPlanRehearsed,
    this.visitorsSignedInOut,
    this.nightStaffNumbersAdequate,
    this.disabledRefugePointsIdentified,
    
    // Section 6: Training & Drills
    this.staffFireTrainingCompleted,
    this.staffTrainingDate,
    this.staffTrainingNextDue,
    this.fireDrillConducted,
    this.fireDrillDate,
    this.fireDrillFrequency,
    
    // Section 7: Management & Records
    this.fireLogBookMaintained,
    this.fireRiskAssessmentReviewDate,
    this.fireWardenAppointed,
    this.fireWardenName,
    this.weeklyChecksRecorded,
    this.monthlyChecksRecorded,
    
    // Section 8: Kitchen & High Risk Areas
    this.kitchenExtractorHoodCleaned,
    this.extractorCleaningDate,
    this.cookerIsolatorSwitchAccessible,
    this.laundryDryerLintFilterCleaned,
    
    // Section 9: Electrical Fire Risks
    this.patTestingUpToDate,
    this.patTestExpiryDate,
    this.electricalEquipmentNotOverloaded,
    this.chargingDevicesOnNonFlammableSurface,
    
    // Section 10: Arson Prevention
    this.externalWasteBinsAwayFromBuilding,
    this.binStoresLocked,
    this.externalLightingWorking,
    this.intruderAlarmWorking,
    
    // Calculated fields
    this.totalScore,
    this.riskLevel,
    this.actionRequired,
    
    // Action plan
    this.actionItems,
    this.responsiblePerson,
    this.completionDeadline,
    this.reviewDate,
    
    // Audit fields
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory FireHazardAssessment.fromJson(Map<String, dynamic> json) {
    return FireHazardAssessment(
      id: json['id'],
      serviceUserId: json['service_user_id'],
      assessmentDate: DateTime.parse(json['assessment_date']),
      assessorName: json['assessor_name'],
      
      // Section 1: Fire Detection & Warning
      smokeDetectorsPresent: json['smoke_detectors_present'],
      smokeDetectorTestDate: json['smoke_detector_test_date'] != null 
          ? DateTime.parse(json['smoke_detector_test_date']) 
          : null,
      heatDetectorsInKitchens: json['heat_detectors_in_kitchens'],
      fireAlarmSystemType: json['fire_alarm_system_type'],
      fireAlarmTestDate: json['fire_alarm_test_date'] != null 
          ? DateTime.parse(json['fire_alarm_test_date']) 
          : null,
      fireAlarmWeeklyTestRecorded: json['fire_alarm_weekly_test_recorded'],
      
      // Section 2: Fire Fighting Equipment
      fireExtinguisherTypes: json['fire_extinguisher_types'] != null 
          ? List<String>.from(json['fire_extinguisher_types']) 
          : null,
      fireExtinguisherLocationsDocumented: json['fire_extinguisher_locations_documented'],
      fireExtinguisherServiceDate: json['fire_extinguisher_service_date'] != null 
          ? DateTime.parse(json['fire_extinguisher_service_date']) 
          : null,
      fireExtinguisherNextServiceDue: json['fire_extinguisher_next_service_due'] != null 
          ? DateTime.parse(json['fire_extinguisher_next_service_due']) 
          : null,
      fireBlanketInKitchen: json['fire_blanket_in_kitchen'],
      fireBlanketServiceDate: json['fire_blanket_service_date'] != null 
          ? DateTime.parse(json['fire_blanket_service_date']) 
          : null,
      fireHoseReelPresent: json['fire_hose_reel_present'],
      equipmentInspectedMonthly: json['equipment_inspected_monthly'],
      
      // Section 3: Means of Escape
      emergencyExitsClearlyMarked: json['emergency_exits_clearly_marked'],
      exitDoorsOpenEasily: json['exit_doors_open_easily'],
      exitRoutesUnobstructed: json['exit_routes_unobstructed'],
      emergencyLightingWorking: json['emergency_lighting_working'],
      emergencyLightingTestDate: json['emergency_lighting_test_date'] != null 
          ? DateTime.parse(json['emergency_lighting_test_date']) 
          : null,
      fireExitSignsIlluminated: json['fire_exit_signs_illuminated'],
      finalExitsOpenOutward: json['final_exits_open_outward'],
      escapeRoutesSuitableForMobilityAids: json['escape_routes_suitable_for_mobility_aids'],
      
      // Section 4: Fire Doors & Compartmentation
      fireDoorsSelfClosing: json['fire_doors_self_closing'],
      fireDoorGapsLessThan4mm: json['fire_door_gaps_less_than_4mm'],
      fireDoorSealsIntact: json['fire_door_seals_intact'],
      fireDoorInspectionDate: json['fire_door_inspection_date'] != null 
          ? DateTime.parse(json['fire_door_inspection_date']) 
          : null,
      compartmentWallsIntact: json['compartment_walls_intact'],
      ceilingFloorPenetrationsSealed: json['ceiling_floor_penetrations_sealed'],
      
      // Section 5: PEEPs & Evacuation
      peepsInPlaceForAllServiceUsers: json['peeps_in_place_for_all_service_users'],
      peepsReviewedAnnually: json['peeps_reviewed_annually'],
      staffKnowPeepsForAssignedServiceUsers: json['staff_know_peeps_for_assigned_service_users'],
      evacuationPlanDisplayed: json['evacuation_plan_displayed'],
      evacuationPlanRehearsed: json['evacuation_plan_rehearsed'],
      visitorsSignedInOut: json['visitors_signed_in_out'],
      nightStaffNumbersAdequate: json['night_staff_numbers_adequate'],
      disabledRefugePointsIdentified: json['disabled_refuge_points_identified'],
      
      // Section 6: Training & Drills
      staffFireTrainingCompleted: json['staff_fire_training_completed'],
      staffTrainingDate: json['staff_training_date'] != null 
          ? DateTime.parse(json['staff_training_date']) 
          : null,
      staffTrainingNextDue: json['staff_training_next_due'] != null 
          ? DateTime.parse(json['staff_training_next_due']) 
          : null,
      fireDrillConducted: json['fire_drill_conducted'],
      fireDrillDate: json['fire_drill_date'] != null 
          ? DateTime.parse(json['fire_drill_date']) 
          : null,
      fireDrillFrequency: json['fire_drill_frequency'],
      
      // Section 7: Management & Records
      fireLogBookMaintained: json['fire_log_book_maintained'],
      fireRiskAssessmentReviewDate: json['fire_risk_assessment_review_date'] != null 
          ? DateTime.parse(json['fire_risk_assessment_review_date']) 
          : null,
      fireWardenAppointed: json['fire_warden_appointed'],
      fireWardenName: json['fire_warden_name'],
      weeklyChecksRecorded: json['weekly_checks_recorded'],
      monthlyChecksRecorded: json['monthly_checks_recorded'],
      
      // Section 8: Kitchen & High Risk Areas
      kitchenExtractorHoodCleaned: json['kitchen_extractor_hood_cleaned'],
      extractorCleaningDate: json['extractor_cleaning_date'] != null 
          ? DateTime.parse(json['extractor_cleaning_date']) 
          : null,
      cookerIsolatorSwitchAccessible: json['cooker_isolator_switch_accessible'],
      laundryDryerLintFilterCleaned: json['laundry_dryer_lint_filter_cleaned'],
      
      // Section 9: Electrical Fire Risks
      patTestingUpToDate: json['pat_testing_up_to_date'],
      patTestExpiryDate: json['pat_test_expiry_date'] != null 
          ? DateTime.parse(json['pat_test_expiry_date']) 
          : null,
      electricalEquipmentNotOverloaded: json['electrical_equipment_not_overloaded'],
      chargingDevicesOnNonFlammableSurface: json['charging_devices_on_non_flammable_surface'],
      
      // Section 10: Arson Prevention
      externalWasteBinsAwayFromBuilding: json['external_waste_bins_away_from_building'],
      binStoresLocked: json['bin_stores_locked'],
      externalLightingWorking: json['external_lighting_working'],
      intruderAlarmWorking: json['intruder_alarm_working'],
      
      // Calculated fields
      totalScore: json['total_score'],
      riskLevel: json['risk_level'],
      actionRequired: json['action_required'],
      
      // Action plan
      actionItems: json['action_items'] != null 
          ? List<Map<String, dynamic>>.from(json['action_items']) 
          : null,
      responsiblePerson: json['responsible_person'],
      completionDeadline: json['completion_deadline'] != null 
          ? DateTime.parse(json['completion_deadline']) 
          : null,
      reviewDate: json['review_date'] != null 
          ? DateTime.parse(json['review_date']) 
          : null,
      
      // Audit fields
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
    );
  }

  String? _nullIfEmpty(String? value) {
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_user_id': _nullIfEmpty(serviceUserId),
      'assessment_date': assessmentDate.toIso8601String(),
      'assessor_name': assessorName,
      
      // Section 1: Fire Detection & Warning
      'smoke_detectors_present': smokeDetectorsPresent,
      'smoke_detector_test_date': smokeDetectorTestDate?.toIso8601String(),
      'heat_detectors_in_kitchens': heatDetectorsInKitchens,
      'fire_alarm_system_type': fireAlarmSystemType,
      'fire_alarm_test_date': fireAlarmTestDate?.toIso8601String(),
      'fire_alarm_weekly_test_recorded': fireAlarmWeeklyTestRecorded,
      
      // Section 2: Fire Fighting Equipment
      'fire_extinguisher_types': fireExtinguisherTypes,
      'fire_extinguisher_locations_documented': fireExtinguisherLocationsDocumented,
      'fire_extinguisher_service_date': fireExtinguisherServiceDate?.toIso8601String(),
      'fire_extinguisher_next_service_due': fireExtinguisherNextServiceDue?.toIso8601String(),
      'fire_blanket_in_kitchen': fireBlanketInKitchen,
      'fire_blanket_service_date': fireBlanketServiceDate?.toIso8601String(),
      'fire_hose_reel_present': fireHoseReelPresent,
      'equipment_inspected_monthly': equipmentInspectedMonthly,
      
      // Section 3: Means of Escape
      'emergency_exits_clearly_marked': emergencyExitsClearlyMarked,
      'exit_doors_open_easily': exitDoorsOpenEasily,
      'exit_routes_unobstructed': exitRoutesUnobstructed,
      'emergency_lighting_working': emergencyLightingWorking,
      'emergency_lighting_test_date': emergencyLightingTestDate?.toIso8601String(),
      'fire_exit_signs_illuminated': fireExitSignsIlluminated,
      'final_exits_open_outward': finalExitsOpenOutward,
      'escape_routes_suitable_for_mobility_aids': escapeRoutesSuitableForMobilityAids,
      
      // Section 4: Fire Doors & Compartmentation
      'fire_doors_self_closing': fireDoorsSelfClosing,
      'fire_door_gaps_less_than_4mm': fireDoorGapsLessThan4mm,
      'fire_door_seals_intact': fireDoorSealsIntact,
      'fire_door_inspection_date': fireDoorInspectionDate?.toIso8601String(),
      'compartment_walls_intact': compartmentWallsIntact,
      'ceiling_floor_penetrations_sealed': ceilingFloorPenetrationsSealed,
      
      // Section 5: PEEPs & Evacuation
      'peeps_in_place_for_all_service_users': peepsInPlaceForAllServiceUsers,
      'peeps_reviewed_annually': peepsReviewedAnnually,
      'staff_know_peeps_for_assigned_service_users': staffKnowPeepsForAssignedServiceUsers,
      'evacuation_plan_displayed': evacuationPlanDisplayed,
      'evacuation_plan_rehearsed': evacuationPlanRehearsed,
      'visitors_signed_in_out': visitorsSignedInOut,
      'night_staff_numbers_adequate': nightStaffNumbersAdequate,
      'disabled_refuge_points_identified': disabledRefugePointsIdentified,
      
      // Section 6: Training & Drills
      'staff_fire_training_completed': staffFireTrainingCompleted,
      'staff_training_date': staffTrainingDate?.toIso8601String(),
      'staff_training_next_due': staffTrainingNextDue?.toIso8601String(),
      'fire_drill_conducted': fireDrillConducted,
      'fire_drill_date': fireDrillDate?.toIso8601String(),
      'fire_drill_frequency': fireDrillFrequency,
      
      // Section 7: Management & Records
      'fire_log_book_maintained': fireLogBookMaintained,
      'fire_risk_assessment_review_date': fireRiskAssessmentReviewDate?.toIso8601String(),
      'fire_warden_appointed': fireWardenAppointed,
      'fire_warden_name': fireWardenName,
      'weekly_checks_recorded': weeklyChecksRecorded,
      'monthly_checks_recorded': monthlyChecksRecorded,
      
      // Section 8: Kitchen & High Risk Areas
      'kitchen_extractor_hood_cleaned': kitchenExtractorHoodCleaned,
      'extractor_cleaning_date': extractorCleaningDate?.toIso8601String(),
      'cooker_isolator_switch_accessible': cookerIsolatorSwitchAccessible,
      'laundry_dryer_lint_filter_cleaned': laundryDryerLintFilterCleaned,
      
      // Section 9: Electrical Fire Risks
      'pat_testing_up_to_date': patTestingUpToDate,
      'pat_test_expiry_date': patTestExpiryDate?.toIso8601String(),
      'electrical_equipment_not_overloaded': electricalEquipmentNotOverloaded,
      'charging_devices_on_non_flammable_surface': chargingDevicesOnNonFlammableSurface,
      
      // Section 10: Arson Prevention
      'external_waste_bins_away_from_building': externalWasteBinsAwayFromBuilding,
      'bin_stores_locked': binStoresLocked,
      'external_lighting_working': externalLightingWorking,
      'intruder_alarm_working': intruderAlarmWorking,
      
      // Calculated fields
      'total_score': totalScore,
      'risk_level': riskLevel,
      'action_required': actionRequired,
      
      // Action plan
      'action_items': actionItems,
      'responsible_person': responsiblePerson,
      'completion_deadline': completionDeadline?.toIso8601String(),
      'review_date': reviewDate?.toIso8601String(),
      
      // Audit fields
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }

  // Calculate total score based on all "yes" answers
  int calculateTotalScore() {
    int score = 0;

    // Section 1: Fire Detection & Warning (6 fields)
    if (smokeDetectorsPresent == 'yes') score++;
    if (smokeDetectorTestDate != null && smokeDetectorTestDate!.isAfter(DateTime.now().subtract(const Duration(days: 180)))) score++;
    if (heatDetectorsInKitchens == true) score++;
    if (fireAlarmSystemType == 'manual' || fireAlarmSystemType == 'automatic') score++;
    if (fireAlarmTestDate != null && fireAlarmTestDate!.isAfter(DateTime.now().subtract(const Duration(days: 7)))) score++;
    if (fireAlarmWeeklyTestRecorded == true) score++;

    // Section 2: Fire Fighting Equipment (8 fields)
    if (fireExtinguisherTypes != null && fireExtinguisherTypes!.isNotEmpty) score++;
    if (fireExtinguisherLocationsDocumented == true) score++;
    if (fireExtinguisherServiceDate != null && fireExtinguisherServiceDate!.isAfter(DateTime.now().subtract(const Duration(days: 365)))) score++;
    if (fireExtinguisherNextServiceDue != null && fireExtinguisherNextServiceDue!.isAfter(DateTime.now())) score++;
    if (fireBlanketInKitchen == true) score++;
    if (fireBlanketServiceDate != null && fireBlanketServiceDate!.isAfter(DateTime.now().subtract(const Duration(days: 365)))) score++;
    if (fireHoseReelPresent == true) score++;
    if (equipmentInspectedMonthly == true) score++;

    // Section 3: Means of Escape (8 fields)
    if (emergencyExitsClearlyMarked == true) score++;
    if (exitDoorsOpenEasily == true) score++;
    if (exitRoutesUnobstructed == true) score++;
    if (emergencyLightingWorking == true) score++;
    if (emergencyLightingTestDate != null && emergencyLightingTestDate!.isAfter(DateTime.now().subtract(const Duration(days: 30)))) score++;
    if (fireExitSignsIlluminated == true) score++;
    if (finalExitsOpenOutward == true) score++;
    if (escapeRoutesSuitableForMobilityAids == true) score++;

    // Section 4: Fire Doors & Compartmentation (6 fields)
    if (fireDoorsSelfClosing == true) score++;
    if (fireDoorGapsLessThan4mm == true) score++;
    if (fireDoorSealsIntact == true) score++;
    if (fireDoorInspectionDate != null && fireDoorInspectionDate!.isAfter(DateTime.now().subtract(const Duration(days: 180)))) score++;
    if (compartmentWallsIntact == true) score++;
    if (ceilingFloorPenetrationsSealed == true) score++;

    // Section 5: PEEPs & Evacuation (8 fields)
    if (peepsInPlaceForAllServiceUsers == 'yes') score++;
    if (peepsReviewedAnnually == true) score++;
    if (staffKnowPeepsForAssignedServiceUsers == true) score++;
    if (evacuationPlanDisplayed == true) score++;
    if (evacuationPlanRehearsed == true) score++;
    if (visitorsSignedInOut == true) score++;
    if (nightStaffNumbersAdequate == true) score++;
    if (disabledRefugePointsIdentified == true) score++;

    // Section 6: Training & Drills (6 fields)
    if (staffFireTrainingCompleted == true) score++;
    if (staffTrainingDate != null && staffTrainingDate!.isAfter(DateTime.now().subtract(const Duration(days: 365)))) score++;
    if (staffTrainingNextDue != null && staffTrainingNextDue!.isAfter(DateTime.now())) score++;
    if (fireDrillConducted == true) score++;
    if (fireDrillDate != null && fireDrillDate!.isAfter(DateTime.now().subtract(const Duration(days: 90)))) score++;
    if (fireDrillFrequency == 'monthly' || fireDrillFrequency == 'quarterly') score++;

    // Section 7: Management & Records (6 fields)
    if (fireLogBookMaintained == true) score++;
    if (fireRiskAssessmentReviewDate != null && fireRiskAssessmentReviewDate!.isAfter(DateTime.now().subtract(const Duration(days: 365)))) score++;
    if (fireWardenAppointed == true) score++;
    if (fireWardenName != null && fireWardenName!.isNotEmpty) score++;
    if (weeklyChecksRecorded == true) score++;
    if (monthlyChecksRecorded == true) score++;

    // Section 8: Kitchen & High Risk Areas (4 fields)
    if (kitchenExtractorHoodCleaned == true) score++;
    if (extractorCleaningDate != null && extractorCleaningDate!.isAfter(DateTime.now().subtract(const Duration(days: 90)))) score++;
    if (cookerIsolatorSwitchAccessible == true) score++;
    if (laundryDryerLintFilterCleaned == true) score++;

    // Section 9: Electrical Fire Risks (4 fields)
    if (patTestingUpToDate == true) score++;
    if (patTestExpiryDate != null && patTestExpiryDate!.isAfter(DateTime.now())) score++;
    if (electricalEquipmentNotOverloaded == true) score++;
    if (chargingDevicesOnNonFlammableSurface == true) score++;

    // Section 10: Arson Prevention (4 fields)
    if (externalWasteBinsAwayFromBuilding == true) score++;
    if (binStoresLocked == true) score++;
    if (externalLightingWorking == true) score++;
    if (intruderAlarmWorking == true) score++;

    return score;
  }

  // Determine risk level based on score
  String getRiskLevel(int score) {
    if (score <= 30) return 'high';
    if (score <= 45) return 'medium';
    if (score <= 55) return 'low';
    return 'excellent';
  }

  // Get action required based on risk level
  String getActionRequired(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return 'IMMEDIATE ACTION REQUIRED: High fire risk identified. Review and address all non-compliant items immediately.';
      case 'medium':
        return 'IMPROVEMENTS NEEDED: Medium fire risk identified. Address non-compliant items within 30 days.';
      case 'low':
        return 'MONITOR: Low fire risk identified. Continue monitoring and maintain current standards.';
      case 'excellent':
        return 'EXCELLENT: Fire safety standards are excellent. Maintain current practices.';
      default:
        return 'REVIEW REQUIRED: Please review the assessment.';
    }
  }

  // Get fire extinguisher types display text
  String getFireExtinguisherTypesDisplay() {
    if (fireExtinguisherTypes == null || fireExtinguisherTypes!.isEmpty) {
      return 'None';
    }
    return fireExtinguisherTypes!.join(', ');
  }

  // Check if fire extinguisher service is due soon (within 30 days)
  bool get isExtinguisherServiceDueSoon {
    return fireExtinguisherNextServiceDue != null && 
           fireExtinguisherNextServiceDue!.isBefore(DateTime.now().add(const Duration(days: 30)));
  }

  // Check if fire blanket service is due soon (within 30 days)
  bool get isBlanketServiceDueSoon {
    return fireBlanketServiceDate != null && 
           fireBlanketServiceDate!.isBefore(DateTime.now().add(const Duration(days: 30)));
  }

  // Check if staff training is due soon (within 30 days)
  bool get isTrainingDueSoon {
    return staffTrainingNextDue != null && 
           staffTrainingNextDue!.isBefore(DateTime.now().add(const Duration(days: 30)));
  }

  // Check if PAT test is due soon (within 30 days)
  bool get isPatTestDueSoon {
    return patTestExpiryDate != null && 
           patTestExpiryDate!.isBefore(DateTime.now().add(const Duration(days: 30)));
  }

  // Check if fire alarm test is overdue (more than 1 week)
  bool get isAlarmTestOverdue {
    return fireAlarmTestDate != null && 
           fireAlarmTestDate!.isBefore(DateTime.now().subtract(const Duration(days: 7)));
  }

  // Check if emergency lighting test is overdue (more than 1 month)
  bool get isEmergencyLightingTestOverdue {
    return emergencyLightingTestDate != null && 
           emergencyLightingTestDate!.isBefore(DateTime.now().subtract(const Duration(days: 30)));
  }

  // Get risk level emoji
  String get riskLevelEmoji {
    switch (riskLevel) {
      case 'high': return '🔴';
      case 'medium': return '🟠';
      case 'low': return '🟡';
      case 'excellent': return '🟢';
      default: return '⚪';
    }
  }

  // Get risk level color
  String get riskLevelColor {
    switch (riskLevel) {
      case 'high': return 'red';
      case 'medium': return 'orange';
      case 'low': return 'yellow';
      case 'excellent': return 'green';
      default: return 'grey';
    }
  }

  @override
  String toString() {
    return 'FireHazardAssessment(id: $id, serviceUserId: $serviceUserId, assessmentDate: $assessmentDate, assessorName: $assessorName, totalScore: $totalScore, riskLevel: $riskLevel, actionRequired: $actionRequired)';
  }

  FireHazardAssessment copyWith({
    String? id,
    String? serviceUserId,
    DateTime? assessmentDate,
    String? assessorName,
    String? smokeDetectorsPresent,
    DateTime? smokeDetectorTestDate,
    bool? heatDetectorsInKitchens,
    String? fireAlarmSystemType,
    DateTime? fireAlarmTestDate,
    bool? fireAlarmWeeklyTestRecorded,
    List<String>? fireExtinguisherTypes,
    bool? fireExtinguisherLocationsDocumented,
    DateTime? fireExtinguisherServiceDate,
    DateTime? fireExtinguisherNextServiceDue,
    bool? fireBlanketInKitchen,
    DateTime? fireBlanketServiceDate,
    bool? fireHoseReelPresent,
    bool? equipmentInspectedMonthly,
    bool? emergencyExitsClearlyMarked,
    bool? exitDoorsOpenEasily,
    bool? exitRoutesUnobstructed,
    bool? emergencyLightingWorking,
    DateTime? emergencyLightingTestDate,
    bool? fireExitSignsIlluminated,
    bool? finalExitsOpenOutward,
    bool? escapeRoutesSuitableForMobilityAids,
    bool? fireDoorsSelfClosing,
    bool? fireDoorGapsLessThan4mm,
    bool? fireDoorSealsIntact,
    DateTime? fireDoorInspectionDate,
    bool? compartmentWallsIntact,
    bool? ceilingFloorPenetrationsSealed,
    String? peepsInPlaceForAllServiceUsers,
    bool? peepsReviewedAnnually,
    bool? staffKnowPeepsForAssignedServiceUsers,
    bool? evacuationPlanDisplayed,
    bool? evacuationPlanRehearsed,
    bool? visitorsSignedInOut,
    bool? nightStaffNumbersAdequate,
    bool? disabledRefugePointsIdentified,
    bool? staffFireTrainingCompleted,
    DateTime? staffTrainingDate,
    DateTime? staffTrainingNextDue,
    bool? fireDrillConducted,
    DateTime? fireDrillDate,
    String? fireDrillFrequency,
    bool? fireLogBookMaintained,
    DateTime? fireRiskAssessmentReviewDate,
    bool? fireWardenAppointed,
    String? fireWardenName,
    bool? weeklyChecksRecorded,
    bool? monthlyChecksRecorded,
    bool? kitchenExtractorHoodCleaned,
    DateTime? extractorCleaningDate,
    bool? cookerIsolatorSwitchAccessible,
    bool? laundryDryerLintFilterCleaned,
    bool? patTestingUpToDate,
    DateTime? patTestExpiryDate,
    bool? electricalEquipmentNotOverloaded,
    bool? chargingDevicesOnNonFlammableSurface,
    bool? externalWasteBinsAwayFromBuilding,
    bool? binStoresLocked,
    bool? externalLightingWorking,
    bool? intruderAlarmWorking,
    int? totalScore,
    String? riskLevel,
    String? actionRequired,
    List<Map<String, dynamic>>? actionItems,
    String? responsiblePerson,
    DateTime? completionDeadline,
    DateTime? reviewDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return FireHazardAssessment(
      id: id ?? this.id,
      serviceUserId: serviceUserId ?? this.serviceUserId,
      assessmentDate: assessmentDate ?? this.assessmentDate,
      assessorName: assessorName ?? this.assessorName,
      smokeDetectorsPresent: smokeDetectorsPresent ?? this.smokeDetectorsPresent,
      smokeDetectorTestDate: smokeDetectorTestDate ?? this.smokeDetectorTestDate,
      heatDetectorsInKitchens: heatDetectorsInKitchens ?? this.heatDetectorsInKitchens,
      fireAlarmSystemType: fireAlarmSystemType ?? this.fireAlarmSystemType,
      fireAlarmTestDate: fireAlarmTestDate ?? this.fireAlarmTestDate,
      fireAlarmWeeklyTestRecorded: fireAlarmWeeklyTestRecorded ?? this.fireAlarmWeeklyTestRecorded,
      fireExtinguisherTypes: fireExtinguisherTypes ?? this.fireExtinguisherTypes,
      fireExtinguisherLocationsDocumented: fireExtinguisherLocationsDocumented ?? this.fireExtinguisherLocationsDocumented,
      fireExtinguisherServiceDate: fireExtinguisherServiceDate ?? this.fireExtinguisherServiceDate,
      fireExtinguisherNextServiceDue: fireExtinguisherNextServiceDue ?? this.fireExtinguisherNextServiceDue,
      fireBlanketInKitchen: fireBlanketInKitchen ?? this.fireBlanketInKitchen,
      fireBlanketServiceDate: fireBlanketServiceDate ?? this.fireBlanketServiceDate,
      fireHoseReelPresent: fireHoseReelPresent ?? this.fireHoseReelPresent,
      equipmentInspectedMonthly: equipmentInspectedMonthly ?? this.equipmentInspectedMonthly,
      emergencyExitsClearlyMarked: emergencyExitsClearlyMarked ?? this.emergencyExitsClearlyMarked,
      exitDoorsOpenEasily: exitDoorsOpenEasily ?? this.exitDoorsOpenEasily,
      exitRoutesUnobstructed: exitRoutesUnobstructed ?? this.exitRoutesUnobstructed,
      emergencyLightingWorking: emergencyLightingWorking ?? this.emergencyLightingWorking,
      emergencyLightingTestDate: emergencyLightingTestDate ?? this.emergencyLightingTestDate,
      fireExitSignsIlluminated: fireExitSignsIlluminated ?? this.fireExitSignsIlluminated,
      finalExitsOpenOutward: finalExitsOpenOutward ?? this.finalExitsOpenOutward,
      escapeRoutesSuitableForMobilityAids: escapeRoutesSuitableForMobilityAids ?? this.escapeRoutesSuitableForMobilityAids,
      fireDoorsSelfClosing: fireDoorsSelfClosing ?? this.fireDoorsSelfClosing,
      fireDoorGapsLessThan4mm: fireDoorGapsLessThan4mm ?? this.fireDoorGapsLessThan4mm,
      fireDoorSealsIntact: fireDoorSealsIntact ?? this.fireDoorSealsIntact,
      fireDoorInspectionDate: fireDoorInspectionDate ?? this.fireDoorInspectionDate,
      compartmentWallsIntact: compartmentWallsIntact ?? this.compartmentWallsIntact,
      ceilingFloorPenetrationsSealed: ceilingFloorPenetrationsSealed ?? this.ceilingFloorPenetrationsSealed,
      peepsInPlaceForAllServiceUsers: peepsInPlaceForAllServiceUsers ?? this.peepsInPlaceForAllServiceUsers,
      peepsReviewedAnnually: peepsReviewedAnnually ?? this.peepsReviewedAnnually,
      staffKnowPeepsForAssignedServiceUsers: staffKnowPeepsForAssignedServiceUsers ?? this.staffKnowPeepsForAssignedServiceUsers,
      evacuationPlanDisplayed: evacuationPlanDisplayed ?? this.evacuationPlanDisplayed,
      evacuationPlanRehearsed: evacuationPlanRehearsed ?? this.evacuationPlanRehearsed,
      visitorsSignedInOut: visitorsSignedInOut ?? this.visitorsSignedInOut,
      nightStaffNumbersAdequate: nightStaffNumbersAdequate ?? this.nightStaffNumbersAdequate,
      disabledRefugePointsIdentified: disabledRefugePointsIdentified ?? this.disabledRefugePointsIdentified,
      staffFireTrainingCompleted: staffFireTrainingCompleted ?? this.staffFireTrainingCompleted,
      staffTrainingDate: staffTrainingDate ?? this.staffTrainingDate,
      staffTrainingNextDue: staffTrainingNextDue ?? this.staffTrainingNextDue,
      fireDrillConducted: fireDrillConducted ?? this.fireDrillConducted,
      fireDrillDate: fireDrillDate ?? this.fireDrillDate,
      fireDrillFrequency: fireDrillFrequency ?? this.fireDrillFrequency,
      fireLogBookMaintained: fireLogBookMaintained ?? this.fireLogBookMaintained,
      fireRiskAssessmentReviewDate: fireRiskAssessmentReviewDate ?? this.fireRiskAssessmentReviewDate,
      fireWardenAppointed: fireWardenAppointed ?? this.fireWardenAppointed,
      fireWardenName: fireWardenName ?? this.fireWardenName,
      weeklyChecksRecorded: weeklyChecksRecorded ?? this.weeklyChecksRecorded,
      monthlyChecksRecorded: monthlyChecksRecorded ?? this.monthlyChecksRecorded,
      kitchenExtractorHoodCleaned: kitchenExtractorHoodCleaned ?? this.kitchenExtractorHoodCleaned,
      extractorCleaningDate: extractorCleaningDate ?? this.extractorCleaningDate,
      cookerIsolatorSwitchAccessible: cookerIsolatorSwitchAccessible ?? this.cookerIsolatorSwitchAccessible,
      laundryDryerLintFilterCleaned: laundryDryerLintFilterCleaned ?? this.laundryDryerLintFilterCleaned,
      patTestingUpToDate: patTestingUpToDate ?? this.patTestingUpToDate,
      patTestExpiryDate: patTestExpiryDate ?? this.patTestExpiryDate,
      electricalEquipmentNotOverloaded: electricalEquipmentNotOverloaded ?? this.electricalEquipmentNotOverloaded,
      chargingDevicesOnNonFlammableSurface: chargingDevicesOnNonFlammableSurface ?? this.chargingDevicesOnNonFlammableSurface,
      externalWasteBinsAwayFromBuilding: externalWasteBinsAwayFromBuilding ?? this.externalWasteBinsAwayFromBuilding,
      binStoresLocked: binStoresLocked ?? this.binStoresLocked,
      externalLightingWorking: externalLightingWorking ?? this.externalLightingWorking,
      intruderAlarmWorking: intruderAlarmWorking ?? this.intruderAlarmWorking,
      totalScore: totalScore ?? this.totalScore,
      riskLevel: riskLevel ?? this.riskLevel,
      actionRequired: actionRequired ?? this.actionRequired,
      actionItems: actionItems ?? this.actionItems,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      completionDeadline: completionDeadline ?? this.completionDeadline,
      reviewDate: reviewDate ?? this.reviewDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is FireHazardAssessment &&
      other.id == id &&
      other.serviceUserId == serviceUserId &&
      other.assessmentDate == assessmentDate &&
      other.assessorName == assessorName &&
      other.smokeDetectorsPresent == smokeDetectorsPresent &&
      other.smokeDetectorTestDate == smokeDetectorTestDate &&
      other.heatDetectorsInKitchens == heatDetectorsInKitchens &&
      other.fireAlarmSystemType == fireAlarmSystemType &&
      other.fireAlarmTestDate == fireAlarmTestDate &&
      other.fireAlarmWeeklyTestRecorded == fireAlarmWeeklyTestRecorded &&
      other.fireExtinguisherTypes == fireExtinguisherTypes &&
      other.fireExtinguisherLocationsDocumented == fireExtinguisherLocationsDocumented &&
      other.fireExtinguisherServiceDate == fireExtinguisherServiceDate &&
      other.fireExtinguisherNextServiceDue == fireExtinguisherNextServiceDue &&
      other.fireBlanketInKitchen == fireBlanketInKitchen &&
      other.fireBlanketServiceDate == fireBlanketServiceDate &&
      other.fireHoseReelPresent == fireHoseReelPresent &&
      other.equipmentInspectedMonthly == equipmentInspectedMonthly &&
      other.emergencyExitsClearlyMarked == emergencyExitsClearlyMarked &&
      other.exitDoorsOpenEasily == exitDoorsOpenEasily &&
      other.exitRoutesUnobstructed == exitRoutesUnobstructed &&
      other.emergencyLightingWorking == emergencyLightingWorking &&
      other.emergencyLightingTestDate == emergencyLightingTestDate &&
      other.fireExitSignsIlluminated == fireExitSignsIlluminated &&
      other.finalExitsOpenOutward == finalExitsOpenOutward &&
      other.escapeRoutesSuitableForMobilityAids == escapeRoutesSuitableForMobilityAids &&
      other.fireDoorsSelfClosing == fireDoorsSelfClosing &&
      other.fireDoorGapsLessThan4mm == fireDoorGapsLessThan4mm &&
      other.fireDoorSealsIntact == fireDoorSealsIntact &&
      other.fireDoorInspectionDate == fireDoorInspectionDate &&
      other.compartmentWallsIntact == compartmentWallsIntact &&
      other.ceilingFloorPenetrationsSealed == ceilingFloorPenetrationsSealed &&
      other.peepsInPlaceForAllServiceUsers == peepsInPlaceForAllServiceUsers &&
      other.peepsReviewedAnnually == peepsReviewedAnnually &&
      other.staffKnowPeepsForAssignedServiceUsers == staffKnowPeepsForAssignedServiceUsers &&
      other.evacuationPlanDisplayed == evacuationPlanDisplayed &&
      other.evacuationPlanRehearsed == evacuationPlanRehearsed &&
      other.visitorsSignedInOut == visitorsSignedInOut &&
      other.nightStaffNumbersAdequate == nightStaffNumbersAdequate &&
      other.disabledRefugePointsIdentified == disabledRefugePointsIdentified &&
      other.staffFireTrainingCompleted == staffFireTrainingCompleted &&
      other.staffTrainingDate == staffTrainingDate &&
      other.staffTrainingNextDue == staffTrainingNextDue &&
      other.fireDrillConducted == fireDrillConducted &&
      other.fireDrillDate == fireDrillDate &&
      other.fireDrillFrequency == fireDrillFrequency &&
      other.fireLogBookMaintained == fireLogBookMaintained &&
      other.fireRiskAssessmentReviewDate == fireRiskAssessmentReviewDate &&
      other.fireWardenAppointed == fireWardenAppointed &&
      other.fireWardenName == fireWardenName &&
      other.weeklyChecksRecorded == weeklyChecksRecorded &&
      other.monthlyChecksRecorded == monthlyChecksRecorded &&
      other.kitchenExtractorHoodCleaned == kitchenExtractorHoodCleaned &&
      other.extractorCleaningDate == extractorCleaningDate &&
      other.cookerIsolatorSwitchAccessible == cookerIsolatorSwitchAccessible &&
      other.laundryDryerLintFilterCleaned == laundryDryerLintFilterCleaned &&
      other.patTestingUpToDate == patTestingUpToDate &&
      other.patTestExpiryDate == patTestExpiryDate &&
      other.electricalEquipmentNotOverloaded == electricalEquipmentNotOverloaded &&
      other.chargingDevicesOnNonFlammableSurface == chargingDevicesOnNonFlammableSurface &&
      other.externalWasteBinsAwayFromBuilding == externalWasteBinsAwayFromBuilding &&
      other.binStoresLocked == binStoresLocked &&
      other.externalLightingWorking == externalLightingWorking &&
      other.intruderAlarmWorking == intruderAlarmWorking &&
      other.totalScore == totalScore &&
      other.riskLevel == riskLevel &&
      other.actionRequired == actionRequired &&
      other.actionItems == actionItems &&
      other.responsiblePerson == responsiblePerson &&
      other.completionDeadline == completionDeadline &&
      other.reviewDate == reviewDate &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.createdBy == createdBy &&
      other.updatedBy == updatedBy;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      serviceUserId.hashCode ^
      assessmentDate.hashCode ^
      assessorName.hashCode ^
      smokeDetectorsPresent.hashCode ^
      smokeDetectorTestDate.hashCode ^
      heatDetectorsInKitchens.hashCode ^
      fireAlarmSystemType.hashCode ^
      fireAlarmTestDate.hashCode ^
      fireAlarmWeeklyTestRecorded.hashCode ^
      fireExtinguisherTypes.hashCode ^
      fireExtinguisherLocationsDocumented.hashCode ^
      fireExtinguisherServiceDate.hashCode ^
      fireExtinguisherNextServiceDue.hashCode ^
      fireBlanketInKitchen.hashCode ^
      fireBlanketServiceDate.hashCode ^
      fireHoseReelPresent.hashCode ^
      equipmentInspectedMonthly.hashCode ^
      emergencyExitsClearlyMarked.hashCode ^
      exitDoorsOpenEasily.hashCode ^
      exitRoutesUnobstructed.hashCode ^
      emergencyLightingWorking.hashCode ^
      emergencyLightingTestDate.hashCode ^
      fireExitSignsIlluminated.hashCode ^
      finalExitsOpenOutward.hashCode ^
      escapeRoutesSuitableForMobilityAids.hashCode ^
      fireDoorsSelfClosing.hashCode ^
      fireDoorGapsLessThan4mm.hashCode ^
      fireDoorSealsIntact.hashCode ^
      fireDoorInspectionDate.hashCode ^
      compartmentWallsIntact.hashCode ^
      ceilingFloorPenetrationsSealed.hashCode ^
      peepsInPlaceForAllServiceUsers.hashCode ^
      peepsReviewedAnnually.hashCode ^
      staffKnowPeepsForAssignedServiceUsers.hashCode ^
      evacuationPlanDisplayed.hashCode ^
      evacuationPlanRehearsed.hashCode ^
      visitorsSignedInOut.hashCode ^
      nightStaffNumbersAdequate.hashCode ^
      disabledRefugePointsIdentified.hashCode ^
      staffFireTrainingCompleted.hashCode ^
      staffTrainingDate.hashCode ^
      staffTrainingNextDue.hashCode ^
      fireDrillConducted.hashCode ^
      fireDrillDate.hashCode ^
      fireDrillFrequency.hashCode ^
      fireLogBookMaintained.hashCode ^
      fireRiskAssessmentReviewDate.hashCode ^
      fireWardenAppointed.hashCode ^
      fireWardenName.hashCode ^
      weeklyChecksRecorded.hashCode ^
      monthlyChecksRecorded.hashCode ^
      kitchenExtractorHoodCleaned.hashCode ^
      extractorCleaningDate.hashCode ^
      cookerIsolatorSwitchAccessible.hashCode ^
      laundryDryerLintFilterCleaned.hashCode ^
      patTestingUpToDate.hashCode ^
      patTestExpiryDate.hashCode ^
      electricalEquipmentNotOverloaded.hashCode ^
      chargingDevicesOnNonFlammableSurface.hashCode ^
      externalWasteBinsAwayFromBuilding.hashCode ^
      binStoresLocked.hashCode ^
      externalLightingWorking.hashCode ^
      intruderAlarmWorking.hashCode ^
      totalScore.hashCode ^
      riskLevel.hashCode ^
      actionRequired.hashCode ^
      actionItems.hashCode ^
      responsiblePerson.hashCode ^
      completionDeadline.hashCode ^
      reviewDate.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      createdBy.hashCode ^
      updatedBy.hashCode;
  }
}