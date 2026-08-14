class AnalysisView {
  final String? id;
  final String name;
  final String? description;
  final String viewType;
  final Map<String, dynamic> filters;
  final Map<String, dynamic> displayOptions;
  final bool isPublic;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String organisationId;

  AnalysisView({
    this.id,
    required this.name,
    this.description,
    required this.viewType,
    this.filters = const {},
    this.displayOptions = const {},
    this.isPublic = false,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.organisationId,
  });

  factory AnalysisView.fromJson(Map<String, dynamic> json) {
    return AnalysisView(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      description: json['description'],
      viewType: json['view_type'] ?? 'custom',
      filters: json['filters'] != null ? Map<String, dynamic>.from(json['filters']) : {},
      displayOptions: json['display_options'] != null ? Map<String, dynamic>.from(json['display_options']) : {},
      isPublic: json['is_public'] ?? false,
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      organisationId: json['organisation_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'view_type': viewType,
      'filters': filters,
      'display_options': displayOptions,
      'is_public': isPublic,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'organisation_id': organisationId,
    };
  }

  AnalysisView copyWith({
    String? id,
    String? name,
    String? description,
    String? viewType,
    Map<String, dynamic>? filters,
    Map<String, dynamic>? displayOptions,
    bool? isPublic,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? organisationId,
  }) {
    return AnalysisView(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      viewType: viewType ?? this.viewType,
      filters: filters ?? this.filters,
      displayOptions: displayOptions ?? this.displayOptions,
      isPublic: isPublic ?? this.isPublic,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      organisationId: organisationId ?? this.organisationId,
    );
  }

  String get viewTypeLabel {
    switch (viewType) {
      case 'financial':
        return 'Financial';
      case 'compliance':
        return 'Compliance';
      case 'operational':
        return 'Operational';
      case 'staff':
        return 'Staff';
      case 'service_user':
        return 'Service User';
      case 'custom':
        return 'Custom';
      default:
        return viewType.toUpperCase();
    }
  }
}