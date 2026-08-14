class MeetingType {
  final String id;
  final String typeCode;
  final String displayName;
  final String? description;
  final int? defaultDurationMinutes;
  final bool requiresAgenda;
  final bool requiresMinutes;
  final bool requiresAttendanceTracking;
  final bool cqcRelevant;
  final bool isActive;
  final String? organisationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  MeetingType({
    required this.id,
    required this.typeCode,
    required this.displayName,
    this.description,
    this.defaultDurationMinutes,
    this.requiresAgenda = true,
    this.requiresMinutes = true,
    this.requiresAttendanceTracking = true,
    this.cqcRelevant = false,
    this.isActive = true,
    this.organisationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MeetingType.fromJson(Map<String, dynamic> json) {
    return MeetingType(
      id: json['id'] ?? '',
      typeCode: json['type_code'] ?? '',
      displayName: json['display_name'] ?? '',
      description: json['description'],
      defaultDurationMinutes: json['default_duration_minutes'],
      requiresAgenda: json['requires_agenda'] ?? true,
      requiresMinutes: json['requires_minutes'] ?? true,
      requiresAttendanceTracking: json['requires_attendance_tracking'] ?? true,
      cqcRelevant: json['cqc_relevant'] ?? false,
      isActive: json['is_active'] ?? true,
      organisationId: json['organisation_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'type_code': typeCode,
      'display_name': displayName,
      'description': description,
      'default_duration_minutes': defaultDurationMinutes,
      'requires_agenda': requiresAgenda,
      'requires_minutes': requiresMinutes,
      'requires_attendance_tracking': requiresAttendanceTracking,
      'cqc_relevant': cqcRelevant,
      'is_active': isActive,
      'organisation_id': organisationId,
    };
  }
}