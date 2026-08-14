// Pure Dart model — no Flutter imports

class MarMedication {
  final String? id;
  final String? serviceUserId;
  final String? serviceUserName;

  // Medication details
  final String medicationName;
  final String dosage;
  final String? dosageUnit;
  final String? strength;
  final String? form;

  // Schedule
  final String frequency; // once_daily, twice_daily, three_times_daily, four_times_daily, as_required
  final List<String>? frequencyTimes;
  final int? timesPerDay;
  final List<int>? daysOfWeek; // 0=Sunday to 6=Saturday, null = daily

  // Duration
  final DateTime startDate;
  final DateTime? endDate;
  final bool isOngoing;

  // Administration instructions
  final String? specialInstructions;
  final String? administrationRoute;

  // Prescriber info
  final String? prescribedBy;
  final DateTime? prescribedDate;

  // Pharmacy info
  final String? pharmacyName;
  final String? pharmacyPhone;

  // Status
  final bool isActive;
  final bool isPrn;

  // Stopping info
  final DateTime? stoppedDate;
  final String? stoppedReason;

  // Stock/Supply
  final int? stockQuantity;
  final String? stockUnit;
  final int? reorderLevel;
  final DateTime? lastOrderedDate;
  final DateTime? nextRefillDue;

  // Audit
  final String? createdBy;
  final DateTime? createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;
  final String? organisationId;

  // Soft delete
  final DateTime? deletedAt;
  final String? deletedBy;

  MarMedication({
    this.id,
    this.serviceUserId,
    this.serviceUserName,
    required this.medicationName,
    required this.dosage,
    this.dosageUnit,
    this.strength,
    this.form,
    required this.frequency,
    this.frequencyTimes,
    this.timesPerDay,
    this.daysOfWeek,
    required this.startDate,
    this.endDate,
    this.isOngoing = true,
    this.specialInstructions,
    this.administrationRoute,
    this.prescribedBy,
    this.prescribedDate,
    this.pharmacyName,
    this.pharmacyPhone,
    this.isActive = true,
    this.isPrn = false,
    this.stoppedDate,
    this.stoppedReason,
    this.stockQuantity,
    this.stockUnit,
    this.reorderLevel,
    this.lastOrderedDate,
    this.nextRefillDue,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.organisationId,
    this.deletedAt,
    this.deletedBy,
  });

  factory MarMedication.fromMap(Map<String, dynamic> map) {
    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value.toLocal();
      return DateTime.parse(value.toString()).toLocal();
    }

