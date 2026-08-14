import 'package:supabase/supabase.dart';

/// Enum for bladder continence status
enum BladderContinenceStatus {
  continent('continent'),
  stress('stress'),
  urge('urge'),
  overflow('overflow'),
  functional('functional');

  final String value;
  const BladderContinenceStatus(this.value);

  String get name => value;

  static BladderContinenceStatus fromString(String value) {
    return BladderContinenceStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BladderContinenceStatus.continent,
    );
  }
}

/// Enum for bowel continence status
enum BowelContinenceStatus {
  continent('continent'),
  constipation('constipation'),
  diarrhoea('diarrhoea'),
  fecalIncontinence('fecal_incontinence');

  final String value;
  const BowelContinenceStatus(this.value);

  String get name => value;

  static BowelContinenceStatus fromString(String value) {
    return BowelContinenceStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BowelContinenceStatus.continent,
    );
  }
}

/// Enum for frequency of incontinence episodes
enum Frequency {
  daily('daily'),
  weekly('weekly'),
  monthly('monthly');

  final String value;
  const Frequency(this.value);

  String get name => value;

  static Frequency fromString(String value) {
    return Frequency.values.firstWhere(
      (freq) => freq.value == value,
      orElse: () => Frequency.daily,
    );
  }
}

/// Enum for toilet accessibility
enum ToiletAccessibility {
  withinReach('within_reach'),
  requiresAssistance('requires_assistance');

  final String value;
  const ToiletAccessibility(this.value);

  String get name => value;

  static ToiletAccessibility fromString(String value) {
    return ToiletAccessibility.values.firstWhere(
      (access) => access.value == value,
      orElse: () => ToiletAccessibility.withinReach,
    );
  }
}

/// Enum for skin condition
enum SkinCondition {
  intact('intact'),
  rash('rash'),
  broken('broken');

  final String value;
  const SkinCondition(this.value);

  String get name => value;

  static SkinCondition fromString(String value) {
    return SkinCondition.values.firstWhere(
      (condition) => condition.value == value,
      orElse: () => SkinCondition.intact,
    );
  }
}

