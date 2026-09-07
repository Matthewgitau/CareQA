class VisitPreferences {
  final String? preferredTime; // e.g. "09:00"
  final int? durationMinutes;
  final List<String> visitDays; // ["monday", "wednesday", "friday"]
  final bool requiresTwoCarers;
  final String? notes;

  const VisitPreferences({
    this.preferredTime,
    this.durationMinutes,
    this.visitDays = const [],
    this.requiresTwoCarers = false,
    this.notes,
  });

  factory VisitPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const VisitPreferences();
    return VisitPreferences(
      preferredTime: json['preferred_time'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      visitDays: (json['visit_days'] as List?)?.cast<String>() ?? const [],
      requiresTwoCarers: json['requires_two_carers'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'preferred_time': preferredTime,
        'duration_minutes': durationMinutes,
        'visit_days': visitDays,
        'requires_two_carers': requiresTwoCarers,
        'notes': notes,
      };

  VisitPreferences copyWith({
    String? preferredTime,
    int? durationMinutes,
    List<String>? visitDays,
    bool? requiresTwoCarers,
    String? notes,
  }) {
    return VisitPreferences(
      preferredTime: preferredTime ?? this.preferredTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      visitDays: visitDays ?? this.visitDays,
      requiresTwoCarers: requiresTwoCarers ?? this.requiresTwoCarers,
      notes: notes ?? this.notes,
    );
  }
}

class ServiceUser {
  final String id;
  final String name;
  final String address;
  final String? notes;
  final String? referenceCode;
  final DateTime? dateOfBirth;
  final String? nhsNumber;
  final String? gpName;
  final String? gpPhone;
  final String? familyContactName;
  final String? familyContactPhone;
  final String? familyContactRelation;
  final String? familyContactEmail;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final List<Map<String, dynamic>> medicationList;
  final Map<String, dynamic> carePlan;
  final String? respectFormUrl;
  final String? carePlanUrl;
  final bool isActive;
  final DateTime createdAt;

  ServiceUser({
    required this.id,
    required this.name,
    required this.address,
    this.notes,
    this.referenceCode,
    this.dateOfBirth,
    this.nhsNumber,
    this.gpName,
    this.gpPhone,
    this.familyContactName,
    this.familyContactPhone,
    this.familyContactRelation,
    this.familyContactEmail,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.medicationList = const [],
    this.carePlan = const {},
    this.respectFormUrl,
    this.carePlanUrl,
    this.isActive = true,
    required this.createdAt,
  });

  /// Visit preferences parsed from the `care_plan` JSON column.
  VisitPreferences get visitPreferences {
    final plan = carePlan['visit_preferences'];
    if (plan is Map<String, dynamic>) {
      return VisitPreferences.fromJson(plan);
    }
    return const VisitPreferences();
  }

  /// Returns the care_plan map with the given visit preferences merged in.
  Map<String, dynamic> carePlanWithVisitPreferences(
      VisitPreferences preferences) {
    final updated = Map<String, dynamic>.from(carePlan);
    updated['visit_preferences'] = preferences.toJson();
    return updated;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'notes': notes,
      'reference_code': referenceCode,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'nhs_number': nhsNumber,
      'gp_name': gpName,
      'gp_phone': gpPhone,
      'family_contact_name': familyContactName,
      'family_contact_phone': familyContactPhone,
      'family_contact_relation': familyContactRelation,
      'family_contact_email': familyContactEmail,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'emergency_contact_relation': emergencyContactRelation,
      'medication_list': medicationList,
      'care_plan': carePlan,
      'respect_form_url': respectFormUrl,
      'care_plan_url': carePlanUrl,
      'is_active': isActive,
    };
  }

  factory ServiceUser.fromMap(Map<String, dynamic> map) {
    return ServiceUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      notes: map['notes'],
      referenceCode: map['reference_code'],
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.tryParse(map['date_of_birth'])
          : null,
      nhsNumber: map['nhs_number'],
      gpName: map['gp_name'],
      gpPhone: map['gp_phone'],
      familyContactName: map['family_contact_name'],
      familyContactPhone: map['family_contact_phone'],
      familyContactRelation: map['family_contact_relation'],
      familyContactEmail: map['family_contact_email'],
      emergencyContactName: map['emergency_contact_name'],
      emergencyContactPhone: map['emergency_contact_phone'],
      emergencyContactRelation: map['emergency_contact_relation'],
      medicationList: map['medication_list'] != null
          ? List<Map<String, dynamic>>.from(map['medication_list'])
          : [],
      carePlan: map['care_plan'] != null
          ? Map<String, dynamic>.from(map['care_plan'])
          : {},
      respectFormUrl: map['respect_form_url'],
      carePlanUrl: map['care_plan_url'],
      isActive: map['is_active'] ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}