    DateTime? _parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value.toLocal();
      return DateTime.tryParse(value.toString())?.toLocal();
    }

    int? _parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return MarMedication(
      id: map['id'],
      serviceUserId: map['service_user_id'],
      serviceUserName: map['service_user_name'],
      medicationName: map['medication_name'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      dosageUnit: map['dosage_unit'],
      strength: map['strength'],
      form: map['form'],
      frequency: map['frequency'] as String? ?? 'once_daily',
      frequencyTimes: map['frequency_times'] != null
          ? List<String>.from(map['frequency_times'])
          : null,
      timesPerDay: _parseInt(map['times_per_day']),
      daysOfWeek: map['days_of_week'] != null
          ? List<int>.from(map['days_of_week'])
          : null,
      startDate: _parseDate(map['start_date']),
      endDate: _parseNullableDate(map['end_date']),
      isOngoing: map['is_ongoing'] as bool? ?? true,
      specialInstructions: map['special_instructions'],
      administrationRoute: map['administration_route'],
      prescribedBy: map['prescribed_by'],
      prescribedDate: _parseNullableDate(map['prescribed_date']),
      pharmacyName: map['pharmacy_name'],
      pharmacyPhone: map['pharmacy_phone'],
      isActive: map['is_active'] as bool? ?? true,
      isPrn: map['is_prn'] as bool? ?? false,
      stoppedDate: _parseNullableDate(map['stopped_date']),
      stoppedReason: map['stopped_reason'],
      stockQuantity: _parseInt(map['stock_quantity']),
      stockUnit: map['stock_unit'],
      reorderLevel: _parseInt(map['reorder_level']),
      lastOrderedDate: _parseNullableDate(map['last_ordered_date']),
      nextRefillDue: _parseNullableDate(map['next_refill_due']),
      createdBy: map['created_by'],
      createdAt: _parseNullableDate(map['created_at']),
      updatedBy: map['updated_by'],
      updatedAt: _parseNullableDate(map['updated_at']),
      organisationId: map['organisation_id'],
      deletedAt: _parseNullableDate(map['deleted_at']),
      deletedBy: map['deleted_by'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'service_user_id': serviceUserId,
      'service_user_name': serviceUserName,
      'medication_name': medicationName,
      'dosage': dosage,
      'dosage_unit': dosageUnit,
      'strength': strength,
      'form': form,
      'frequency': frequency,
      'frequency_times': frequencyTimes,
      'times_per_day': timesPerDay,
      'days_of_week': daysOfWeek,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'is_ongoing': isOngoing,
      'special_instructions': specialInstructions,
      'administration_route': administrationRoute,
      'prescribed_by': prescribedBy,
      'prescribed_date': prescribedDate?.toIso8601String().split('T').first,
      'pharmacy_name': pharmacyName,
      'pharmacy_phone': pharmacyPhone,
      'is_active': isActive,
      'is_prn': isPrn,
      'stopped_date': stoppedDate?.toIso8601String().split('T').first,
      'stopped_reason': stoppedReason,
      'stock_quantity': stockQuantity,
      'stock_unit': stockUnit,
      'reorder_level': reorderLevel,
      'last_ordered_date': lastOrderedDate?.toIso8601String().split('T').first,
      'next_refill_due': nextRefillDue?.toIso8601String().split('T').first,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_by': updatedBy,
      'updated_at': updatedAt?.toIso8601String(),
      'organisation_id': organisationId,
      'deleted_at': deletedAt?.toIso8601String(),
      'deleted_by': deletedBy,
    };
  }

  /// Create a copy with updated fields
  MarMedication copyWith({
    String? id,
    String? serviceUserId,
    String? serviceUserName,
    String? medicationName,
    String? dosage,
    String? dosageUnit,
    String? strength,
    String? form,
    String? frequency,
    List<String>? frequencyTimes,
    int? timesPerDay,
    List<int>? daysOfWeek,
    DateTime? startDate,
    DateTime? endDate,
    bool? isOngoing,
    String? specialInstructions,
    String? administrationRoute,
    String? prescribedBy,
    DateTime? prescribedDate,
    String? pharmacyName,
    String? pharmacyPhone,
    bool? isActive,
    bool? isPrn,
    DateTime? stoppedDate,
    String? stoppedReason,
    int? stockQuantity,
    String? stockUnit,
    int? reorderLevel,
    DateTime? lastOrderedDate,
    DateTime? nextRefillDue,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    String? organisationId,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return MarMedication(
      id: id ?? this.id,
      serviceUserId: serviceUserId ?? this.serviceUserId,
      serviceUserName: serviceUserName ?? this.serviceUserName,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      strength: strength ?? this.strength,
      form: form ?? this.form,
      frequency: frequency ?? this.frequency,
      frequencyTimes: frequencyTimes ?? this.frequencyTimes,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isOngoing: isOngoing ?? this.isOngoing,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      administrationRoute: administrationRoute ?? this.administrationRoute,
      prescribedBy: prescribedBy ?? this.prescribedBy,
      prescribedDate: prescribedDate ?? this.prescribedDate,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      pharmacyPhone: pharmacyPhone ?? this.pharmacyPhone,
      isActive: isActive ?? this.isActive,
      isPrn: isPrn ?? this.isPrn,
      stoppedDate: stoppedDate ?? this.stoppedDate,
      stoppedReason: stoppedReason ?? this.stoppedReason,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      stockUnit: stockUnit ?? this.stockUnit,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      lastOrderedDate: lastOrderedDate ?? this.lastOrderedDate,
      nextRefillDue: nextRefillDue ?? this.nextRefillDue,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      organisationId: organisationId ?? this.organisationId,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  /// Helper to get display-friendly frequency label
  String get frequencyLabel {
    switch (frequency) {
      case 'once_daily':
        return 'Once Daily';
      case 'twice_daily':
        return 'Twice Daily';
      case 'three_times_daily':
        return 'Three Times Daily';
      case 'four_times_daily':
        return 'Four Times Daily';
      case 'as_required':
        return 'As Required (PRN)';
      default:
        return frequency;
    }
  }

  /// Helper to get display-friendly form label
  String get formLabel {
    switch (form) {
      case 'tablet':
        return 'Tablet';
      case 'capsule':
        return 'Capsule';
      case 'liquid':
        return 'Liquid';
      case 'injection':
        return 'Injection';
      case 'cream':
        return 'Cream';
      case 'patch':
        return 'Patch';
      case 'inhaler':
        return 'Inhaler';
      default:
        return form ?? 'N/A';
    }
  }

  /// Helper to get display-friendly route label
  String get routeLabel {
    switch (administrationRoute) {
      case 'oral':
        return 'Oral';
      case 'sublingual':
        return 'Sublingual';
      case 'topical':
        return 'Topical';
      case 'subcutaneous':
        return 'Subcutaneous';
      case 'intramuscular':
        return 'Intramuscular';
      case 'intravenous':
        return 'Intravenous';
      case 'rectal':
        return 'Rectal';
      case 'ophthalmic':
        return 'Ophthalmic';
      case 'otic':
        return 'Otic';
      case 'inhaled':
        return 'Inhaled';
      default:
        return administrationRoute ?? 'N/A';
    }
  }

  /// Check if medication is ending soon (within 7 days)
  bool get isEndingSoon {
    if (endDate == null || isOngoing) return false;
    final daysUntilEnd = endDate!.difference(DateTime.now()).inDays;
    return daysUntilEnd >= 0 && daysUntilEnd <= 7;
  }

  /// Check if stock is low
  bool get isLowStock {
    if (stockQuantity == null || reorderLevel == null) return false;
    return stockQuantity! <= reorderLevel!;
  }
}

/// Helper class for frequency options
class FrequencyHelper {
  static const Map<String, String> labels = {
    'once_daily': 'Once Daily',
    'twice_daily': 'Twice Daily',
    'three_times_daily': 'Three Times Daily',
    'four_times_daily': 'Four Times Daily',
    'as_required': 'As Required (PRN)',
  };

  static const List<String> values = [
    'once_daily',
    'twice_daily',
    'three_times_daily',
    'four_times_daily',
    'as_required',
  ];

  static int timesCount(String frequency) {
    switch (frequency) {
      case 'once_daily':
        return 1;
      case 'twice_daily':
        return 2;
      case 'three_times_daily':
        return 3;
      case 'four_times_daily':
        return 4;
      case 'as_required':
        return 1;
      default:
        return 1;
    }
  }
}

/// Helper class for form options
class FormHelper {
  static const Map<String, String> labels = {
    'tablet': 'Tablet',
    'capsule': 'Capsule',
    'liquid': 'Liquid',
    'injection': 'Injection',
    'cream': 'Cream',
    'patch': 'Patch',
    'inhaler': 'Inhaler',
  };

  static const List<String> values = [
    'tablet',
    'capsule',
    'liquid',
    'injection',
    'cream',
    'patch',
    'inhaler',
  ];
}

/// Helper class for administration route options
class RouteHelper {
  static const Map<String, String> labels = {
    'oral': 'Oral',
    'sublingual': 'Sublingual',
    'topical': 'Topical',
    'subcutaneous': 'Subcutaneous',
    'intramuscular': 'Intramuscular',
    'intravenous': 'Intravenous',
    'rectal': 'Rectal',
    'ophthalmic': 'Ophthalmic',
    'otic': 'Otic',
    'inhaled': 'Inhaled',
  };

  static const List<String> values = [
    'oral',
    'sublingual',
    'topical',
    'subcutaneous',
    'intramuscular',
    'intravenous',
    'rectal',
    'ophthalmic',
    'otic',
    'inhaled',
  ];
}

/// Helper class for dosage unit options
class DosageUnitHelper {
  static const Map<String, String> labels = {
    'mg': 'mg',
    'ml': 'ml',
    'tablet': 'Tablet(s)',
    'patch': 'Patch(es)',
    'inhalation': 'Inhalation(s)',
    'unit': 'Unit(s)',
    'drop': 'Drop(s)',
    'suppository': 'Suppository',
  };

  static const List<String> values = [
    'mg',
    'ml',
    'tablet',
    'patch',
    'inhalation',
    'unit',
    'drop',
    'suppository',
  ];
}

/// Helper class for stopped reason options
class StoppedReasonHelper {
  static const Map<String, String> labels = {
    'course_completed': 'Course Completed',
    'changed_medication': 'Changed Medication',
    'adverse_reaction': 'Adverse Reaction',
    'refused': 'Refused',
    'other': 'Other',
  };

  static const List<String> values = [
    'course_completed',
    'changed_medication',
    'adverse_reaction',
    'refused',
    'other',
  ];
}
