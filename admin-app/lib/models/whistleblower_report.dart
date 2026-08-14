/// Model for anonymous whistleblower reports.
class WhistleblowerReport {
  final String id;
  final String? reportReference; // Auto-generated: WB-YYYY-MM-XXXX
  final String? reportedByEmail;
  final DateTime reportDate;
  final String category;
  final String description;
  final String? serviceUserId;
  final String? serviceUserName;
  final String? carerId;
  final String? carerName;
  final DateTime? dateTimeOccurred;
  final String? location;
  final String? witnesses;
  final bool evidenceProvided;
  final String? evidenceDetails;
  final bool anonymous;
  final String status;
  final String priority;

  // Internal review
  final String? assignedTo;
  final DateTime? assignedAt;
  final String? reviewNotes;
  final String? investigationOutcome;
  final String? actionsTaken;

  // Resolution
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? feedbackToReporter;

  // Archiving
  final bool archived;
  final DateTime? archivedAt;
  final String? archivedBy;
  final String? archiveReason;

  final DateTime createdAt;
  final String? organisationId;

  const WhistleblowerReport({
    required this.id,
    this.reportReference,
    this.reportedByEmail,
    required this.reportDate,
    required this.category,
    required this.description,
    this.serviceUserId,
    this.serviceUserName,
    this.carerId,
    this.carerName,
    this.dateTimeOccurred,
    this.location,
    this.witnesses,
    this.evidenceProvided = false,
    this.evidenceDetails,
    this.anonymous = true,
    this.status = 'pending',
    this.priority = 'medium',
    this.assignedTo,
    this.assignedAt,
    this.reviewNotes,
    this.investigationOutcome,
    this.actionsTaken,
    this.resolvedAt,
    this.resolvedBy,
    this.feedbackToReporter,
    this.archived = false,
    this.archivedAt,
    this.archivedBy,
    this.archiveReason,
    required this.createdAt,
    this.organisationId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'report_reference': reportReference,
      'reported_by_email': reportedByEmail,
      'report_date': reportDate.toIso8601String().substring(0, 10),
      'category': category,
      'description': description,
      'service_user_id': serviceUserId,
      'service_user_name': serviceUserName,
      'carer_id': carerId,
      'carer_name': carerName,
      'date_time_occurred': dateTimeOccurred?.toIso8601String(),
      'location': location,
      'witnesses': witnesses,
      'evidence_provided': evidenceProvided,
      'evidence_details': evidenceDetails,
      'anonymous': anonymous,
      'status': status,
      'priority': priority,
      'assigned_to': assignedTo,
      'assigned_at': assignedAt?.toIso8601String(),
      'review_notes': reviewNotes,
      'investigation_outcome': investigationOutcome,
      'actions_taken': actionsTaken,
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
      'feedback_to_reporter': feedbackToReporter,
      'archived': archived,
      'archived_at': archivedAt?.toIso8601String(),
      'archived_by': archivedBy,
      'archive_reason': archiveReason,
      'created_at': createdAt.toIso8601String(),
      'organisation_id': organisationId,
    };
  }

  factory WhistleblowerReport.fromMap(Map<String, dynamic> map) {
    return WhistleblowerReport(
      id: map['id'] ?? '',
      reportReference: map['report_reference'],
      reportedByEmail: map['reported_by_email'],
      reportDate: _parseDate(map['report_date']) ?? DateTime.now(),
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      serviceUserId: map['service_user_id'],
      serviceUserName: map['service_user_name'],
      carerId: map['carer_id'],
      carerName: map['carer_name'],
      dateTimeOccurred: _parseDate(map['date_time_occurred']),
      location: map['location'],
      witnesses: map['witnesses'],
      evidenceProvided: map['evidence_provided'] ?? false,
      evidenceDetails: map['evidence_details'],
      anonymous: map['anonymous'] ?? true,
      status: map['status'] ?? 'pending',
      priority: map['priority'] ?? 'medium',
      assignedTo: map['assigned_to'],
      assignedAt: _parseDate(map['assigned_at']),
      reviewNotes: map['review_notes'],
      investigationOutcome: map['investigation_outcome'],
      actionsTaken: map['actions_taken'],
      resolvedAt: _parseDate(map['resolved_at']),
      resolvedBy: map['resolved_by'],
      feedbackToReporter: map['feedback_to_reporter'],
      archived: map['archived'] ?? false,
      archivedAt: _parseDate(map['archived_at']),
      archivedBy: map['archived_by'],
      archiveReason: map['archive_reason'],
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      organisationId: map['organisation_id'],
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String get categoryDisplayName {
    switch (category) {
      case 'safeguarding':
        return 'Safeguarding';
      case 'financial_misconduct':
        return 'Financial Misconduct';
      case 'staff_conduct':
        return 'Staff Conduct';
      case 'health_safety':
        return 'Health & Safety';
      case 'medication':
        return 'Medication';
      case 'fraud':
        return 'Fraud';
      default:
        return category;
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'urgent':
        return 'Urgent';
      default:
        return priority;
    }
  }

  WhistleblowerReport copyWith({
    String? status,
    String? priority,
    String? assignedTo,
    DateTime? assignedAt,
    String? reviewNotes,
    String? investigationOutcome,
    String? actionsTaken,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? feedbackToReporter,
    bool? archived,
    DateTime? archivedAt,
    String? archivedBy,
    String? archiveReason,
  }) {
    return WhistleblowerReport(
      id: id,
      reportReference: reportReference,
      reportedByEmail: reportedByEmail,
      reportDate: reportDate,
      category: category,
      description: description,
      serviceUserId: serviceUserId,
      serviceUserName: serviceUserName,
      carerId: carerId,
      carerName: carerName,
      dateTimeOccurred: dateTimeOccurred,
      location: location,
      witnesses: witnesses,
      evidenceProvided: evidenceProvided,
      evidenceDetails: evidenceDetails,
      anonymous: anonymous,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedAt: assignedAt ?? this.assignedAt,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      investigationOutcome: investigationOutcome ?? this.investigationOutcome,
      actionsTaken: actionsTaken ?? this.actionsTaken,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      feedbackToReporter: feedbackToReporter ?? this.feedbackToReporter,
      archived: archived ?? this.archived,
      archivedAt: archivedAt ?? this.archivedAt,
      archivedBy: archivedBy ?? this.archivedBy,
      archiveReason: archiveReason ?? this.archiveReason,
      createdAt: createdAt,
      organisationId: organisationId,
    );
  }
}