/// Model for Incontinence Risk Assessment
class IncontinenceAssessment {
  final String? id;
  final String? serviceUserId;
  final DateTime assessmentDate;
  final String assessorName;
  final BladderContinenceStatus bladderContinenceStatus;
  final BowelContinenceStatus bowelContinenceStatus;
  final Frequency frequency;
  final List<String> triggers;
  final int? fluidIntakeMl;
  final bool caffeineIntake;
  final bool alcoholIntake;
  final String? medications;
  final bool mobilityAffectingAccess;
  final bool cognitiveAwareness;
  final ToiletAccessibility toiletAccessibility;
  final List<String> incontinenceProducts;
  final SkinCondition skinCondition;
  final DateTime? previousAssessmentDate;
  final bool referredToContinenceService;
  final bool bladderDiaryCompleted;
  final bool bowelDiaryCompleted;
  final String? actionPlan;
  final DateTime? reviewDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  IncontinenceAssessment({
    this.id,
    this.serviceUserId,
    required this.assessmentDate,
    required this.assessorName,
    required this.bladderContinenceStatus,
    required this.bowelContinenceStatus,
    required this.frequency,
    required this.triggers,
    this.fluidIntakeMl,
    required this.caffeineIntake,
    required this.alcoholIntake,
    this.medications,
    required this.mobilityAffectingAccess,
    required this.cognitiveAwareness,
    required this.toiletAccessibility,
    required this.incontinenceProducts,
    required this.skinCondition,
    this.previousAssessmentDate,
    required this.referredToContinenceService,
    required this.bladderDiaryCompleted,
    required this.bowelDiaryCompleted,
    this.actionPlan,
    this.reviewDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert from Supabase response
  factory IncontinenceAssessment.fromMap(Map<String, dynamic> map) {
    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value.toLocal();
      return DateTime.parse(value).toLocal();
    }

    return IncontinenceAssessment(
      id: map['id'],
      serviceUserId: map['service_user_id'],
      assessmentDate: _parseDate(map['assessment_date']),
      assessorName: map['assessor_name'],
      bladderContinenceStatus: BladderContinenceStatus.fromString(map['bladder_continence_status']),
      bowelContinenceStatus: BowelContinenceStatus.fromString(map['bowel_continence_status']),
      frequency: Frequency.fromString(map['frequency']),
      triggers: List<String>.from(map['triggers'] ?? []),
      fluidIntakeMl: map['fluid_intake_ml'],
      caffeineIntake: map['caffeine_intake'] ?? false,
      alcoholIntake: map['alcohol_intake'] ?? false,
      medications: map['medications'],
      mobilityAffectingAccess: map['mobility_affecting_access'] ?? false,
      cognitiveAwareness: map['cognitive_awareness'] ?? true,
      toiletAccessibility: ToiletAccessibility.fromString(map['toilet_accessibility']),
      incontinenceProducts: List<String>.from(map['incontinence_products'] ?? []),
      skinCondition: SkinCondition.fromString(map['skin_condition']),
      previousAssessmentDate: map['previous_assessment_date'] != null ? _parseDate(map['previous_assessment_date']) : null,
      referredToContinenceService: map['referred_to_continence_service'] ?? false,
      bladderDiaryCompleted: map['bladder_diary_completed'] ?? false,
      bowelDiaryCompleted: map['bowel_diary_completed'] ?? false,
      actionPlan: map['action_plan'],
      reviewDate: map['review_date'] != null ? _parseDate(map['review_date']) : null,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  /// Convert to Supabase insert/update format
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'service_user_id': serviceUserId,
      'assessment_date': assessmentDate.toIso8601String().split('T').first,
      'assessor_name': assessorName,
      'bladder_continence_status': bladderContinenceStatus.value,
      'bowel_continence_status': bowelContinenceStatus.value,
      'frequency': frequency.value,
      'triggers': triggers,
      'fluid_intake_ml': fluidIntakeMl,
      'caffeine_intake': caffeineIntake,
      'alcohol_intake': alcoholIntake,
      'medications': medications,
      'mobility_affecting_access': mobilityAffectingAccess,
      'cognitive_awareness': cognitiveAwareness,
      'toilet_accessibility': toiletAccessibility.value,
      'incontinence_products': incontinenceProducts,
      'skin_condition': skinCondition.value,
      'previous_assessment_date': previousAssessmentDate?.toIso8601String().split('T').first,
      'referred_to_continence_service': referredToContinenceService,
      'bladder_diary_completed': bladderDiaryCompleted,
      'bowel_diary_completed': bowelDiaryCompleted,
      'action_plan': actionPlan,
      'review_date': reviewDate?.toIso8601String().split('T').first,
    };
  }

  /// Create a copy with updated values
  IncontinenceAssessment copyWith({
    String? id,
    String? serviceUserId,
    DateTime? assessmentDate,
    String? assessorName,
    BladderContinenceStatus? bladderContinenceStatus,
    BowelContinenceStatus? bowelContinenceStatus,
    Frequency? frequency,
    List<String>? triggers,
    int? fluidIntakeMl,
    bool? caffeineIntake,
    bool? alcoholIntake,
    String? medications,
    bool? mobilityAffectingAccess,
    bool? cognitiveAwareness,
    ToiletAccessibility? toiletAccessibility,
    List<String>? incontinenceProducts,
    SkinCondition? skinCondition,
    DateTime? previousAssessmentDate,
    bool? referredToContinenceService,
    bool? bladderDiaryCompleted,
    bool? bowelDiaryCompleted,
    String? actionPlan,
    DateTime? reviewDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IncontinenceAssessment(
      id: id ?? this.id,
      serviceUserId: serviceUserId ?? this.serviceUserId,
      assessmentDate: assessmentDate ?? this.assessmentDate,
      assessorName: assessorName ?? this.assessorName,
      bladderContinenceStatus: bladderContinenceStatus ?? this.bladderContinenceStatus,
      bowelContinenceStatus: bowelContinenceStatus ?? this.bowelContinenceStatus,
      frequency: frequency ?? this.frequency,
      triggers: triggers ?? this.triggers,
      fluidIntakeMl: fluidIntakeMl ?? this.fluidIntakeMl,
      caffeineIntake: caffeineIntake ?? this.caffeineIntake,
      alcoholIntake: alcoholIntake ?? this.alcoholIntake,
      medications: medications ?? this.medications,
      mobilityAffectingAccess: mobilityAffectingAccess ?? this.mobilityAffectingAccess,
      cognitiveAwareness: cognitiveAwareness ?? this.cognitiveAwareness,
      toiletAccessibility: toiletAccessibility ?? this.toiletAccessibility,
      incontinenceProducts: incontinenceProducts ?? this.incontinenceProducts,
      skinCondition: skinCondition ?? this.skinCondition,
      previousAssessmentDate: previousAssessmentDate ?? this.previousAssessmentDate,
      referredToContinenceService: referredToContinenceService ?? this.referredToContinenceService,
      bladderDiaryCompleted: bladderDiaryCompleted ?? this.bladderDiaryCompleted,
      bowelDiaryCompleted: bowelDiaryCompleted ?? this.bowelDiaryCompleted,
      actionPlan: actionPlan ?? this.actionPlan,
      reviewDate: reviewDate ?? this.reviewDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get human-readable bladder continence status
  String get bladderContinenceStatusText {
    switch (bladderContinenceStatus) {
      case BladderContinenceStatus.continent: return 'Continent';
      case BladderContinenceStatus.stress: return 'Stress Incontinence';
      case BladderContinenceStatus.urge: return 'Urge Incontinence';
      case BladderContinenceStatus.overflow: return 'Overflow Incontinence';
      case BladderContinenceStatus.functional: return 'Functional Incontinence';
    }
  }

  /// Get human-readable bowel continence status
  String get bowelContinenceStatusText {
    switch (bowelContinenceStatus) {
      case BowelContinenceStatus.continent: return 'Continent';
      case BowelContinenceStatus.constipation: return 'Constipation';
      case BowelContinenceStatus.diarrhoea: return 'Diarrhoea';
      case BowelContinenceStatus.fecalIncontinence: return 'Fecal Incontinence';
    }
  }

  /// Get human-readable frequency
  String get frequencyText {
    switch (frequency) {
      case Frequency.daily: return 'Daily';
      case Frequency.weekly: return 'Weekly';
      case Frequency.monthly: return 'Monthly';
    }
  }

  /// Get human-readable toilet accessibility
  String get toiletAccessibilityText {
    switch (toiletAccessibility) {
      case ToiletAccessibility.withinReach: return 'Within Reach';
      case ToiletAccessibility.requiresAssistance: return 'Requires Assistance';
    }
  }

  /// Get human-readable skin condition
  String get skinConditionText {
    switch (skinCondition) {
      case SkinCondition.intact: return 'Intact';
      case SkinCondition.rash: return 'Rash';
      case SkinCondition.broken: return 'Broken';
    }
  }

  /// Check if assessment needs review
  bool get needsReview {
    return reviewDate != null && reviewDate!.isBefore(DateTime.now());
  }

  /// Get risk level based on assessment
  String get riskLevel {
    if (bladderContinenceStatus != BladderContinenceStatus.continent ||
        bowelContinenceStatus != BowelContinenceStatus.continent) {
      if (frequency == Frequency.daily) {
        return 'High';
      } else if (frequency == Frequency.weekly) {
        return 'Medium';
      } else {
        return 'Low';
      }
    }
    return 'Low';
  }

  /// Get summary of triggers
  String get triggersSummary {
    if (triggers.isEmpty) return 'None';
    return triggers.join(', ');
  }

  /// Get summary of incontinence products
  String get productsSummary {
    if (incontinenceProducts.isEmpty) return 'None';
    return incontinenceProducts.join(', ');
  }
}