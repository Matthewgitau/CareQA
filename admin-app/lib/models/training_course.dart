/// Represents a training course
class TrainingCourse {
  final String id;
  final String name;
  final String? description;
  final bool isMandatory;
  final int defaultRenewalIntervalMonths;
  final String? category;
  final bool isActive;
  final String? organisationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  TrainingCourse({
    required this.id,
    required this.name,
    this.description,
    this.isMandatory = true,
    this.defaultRenewalIntervalMonths = 12,
    this.category,
    this.isActive = true,
    this.organisationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainingCourse.fromJson(Map<String, dynamic> json) {
    return TrainingCourse(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      isMandatory: json['is_mandatory'] ?? true,
      defaultRenewalIntervalMonths: json['default_renewal_interval_months'] ?? 12,
      category: json['category'],
      isActive: json['is_active'] ?? true,
      organisationId: json['organisation_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'description': description,
      'is_mandatory': isMandatory,
      'default_renewal_interval_months': defaultRenewalIntervalMonths,
      'category': category,
      'is_active': isActive,
      'organisation_id': organisationId,
    };
  }

  TrainingCourse copyWith({
    String? id,
    String? name,
    String? description,
    bool? isMandatory,
    int? defaultRenewalIntervalMonths,
    String? category,
    bool? isActive,
    String? organisationId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrainingCourse(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isMandatory: isMandatory ?? this.isMandatory,
      defaultRenewalIntervalMonths: defaultRenewalIntervalMonths ?? this.defaultRenewalIntervalMonths,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      organisationId: organisationId ?? this.organisationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}