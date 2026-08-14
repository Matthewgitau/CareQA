class CompetencyRating {
  final String competencyId;
  final String competencyName;
  final int achievedLevel;
  final String evidence;
  final List<String> evidenceUrls;
  final String assessorNotes;
  final DateTime assessedDate;

  CompetencyRating({
    required this.competencyId,
    required this.competencyName,
    required this.achievedLevel,
    this.evidence = '',
    this.evidenceUrls = const [],
    this.assessorNotes = '',
    required this.assessedDate,
  });

  factory CompetencyRating.fromJson(Map<String, dynamic> json) {
    return CompetencyRating(
      competencyId: json['competency_id'] ?? '',
      competencyName: json['competency_name'] ?? '',
      achievedLevel: json['achieved_level'] ?? 1,
      evidence: json['evidence'] ?? '',
      evidenceUrls: json['evidence_urls'] != null ? List<String>.from(json['evidence_urls']) : [],
      assessorNotes: json['assessor_notes'] ?? '',
      assessedDate: json['assessed_date'] != null ? DateTime.parse(json['assessed_date']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'competency_id': competencyId,
      'competency_name': competencyName,
      'achieved_level': achievedLevel,
      'evidence': evidence,
      'evidence_urls': evidenceUrls,
      'assessor_notes': assessorNotes,
      'assessed_date': assessedDate.toIso8601String().split('T').first,
    };
  }

  String getLevelDisplay() {
    switch (achievedLevel) {
      case 1: return 'Beginner';
      case 2: return 'Elementary';
      case 3: return 'Intermediate';
      case 4: return 'Advanced';
      case 5: return 'Expert';
      default: return 'Level $achievedLevel';
    }
  }
}

class CompetencyAssessment {
  final String id;
  final String staffId;
  final String staffName;
  final String assessorId;
  final String assessorName;
  final DateTime assessmentDate;
  final String assessmentType;
  final List<CompetencyRating> competencyRatings;
  final String overallRating;
  final bool passed;
  final List<String> developmentAreas;
  final String actionPlan;
  final DateTime? nextReviewDate;
  final String status;
  final DateTime? staffSignOffDate;
  final String? organisationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CompetencyAssessment({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.assessorId,
    required this.assessorName,
    required this.assessmentDate,
    this.assessmentType = 'annual',
    this.competencyRatings = const [],
    this.overallRating = 'development_needed',
    this.passed = false,
    this.developmentAreas = const [],
    this.actionPlan = '',
    this.nextReviewDate,
    this.status = 'draft',
    this.staffSignOffDate,
    this.organisationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompetencyAssessment.fromJson(Map<String, dynamic> json) {
    return CompetencyAssessment(
      id: json['id'] ?? '',
      staffId: json['staff_id'] ?? '',
      staffName: json['staff_name'] ?? '',
      assessorId: json['assessor_id'] ?? '',
      assessorName: json['assessor_name'] ?? '',
      assessmentDate: json['assessment_date'] != null ? DateTime.parse(json['assessment_date']) : DateTime.now(),
      assessmentType: json['assessment_type'] ?? 'annual',
      competencyRatings: json['competency_ratings'] != null 
        ? (json['competency_ratings'] as List).map((r) => CompetencyRating.fromJson(r)).toList()
        : [],
      overallRating: json['overall_rating'] ?? 'development_needed',
      passed: json['passed'] ?? false,
      developmentAreas: json['development_areas'] != null ? List<String>.from(json['development_areas']) : [],
      actionPlan: json['action_plan'] ?? '',
      nextReviewDate: json['next_review_date'] != null ? DateTime.parse(json['next_review_date']) : null,
      status: json['status'] ?? 'draft',
      staffSignOffDate: json['staff_sign_off_date'] != null ? DateTime.parse(json['staff_sign_off_date']) : null,
      organisationId: json['organisation_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'staff_id': staffId,
      'staff_name': staffName,
      'assessor_id': assessorId,
      'assessor_name': assessorName,
      'assessment_date': assessmentDate.toIso8601String().split('T').first,
      'assessment_type': assessmentType,
      'competency_ratings': competencyRatings.map((r) => r.toJson()).toList(),
      'overall_rating': overallRating,
      'passed': passed,
      'development_areas': developmentAreas,
      'action_plan': actionPlan,
      'next_review_date': nextReviewDate?.toIso8601String().split('T').first,
      'status': status,
      'staff_sign_off_date': staffSignOffDate?.toIso8601String().split('T').first,
      'organisation_id': organisationId,
    };
  }

  double getAverageScore() {
    if (competencyRatings.isEmpty) return 0.0;
    final total = competencyRatings.fold<int>(0, (sum, rating) => sum + rating.achievedLevel);
    return total / competencyRatings.length;
  }

  bool get isComplete => status == 'approved' || status == 'acknowledged';
}

class DevelopmentPlan {
  final String id;
  final String staffId;
  final String createdById;
  final DateTime createdDate;
  final DateTime? reviewDate;
  final List<DevelopmentGoal> goals;
  final String notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  DevelopmentPlan({
    required this.id,
    required this.staffId,
    required this.createdById,
    required this.createdDate,
    this.reviewDate,
    this.goals = const [],
    this.notes = '',
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory DevelopmentPlan.fromJson(Map<String, dynamic> json) {
    return DevelopmentPlan(
      id: json['id'] ?? '',
      staffId: json['staff_id'] ?? '',
      createdById: json['created_by'] ?? '',
      createdDate: json['created_date'] != null ? DateTime.parse(json['created_date']) : DateTime.now(),
      reviewDate: json['review_date'] != null ? DateTime.parse(json['review_date']) : null,
      goals: json['goals'] != null 
        ? (json['goals'] as List).map((g) => DevelopmentGoal.fromJson(g)).toList()
        : [],
      notes: json['notes'] ?? '',
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'staff_id': staffId,
      'created_by': createdById,
      'created_date': createdDate.toIso8601String().split('T').first,
      'review_date': reviewDate?.toIso8601String().split('T').first,
      'goals': goals.map((g) => g.toJson()).toList(),
      'notes': notes,
      'status': status,
    };
  }

  bool get isActive => status == 'active';
  bool get isOverdue => reviewDate != null && reviewDate!.isBefore(DateTime.now());
}

class DevelopmentGoal {
  final String competencyId;
  final String competencyName;
  final int targetLevel;
  final DateTime targetDate;
  final String status;
  final String? actionPlan;
  final String? notes;

  DevelopmentGoal({
    required this.competencyId,
    required this.competencyName,
    required this.targetLevel,
    required this.targetDate,
    this.status = 'not_started',
    this.actionPlan,
    this.notes,
  });

  factory DevelopmentGoal.fromJson(Map<String, dynamic> json) {
    return DevelopmentGoal(
      competencyId: json['competency_id'] ?? '',
      competencyName: json['competency_name'] ?? '',
      targetLevel: json['target_level'] ?? 3,
      targetDate: json['target_date'] != null ? DateTime.parse(json['target_date']) : DateTime.now(),
      status: json['status'] ?? 'not_started',
      actionPlan: json['action_plan'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'competency_id': competencyId,
      'competency_name': competencyName,
      'target_level': targetLevel,
      'target_date': targetDate.toIso8601String().split('T').first,
      'status': status,
      'action_plan': actionPlan,
      'notes': notes,
    };
  }

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isOverdue => !isCompleted && targetDate.isBefore(DateTime.now());
}

class Competency {
  final String id;
  final String competencyCode;
  final String competencyName;
  final String category;
  final String description;
  final int requiredLevel;
  final List<String> assessmentMethod;
  final List<String> evidenceRequirements;
  final String? regulatoryReference;
  final bool isActive;
  final String? organisationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Competency({
    required this.id,
    required this.competencyCode,
    required this.competencyName,
    required this.category,
    required this.description,
    this.requiredLevel = 3,
    this.assessmentMethod = const ['observation'],
    this.evidenceRequirements = const [],
    this.regulatoryReference,
    this.isActive = true,
    this.organisationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Competency.fromJson(Map<String, dynamic> json) {
    return Competency(
      id: json['id'] ?? '',
      competencyCode: json['competency_code'] ?? '',
      competencyName: json['competency_name'] ?? '',
      category: json['category'] ?? 'clinical',
      description: json['description'] ?? '',
      requiredLevel: json['required_level'] ?? 3,
      assessmentMethod: json['assessment_method'] != null ? List<String>.from(json['assessment_method']) : ['observation'],
      evidenceRequirements: json['evidence_requirements'] != null ? List<String>.from(json['evidence_requirements']) : [],
      regulatoryReference: json['regulatory_reference'],
      isActive: json['is_active'] ?? true,
      organisationId: json['organisation_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'competency_code': competencyCode,
      'competency_name': competencyName,
      'category': category,
      'description': description,
      'required_level': requiredLevel,
      'assessment_method': assessmentMethod,
      'evidence_requirements': evidenceRequirements,
      'regulatory_reference': regulatoryReference,
      'is_active': isActive,
      'organisation_id': organisationId,
    };
  }

  String getCategoryDisplay() {
    switch (category) {
      case 'clinical': return 'Clinical Skills';
      case 'communication': return 'Communication';
      case 'professional': return 'Professional';
      case 'safety': return 'Safety';
      case 'management': return 'Management';
      case 'digital': return 'Digital';
      default: return category;
    }
  }

  String getLevelDisplay(int level) {
    switch (level) {
      case 1: return 'Beginner';
      case 2: return 'Elementary';
      case 3: return 'Intermediate';
      case 4: return 'Advanced';
      case 5: return 'Expert';
      default: return 'Level $level';
    }
  }
}