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

class RoleRequirement {
  final String id;
  final String roleType;
  final String competencyId;
  final int requiredLevel;
  final bool isMandatory;
  final DateTime createdAt;

  RoleRequirement({
    required this.id,
    required this.roleType,
    required this.competencyId,
    this.requiredLevel = 3,
    this.isMandatory = true,
    required this.createdAt,
  });

  factory RoleRequirement.fromJson(Map<String, dynamic> json) {
    return RoleRequirement(
      id: json['id'] ?? '',
      roleType: json['role_type'] ?? '',
      competencyId: json['competency_id'] ?? '',
      requiredLevel: json['required_level'] ?? 3,
      isMandatory: json['is_mandatory'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'role_type': roleType,
      'competency_id': competencyId,
      'required_level': requiredLevel,
      'is_mandatory': isMandatory,
    };
  }

  String getRoleTypeDisplay() {
    switch (roleType) {
      case 'care_worker': return 'Care Worker';
      case 'senior_carer': return 'Senior Carer';
      case 'team_leader': return 'Team Leader';
      case 'manager': return 'Manager';
      case 'nurse': return 'Nurse';
      case 'admin': return 'Administrator';
      default: return roleType;
    }
  }
}