class Meeting {
  final String id;
  final String meetingTitle;
  final String meetingType;
  final DateTime meetingDate;
  final String startTime;
  final String endTime;
  final int? durationMinutes;
  final String? location;
  final bool isOnline;
  final String? meetingLink;
  final String? agenda;
  final String? chairPerson;
  final String? chairPersonName;
  final String? organiser;
  final String? organiserName;
  final String? minuteTaker;
  final String? minuteTakerName;
  final List<dynamic> attendees;
  final int? attendeesCount;
  final List<dynamic> apologies;
  final int? apologiesCount;
  final String? minutes;
  final List<dynamic> decisions;
  final String? keyDiscussionPoints;
  final List<dynamic> actionItems;
  final DateTime? nextMeetingDate;
  final String? nextMeetingTime;
  final String? nextMeetingNotes;
  final String status;
  final bool minutedApproved;
  final DateTime? minutedApprovedAt;
  final String? minutedApprovedBy;
  final bool cqcComplianceChecked;
  final String? cqcComplianceNotes;
  final List<dynamic> attachments;
  final bool isConfidential;
  final int? meetingEffectivenessScore;
  final String? feedbackNotes;
  final String? notes;
  final String? organisationId;
  final String? createdById;
  final DateTime createdAt;
  final DateTime updatedAt;

  Meeting({
    required this.id,
    required this.meetingTitle,
    required this.meetingType,
    required this.meetingDate,
    required this.startTime,
    required this.endTime,
    this.durationMinutes,
    this.location,
    this.isOnline = false,
    this.meetingLink,
    this.agenda,
    this.chairPerson,
    this.chairPersonName,
    this.organiser,
    this.organiserName,
    this.minuteTaker,
    this.minuteTakerName,
    this.attendees = const [],
    this.attendeesCount,
    this.apologies = const [],
    this.apologiesCount,
    this.minutes,
    this.decisions = const [],
    this.keyDiscussionPoints,
    this.actionItems = const [],
    this.nextMeetingDate,
    this.nextMeetingTime,
    this.nextMeetingNotes,
    this.status = 'scheduled',
    this.minutedApproved = false,
    this.minutedApprovedAt,
    this.minutedApprovedBy,
    this.cqcComplianceChecked = false,
    this.cqcComplianceNotes,
    this.attachments = const [],
    this.isConfidential = false,
    this.meetingEffectivenessScore,
    this.feedbackNotes,
    this.notes,
    this.organisationId,
    this.createdById,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'] ?? '',
      meetingTitle: json['meeting_title'] ?? '',
      meetingType: json['meeting_type'] ?? 'other',
      meetingDate: json['meeting_date'] != null ? DateTime.parse(json['meeting_date']) : DateTime.now(),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      durationMinutes: json['duration_minutes'],
      location: json['location'],
      isOnline: json['is_online'] ?? false,
      meetingLink: json['meeting_link'],
      agenda: json['agenda'],
      chairPerson: json['chair_person'],
      chairPersonName: json['chair_person_name'],
      organiser: json['organiser'],
      organiserName: json['organiser_name'],
      minuteTaker: json['minute_taker'],
      minuteTakerName: json['minute_taker_name'],
      attendees: json['attendees'] ?? [],
      attendeesCount: json['attendees_count'],
      apologies: json['apologies'] ?? [],
      apologiesCount: json['apologies_count'],
      minutes: json['minutes'],
      decisions: json['decisions'] ?? [],
      keyDiscussionPoints: json['key_discussion_points'],
      actionItems: json['action_items'] ?? [],
      nextMeetingDate: json['next_meeting_date'] != null ? DateTime.parse(json['next_meeting_date']) : null,
      nextMeetingTime: json['next_meeting_time'],
      nextMeetingNotes: json['next_meeting_notes'],
      status: json['status'] ?? 'scheduled',
      minutedApproved: json['minuted_approved'] ?? false,
      minutedApprovedAt: json['minuted_approved_at'] != null ? DateTime.parse(json['minuted_approved_at']) : null,
      minutedApprovedBy: json['minuted_approved_by'],
      cqcComplianceChecked: json['cqc_compliance_checked'] ?? false,
      cqcComplianceNotes: json['cqc_compliance_notes'],
      attachments: json['attachments'] ?? [],
      isConfidential: json['is_confidential'] ?? false,
      meetingEffectivenessScore: json['meeting_effectiveness_score'],
      feedbackNotes: json['feedback_notes'],
      notes: json['notes'],
      organisationId: json['organisation_id'],
      createdById: json['created_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'meeting_title': meetingTitle,
      'meeting_type': meetingType,
      'meeting_date': meetingDate.toIso8601String().split('T').first,
      'start_time': startTime,
      'end_time': endTime,
      'location': location,
      'is_online': isOnline,
      'meeting_link': meetingLink,
      'agenda': agenda,
      'chair_person': chairPerson,
      'chair_person_name': chairPersonName,
      'organiser': organiser,
      'organiser_name': organiserName,
      'minute_taker': minuteTaker,
      'minute_taker_name': minuteTakerName,
      'attendees': attendees,
      'apologies': apologies,
      'minutes': minutes,
      'decisions': decisions,
      'key_discussion_points': keyDiscussionPoints,
      'action_items': actionItems,
      'next_meeting_date': nextMeetingDate?.toIso8601String().split('T').first,
      'next_meeting_time': nextMeetingTime,
      'next_meeting_notes': nextMeetingNotes,
      'status': status,
      'minuted_approved': minutedApproved,
      'minuted_approved_at': minutedApprovedAt?.toIso8601String(),
      'minuted_approved_by': minutedApprovedBy,
      'cqc_compliance_checked': cqcComplianceChecked,
      'cqc_compliance_notes': cqcComplianceNotes,
      'attachments': attachments,
      'is_confidential': isConfidential,
      'meeting_effectiveness_score': meetingEffectivenessScore,
      'feedback_notes': feedbackNotes,
      'notes': notes,
      'organisation_id': organisationId,
      'created_by': createdById,
    };
  }

  String getMeetingTypeDisplay() {
    switch (meetingType) {
      case 'team_meeting': return 'Team Meeting';
      case 'handover': return 'Shift Handover';
      case 'supervision': return 'Supervision';
      case 'training_session': return 'Training Session';
      case 'emergency_meeting': return 'Emergency Meeting';
      case 'management_meeting': return 'Management Meeting';
      case 'care_plan_review': return 'Care Plan Review';
      case 'service_user_review': return 'Service User Review';
      case 'incident_review': return 'Incident Review';
      case 'audit_review': return 'Audit Review';
      case 'staff_meeting': return 'Staff Meeting';
      default: return meetingType;
    }
  }

  String getStatusDisplay() {
    switch (status) {
      case 'scheduled': return 'Scheduled';
      case 'in_progress': return 'In Progress';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      case 'postponed': return 'Postponed';
      default: return status;
    }
  }

  bool get isCompleted => status == 'completed';
  bool get isCqcRelevant => meetingType == 'care_plan_review' || meetingType == 'service_user_review' || meetingType == 'incident_review' || meetingType == 'audit_review';
}