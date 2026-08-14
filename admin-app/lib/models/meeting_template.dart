class MeetingTemplate {
  final String id;
  final String templateName;
  final String meetingType;
  final String? defaultAgenda;
  final List<String> defaultAttendees;
  final String? defaultLocation;
  final bool isOnline;
  final String? meetingLinkTemplate;
  final bool isActive;
  final String? organisationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  MeetingTemplate({
    required this.id,
    required this.templateName,
    required this.meetingType,
    this.defaultAgenda,
    this.defaultAttendees = const [],
    this.defaultLocation,
    this.isOnline = false,
    this.meetingLinkTemplate,
    this.isActive = true,
    this.organisationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MeetingTemplate.fromJson(Map<String, dynamic> json) {
    return MeetingTemplate(
      id: json['id'] ?? '',
      templateName: json['template_name'] ?? '',
      meetingType: json['meeting_type'] ?? 'other',
      defaultAgenda: json['default_agenda'],
      defaultAttendees: json['default_attendees'] != null ? List<String>.from(json['default_attendees']) : [],
      defaultLocation: json['default_location'],
      isOnline: json['is_online'] ?? false,
      meetingLinkTemplate: json['meeting_link_template'],
      isActive: json['is_active'] ?? true,
      organisationId: json['organisation_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'template_name': templateName,
      'meeting_type': meetingType,
      'default_agenda': defaultAgenda,
      'default_attendees': defaultAttendees,
      'default_location': defaultLocation,
      'is_online': isOnline,
      'meeting_link_template': meetingLinkTemplate,
      'is_active': isActive,
      'organisation_id': organisationId,
    };
  }
}