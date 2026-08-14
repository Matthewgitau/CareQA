import 'dart:convert';

class EquipmentRegisterAssessment {
  final String? id;
  final String equipmentId;
  final String equipmentName;
  final String equipmentCategory;
  final String? serialNumber;
  final String? manufacturer;
  final String? supplier;
  final DateTime? purchaseDate;
  final DateTime? lastServiceDate;
  final DateTime? nextServiceDueDate;
  final String? serviceProvider;
  final DateTime? patTestDate;
  final DateTime? patTestExpiry;
  final DateTime? lolerTestDate;
  final DateTime? lolerTestExpiry;
  final bool dailyChecksCompleted;
  final bool weeklyChecksCompleted;
  final bool monthlyChecksCompleted;
  final String equipmentCondition;
  final String reportedFaults;
  final DateTime? faultReportedDate;
  final DateTime? faultResolvedDate;
  final bool staffTrained;
  final bool trainingRecordAvailable;
  final String riskLevel;
  final String? actionRequired;
  final DateTime? reviewDate;
  final String? assessorName;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EquipmentRegisterAssessment({
    this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentCategory,
    this.serialNumber,
    this.manufacturer,
    this.supplier,
    this.purchaseDate,
    this.lastServiceDate,
    this.nextServiceDueDate,
    this.serviceProvider,
    this.patTestDate,
    this.patTestExpiry,
    this.lolerTestDate,
    this.lolerTestExpiry,
    this.dailyChecksCompleted = false,
    this.weeklyChecksCompleted = false,
    this.monthlyChecksCompleted = false,
    this.equipmentCondition = 'good',
    this.reportedFaults = 'none',
    this.faultReportedDate,
    this.faultResolvedDate,
    this.staffTrained = false,
    this.trainingRecordAvailable = false,
    this.riskLevel = 'low',
    this.actionRequired,
    this.reviewDate,
    this.assessorName,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory EquipmentRegisterAssessment.fromJson(Map<String, dynamic> json) {
    return EquipmentRegisterAssessment(
      id: json['id'],
      equipmentId: json['equipment_id'],
      equipmentName: json['equipment_name'],
      equipmentCategory: json['equipment_category'],
      serialNumber: json['serial_number'],
      manufacturer: json['manufacturer'],
      supplier: json['supplier'],
      purchaseDate: json['purchase_date'] != null 
          ? DateTime.parse(json['purchase_date']) 
          : null,
      lastServiceDate: json['last_service_date'] != null 
          ? DateTime.parse(json['last_service_date']) 
          : null,
      nextServiceDueDate: json['next_service_due_date'] != null 
          ? DateTime.parse(json['next_service_due_date']) 
          : null,
      serviceProvider: json['service_provider'],
      patTestDate: json['pat_test_date'] != null 
          ? DateTime.parse(json['pat_test_date']) 
          : null,
      patTestExpiry: json['pat_test_expiry'] != null 
          ? DateTime.parse(json['pat_test_expiry']) 
          : null,
      lolerTestDate: json['loler_test_date'] != null 
          ? DateTime.parse(json['loler_test_date']) 
          : null,
      lolerTestExpiry: json['loler_test_expiry'] != null 
          ? DateTime.parse(json['loler_test_expiry']) 
          : null,
      dailyChecksCompleted: json['daily_checks_completed'] ?? false,
      weeklyChecksCompleted: json['weekly_checks_completed'] ?? false,
      monthlyChecksCompleted: json['monthly_checks_completed'] ?? false,
      equipmentCondition: json['equipment_condition'] ?? 'good',
      reportedFaults: json['reported_faults'] ?? 'none',
      faultReportedDate: json['fault_reported_date'] != null 
          ? DateTime.parse(json['fault_reported_date']) 
          : null,
      faultResolvedDate: json['fault_resolved_date'] != null 
          ? DateTime.parse(json['fault_resolved_date']) 
          : null,
      staffTrained: json['staff_trained'] ?? false,
      trainingRecordAvailable: json['training_record_available'] ?? false,
      riskLevel: json['risk_level'] ?? 'low',
      actionRequired: json['action_required'],
      reviewDate: json['review_date'] != null 
          ? DateTime.parse(json['review_date']) 
          : null,
      assessorName: json['assessor_name'],
      notes: json['notes'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipment_id': equipmentId,
      'equipment_name': equipmentName,
      'equipment_category': equipmentCategory,
      'serial_number': serialNumber,
      'manufacturer': manufacturer,
      'supplier': supplier,
      'purchase_date': purchaseDate?.toIso8601String(),
      'last_service_date': lastServiceDate?.toIso8601String(),
      'next_service_due_date': nextServiceDueDate?.toIso8601String(),
      'service_provider': serviceProvider,
      'pat_test_date': patTestDate?.toIso8601String(),
      'pat_test_expiry': patTestExpiry?.toIso8601String(),
      'loler_test_date': lolerTestDate?.toIso8601String(),
      'loler_test_expiry': lolerTestExpiry?.toIso8601String(),
      'daily_checks_completed': dailyChecksCompleted,
      'weekly_checks_completed': weeklyChecksCompleted,
      'monthly_checks_completed': monthlyChecksCompleted,
      'equipment_condition': equipmentCondition,
      'reported_faults': reportedFaults,
      'fault_reported_date': faultReportedDate?.toIso8601String(),
      'fault_resolved_date': faultResolvedDate?.toIso8601String(),
      'staff_trained': staffTrained,
      'training_record_available': trainingRecordAvailable,
      'risk_level': riskLevel,
      'action_required': actionRequired,
      'review_date': reviewDate?.toIso8601String(),
      'assessor_name': assessorName,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Calculate if LOLER test is expired
  bool get lolerExpired {
    if (lolerTestExpiry == null) return false;
    return lolerTestExpiry!.isBefore(DateTime.now());
  }

  // Calculate if PAT test is expired
  bool get patExpired {
    if (patTestExpiry == null) return false;
    return patTestExpiry!.isBefore(DateTime.now());
  }

  // Calculate days until next service
  int? get daysUntilService {
    if (nextServiceDueDate == null) return null;
    return nextServiceDueDate!.difference(DateTime.now()).inDays;
  }

  // Calculate if service is due
  bool get serviceDue {
    if (nextServiceDueDate == null) return false;
    return nextServiceDueDate!.isBefore(DateTime.now());
  }

  // Calculate if review is due
  bool get reviewDue {
    if (reviewDate == null) return false;
    return reviewDate!.isBefore(DateTime.now());
  }

  // Calculate if equipment is safe for use
  bool get isSafeForUse {
    // Equipment is unsafe if LOLER expired, has major fault, or condition is unsafe
    if (lolerExpired || reportedFaults == 'major' || equipmentCondition == 'unsafe') {
      return false;
    }
    return true;
  }

  // Get equipment status text
  String get equipmentStatus {
    if (!isSafeForUse) {
      return 'UNSAFE';
    }
    if (serviceDue) {
      return 'SERVICE DUE';
    }
    if (lolerExpired) {
      return 'LOLER EXPIRED';
    }
    if (patExpired) {
      return 'PAT EXPIRED';
    }
    if (reportedFaults != 'none') {
      return 'FAULT REPORTED';
    }
    return 'SAFE';
  }

  // Get equipment status color
  String get equipmentStatusColor {
    if (!isSafeForUse) {
      return 'red';
    }
    if (serviceDue || lolerExpired || patExpired || reportedFaults != 'none') {
      return 'orange';
    }
    return 'green';
  }

  // Get risk level emoji
  String get riskLevelEmoji {
    switch (riskLevel) {
      case 'critical': return '🔴';
      case 'high': return '🟠';
      case 'medium': return '🟡';
      case 'low': return '🟢';
      default: return '⚪';
    }
  }

  // Get equipment category display text
  String get equipmentCategoryDisplay {
    switch (equipmentCategory) {
      case 'hoist': return 'Hoist';
      case 'wheelchair': return 'Wheelchair';
      case 'bed': return 'Bed';
      case 'chair': return 'Chair';
      case 'other': return 'Other';
      default: return equipmentCategory;
    }
  }

  // Get equipment condition display text
  String get equipmentConditionDisplay {
    switch (equipmentCondition) {
      case 'good': return 'Good';
      case 'worn': return 'Worn';
      case 'damaged': return 'Damaged';
      case 'unsafe': return 'Unsafe';
      default: return equipmentCondition;
    }
  }

  // Get reported faults display text
  String get reportedFaultsDisplay {
    switch (reportedFaults) {
      case 'none': return 'None';
      case 'minor': return 'Minor';
      case 'major': return 'Major';
      default: return reportedFaults;
    }
  }

  // Calculate risk level based on equipment status
  String calculateRiskLevel() {
    // Critical risk conditions
    if (lolerExpired || equipmentCondition == 'unsafe' || reportedFaults == 'major') {
      return 'critical';
    }
    
    // High risk conditions
    if (patExpired || equipmentCondition == 'damaged') {
      return 'high';
    }
    
    // Medium risk conditions
    if (equipmentCondition == 'worn' || 
        !dailyChecksCompleted || 
        !weeklyChecksCompleted || 
        !monthlyChecksCompleted) {
      return 'medium';
    }
    
    // Low risk
    return 'low';
  }

  // Get action required based on equipment status
  String? getActionRequired() {
    if (lolerExpired) {
      return 'LOLER test expired - Remove from service immediately';
    }
    if (patExpired) {
      return 'PAT test expired - Schedule electrical safety test';
    }
    if (reportedFaults == 'major') {
      return 'Major fault reported - Remove from service until repaired';
    }
    if (equipmentCondition == 'unsafe') {
      return 'Equipment unsafe - Remove from service immediately';
    }
    if (serviceDue) {
      return 'Service due - Schedule maintenance';
    }
    if (!staffTrained) {
      return 'Staff training required - Ensure all users are trained';
    }
    if (!trainingRecordAvailable) {
      return 'Training records missing - Update training documentation';
    }
    return null;
  }

  @override
  String toString() {
    return 'EquipmentRegisterAssessment(id: $id, equipmentId: $equipmentId, equipmentName: $equipmentName, equipmentCategory: $equipmentCategory, serialNumber: $serialNumber, manufacturer: $manufacturer, supplier: $supplier, purchaseDate: $purchaseDate, lastServiceDate: $lastServiceDate, nextServiceDueDate: $nextServiceDueDate, serviceProvider: $serviceProvider, patTestDate: $patTestDate, patTestExpiry: $patTestExpiry, lolerTestDate: $lolerTestDate, lolerTestExpiry: $lolerTestExpiry, dailyChecksCompleted: $dailyChecksCompleted, weeklyChecksCompleted: $weeklyChecksCompleted, monthlyChecksCompleted: $monthlyChecksCompleted, equipmentCondition: $equipmentCondition, reportedFaults: $reportedFaults, faultReportedDate: $faultReportedDate, faultResolvedDate: $faultResolvedDate, staffTrained: $staffTrained, trainingRecordAvailable: $trainingRecordAvailable, riskLevel: $riskLevel, actionRequired: $actionRequired, reviewDate: $reviewDate, assessorName: $assessorName, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  EquipmentRegisterAssessment copyWith({
    String? id,
    String? equipmentId,
    String? equipmentName,
    String? equipmentCategory,
    String? serialNumber,
    String? manufacturer,
    String? supplier,
    DateTime? purchaseDate,
    DateTime? lastServiceDate,
    DateTime? nextServiceDueDate,
    String? serviceProvider,
    DateTime? patTestDate,
    DateTime? patTestExpiry,
    DateTime? lolerTestDate,
    DateTime? lolerTestExpiry,
    bool? dailyChecksCompleted,
    bool? weeklyChecksCompleted,
    bool? monthlyChecksCompleted,
    String? equipmentCondition,
    String? reportedFaults,
    DateTime? faultReportedDate,
    DateTime? faultResolvedDate,
    bool? staffTrained,
    bool? trainingRecordAvailable,
    String? riskLevel,
    String? actionRequired,
    DateTime? reviewDate,
    String? assessorName,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EquipmentRegisterAssessment(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      equipmentCategory: equipmentCategory ?? this.equipmentCategory,
      serialNumber: serialNumber ?? this.serialNumber,
      manufacturer: manufacturer ?? this.manufacturer,
      supplier: supplier ?? this.supplier,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      nextServiceDueDate: nextServiceDueDate ?? this.nextServiceDueDate,
      serviceProvider: serviceProvider ?? this.serviceProvider,
      patTestDate: patTestDate ?? this.patTestDate,
      patTestExpiry: patTestExpiry ?? this.patTestExpiry,
      lolerTestDate: lolerTestDate ?? this.lolerTestDate,
      lolerTestExpiry: lolerTestExpiry ?? this.lolerTestExpiry,
      dailyChecksCompleted: dailyChecksCompleted ?? this.dailyChecksCompleted,
      weeklyChecksCompleted: weeklyChecksCompleted ?? this.weeklyChecksCompleted,
      monthlyChecksCompleted: monthlyChecksCompleted ?? this.monthlyChecksCompleted,
      equipmentCondition: equipmentCondition ?? this.equipmentCondition,
      reportedFaults: reportedFaults ?? this.reportedFaults,
      faultReportedDate: faultReportedDate ?? this.faultReportedDate,
      faultResolvedDate: faultResolvedDate ?? this.faultResolvedDate,
      staffTrained: staffTrained ?? this.staffTrained,
      trainingRecordAvailable: trainingRecordAvailable ?? this.trainingRecordAvailable,
      riskLevel: riskLevel ?? this.riskLevel,
      actionRequired: actionRequired ?? this.actionRequired,
      reviewDate: reviewDate ?? this.reviewDate,
      assessorName: assessorName ?? this.assessorName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is EquipmentRegisterAssessment &&
      other.id == id &&
      other.equipmentId == equipmentId &&
      other.equipmentName == equipmentName &&
      other.equipmentCategory == equipmentCategory &&
      other.serialNumber == serialNumber &&
      other.manufacturer == manufacturer &&
      other.supplier == supplier &&
      other.purchaseDate == purchaseDate &&
      other.lastServiceDate == lastServiceDate &&
      other.nextServiceDueDate == nextServiceDueDate &&
      other.serviceProvider == serviceProvider &&
      other.patTestDate == patTestDate &&
      other.patTestExpiry == patTestExpiry &&
      other.lolerTestDate == lolerTestDate &&
      other.lolerTestExpiry == lolerTestExpiry &&
      other.dailyChecksCompleted == dailyChecksCompleted &&
      other.weeklyChecksCompleted == weeklyChecksCompleted &&
      other.monthlyChecksCompleted == monthlyChecksCompleted &&
      other.equipmentCondition == equipmentCondition &&
      other.reportedFaults == reportedFaults &&
      other.faultReportedDate == faultReportedDate &&
      other.faultResolvedDate == faultResolvedDate &&
      other.staffTrained == staffTrained &&
      other.trainingRecordAvailable == trainingRecordAvailable &&
      other.riskLevel == riskLevel &&
      other.actionRequired == actionRequired &&
      other.reviewDate == reviewDate &&
      other.assessorName == assessorName &&
      other.notes == notes &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      equipmentId.hashCode ^
      equipmentName.hashCode ^
      equipmentCategory.hashCode ^
      serialNumber.hashCode ^
      manufacturer.hashCode ^
      supplier.hashCode ^
      purchaseDate.hashCode ^
      lastServiceDate.hashCode ^
      nextServiceDueDate.hashCode ^
      serviceProvider.hashCode ^
      patTestDate.hashCode ^
      patTestExpiry.hashCode ^
      lolerTestDate.hashCode ^
      lolerTestExpiry.hashCode ^
      dailyChecksCompleted.hashCode ^
      weeklyChecksCompleted.hashCode ^
      monthlyChecksCompleted.hashCode ^
      equipmentCondition.hashCode ^
      reportedFaults.hashCode ^
      faultReportedDate.hashCode ^
      faultResolvedDate.hashCode ^
      staffTrained.hashCode ^
      trainingRecordAvailable.hashCode ^
      riskLevel.hashCode ^
      actionRequired.hashCode ^
      reviewDate.hashCode ^
      assessorName.hashCode ^
      notes.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
  }
}