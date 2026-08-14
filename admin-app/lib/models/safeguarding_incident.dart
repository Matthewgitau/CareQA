/// Unified model representing any safeguarding incident across all types.
/// The [type] field distinguishes between accident, complaint, medication,
/// missing_person, serious, and missing_item.
class SafeguardingIncident {
  final String id;
  final String type; // 'accident', 'complaint', 'medication', 'missing_person', 'serious', 'missing_item'

  // Common fields
  final String? serviceUserId;
  final String? serviceUserName;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Date of the incident (varies per type)
  final DateTime incidentDate;

  // Location
  final String? location;

  // Severity / priority
  final String? severity;

  // CQC notification
  final bool reportedToCqc;
  final String? cqcReference;

  // Family notification
  final bool reportedToFamily;

  // Police
  final bool policeInvolved;
  final String? policeReference;

  // Resolution
  final DateTime? resolvedAt;
  final String? resolvedBy;

  // Creator
  final String? createdBy;

  // Organisation
  final String? organisationId;

  // ─── Type-specific fields (stored as a map for flexibility) ───
  final Map<String, dynamic> extra;

  const SafeguardingIncident({
    required this.id,
    required this.type,
    this.serviceUserId,
    this.serviceUserName,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.incidentDate,
    this.location,
    this.severity,
    this.reportedToCqc = false,
    this.cqcReference,
    this.reportedToFamily = false,
    this.policeInvolved = false,
    this.policeReference,
    this.resolvedAt,
    this.resolvedBy,
    this.createdBy,
    this.organisationId,
    this.extra = const {},
  });

  // ─── Factory constructors per table ──────────────────────

  factory SafeguardingIncident.fromAccidentLog(Map<String, dynamic> m) {
    return SafeguardingIncident(
      id: m['id'] ?? '',
      type: 'accident',
      serviceUserId: m['service_user_id'],
      serviceUserName: m['service_user_name'],
      description: m['description'] ?? '',
      status: m['status'] ?? 'investigating',
      createdAt: _parseDate(m['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(m['updated_at']) ?? DateTime.now(),
      incidentDate: _parseDate(m['accident_date']) ?? DateTime.now(),
      location: m['location'],
      severity: m['injury_severity'],
      reportedToCqc: m['reported_to_cqc'] ?? false,
      cqcReference: m['cqc_reference'],
      reportedToFamily: m['reported_to_family'] ?? false,
      policeInvolved: false,
      resolvedAt: _parseDate(m['resolved_at']),
      resolvedBy: m['resolved_by'],
      createdBy: m['created_by'],
      organisationId: m['organisation_id'],
      extra: {
        'accident_type': m['accident_type'],
        'accident_time': m['accident_time'],
        'first_aid_given': m['first_aid_given'] ?? false,
        'first_aid_details': m['first_aid_details'],
        'medical_attention_sought': m['medical_attention_sought'] ?? false,
        'medical_provider': m['medical_provider'],
        'hospital_reference': m['hospital_reference'],
        'family_notified_at': m['family_notified_at'],
        'root_cause_analysis': m['root_cause_analysis'],
        'preventive_actions': m['preventive_actions'],
      },
    );
  }

  factory SafeguardingIncident.fromComplaintLog(Map<String, dynamic> m) {
    return SafeguardingIncident(
      id: m['id'] ?? '',
      type: 'complaint',
      serviceUserId: m['service_user_id'],
      serviceUserName: m['service_user_name'],
      description: m['description'] ?? '',
      status: m['status'] ?? 'investigating',
      createdAt: _parseDate(m['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(m['updated_at']) ?? DateTime.now(),
      incidentDate: _parseDate(m['complaint_date']) ?? DateTime.now(),
      severity: m['complaint_category'],
      reportedToCqc: m['cqc_notified'] ?? false,
      reportedToFamily: false,
      policeInvolved: false,
      resolvedAt: _parseDate(m['resolved_at']),
      resolvedBy: m['resolved_by'],
      createdBy: m['created_by'],
      organisationId: m['organisation_id'],
      extra: {
        'complainant_name': m['complainant_name'],
        'complainant_type': m['complainant_type'],
        'complaint_category': m['complaint_category'],
        'investigation_summary': m['investigation_summary'],
        'outcome': m['outcome'],
        'actions_taken': m['actions_taken'],
        'complainant_satisfied': m['complainant_satisfied'],
        'response_date': m['response_date'],
      },
    );
  }

  factory SafeguardingIncident.fromMedicationIncident(Map<String, dynamic> m) {
    return SafeguardingIncident(
      id: m['id'] ?? '',
      type: 'medication',
      serviceUserId: m['service_user_id'],
      serviceUserName: m['service_user_name'],
      description: m['description'] ?? '',
      status: m['status'] ?? 'investigating',
      createdAt: _parseDate(m['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(m['updated_at']) ?? DateTime.now(),
      incidentDate: _parseDate(m['incident_date']) ?? DateTime.now(),
      severity: m['severity'],
      reportedToFamily: m['reported_to_family'] ?? false,
      reportedToCqc: false,
      policeInvolved: false,
      resolvedAt: _parseDate(m['resolved_at']),
      resolvedBy: m['resolved_by'],
      createdBy: m['created_by'],
      organisationId: m['organisation_id'],
      extra: {
        'medication_name': m['medication_name'],
        'prescribed_dosage': m['prescribed_dosage'],
        'actual_dosage': m['actual_dosage'],
        'incident_type': m['incident_type'],
        'incident_time': m['incident_time'],
        'immediate_action': m['immediate_action'],
        'root_cause': m['root_cause'],
        'preventive_measures': m['preventive_measures'],
        'reported_to_gp': m['reported_to_gp'] ?? false,
        'mar_chart_updated': m['mar_chart_updated'] ?? false,
      },
    );
  }

  factory SafeguardingIncident.fromMissingPerson(Map<String, dynamic> m) {
    return SafeguardingIncident(
      id: m['id'] ?? '',
      type: 'missing_person',
      serviceUserId: m['service_user_id'],
      serviceUserName: m['service_user_name'],
      description: m['circumstances'] ?? '',
      status: m['status'] ?? 'active',
      createdAt: _parseDate(m['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(m['updated_at']) ?? DateTime.now(),
      incidentDate: _parseDate(m['missing_date']) ?? DateTime.now(),
      location: m['last_seen_location'],
      severity: 'high',
      policeInvolved: m['police_informed'] ?? false,
      policeReference: m['police_reference'],
      reportedToCqc: m['cqc_informed'] ?? false,
      reportedToFamily: m['family_informed'] ?? false,
      resolvedAt: _parseDate(m['resolved_at']),
      resolvedBy: m['resolved_by'],
      createdBy: m['created_by'],
      organisationId: m['organisation_id'],
      extra: {
        'missing_time': m['missing_time'],
        'last_seen_location': m['last_seen_location'],
        'risk_assessment': m['risk_assessment'],
        'police_contact_name': m['police_contact_name'],
        'family_notified_at': m['family_notified_at'],
        'safeguarding_lead_informed': m['safeguarding_lead_informed'] ?? false,
        'internal_search_conducted': m['internal_search_conducted'] ?? false,
        'search_details': m['search_details'],
        'found_at': m['found_at'],
        'found_location': m['found_location'],
        'condition_on_return': m['condition_on_return'],
        'debrief_conducted': m['debrief_conducted'] ?? false,
        'debrief_notes': m['debrief_notes'],
        'preventive_actions': m['preventive_actions'],
      },
    );
  }

  factory SafeguardingIncident.fromSeriousIncident(Map<String, dynamic> m) {
    return SafeguardingIncident(
      id: m['id'] ?? '',
      type: 'serious',
      serviceUserId: m['service_user_id'],
      serviceUserName: m['service_user_name'],
      description: m['description'] ?? '',
      status: m['status'] ?? 'investigating',
      createdAt: _parseDate(m['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(m['updated_at']) ?? DateTime.now(),
      incidentDate: _parseDate(m['incident_date']) ?? DateTime.now(),
      severity: m['incident_type'],
      reportedToCqc: m['cqc_notified_at'] != null,
      cqcReference: m['cqc_reference'],
      policeInvolved: m['police_involved'] ?? false,
      policeReference: m['police_reference'],
      reportedToFamily: false,
      resolvedAt: _parseDate(m['resolved_at']),
      resolvedBy: m['resolved_by'],
      createdBy: m['created_by'],
      organisationId: m['organisation_id'],
      extra: {
        'incident_type': m['incident_type'],
        'incident_time': m['incident_time'],
        'notification_required': m['notification_required'] ?? true,
        'cqc_notified_at': m['cqc_notified_at'],
        'cqc_notification_method': m['cqc_notification_method'],
        'local_authority_notified': m['local_authority_notified'] ?? false,
        'local_authority_reference': m['local_authority_reference'],
        'coroner_involved': m['coroner_involved'] ?? false,
        'coroner_reference': m['coroner_reference'],
        'investigation_lead': m['investigation_lead'],
        'investigation_summary': m['investigation_summary'],
        'root_cause_analysis': m['root_cause_analysis'],
        'action_plan': m['action_plan'],
        'lessons_learned': m['lessons_learned'],
        'cqc_acknowledged': m['cqc_acknowledged'] ?? false,
        'cqc_acknowledged_at': m['cqc_acknowledged_at'],
      },
    );
  }

  factory SafeguardingIncident.fromMissingItem(Map<String, dynamic> m) {
    return SafeguardingIncident(
      id: m['id'] ?? '',
      type: 'missing_item',
      serviceUserId: m['service_user_id'],
      serviceUserName: m['service_user_name'],
      description: m['item_name'] + (m['item_description'] != null ? ' - ${m['item_description']}' : ''),
      status: m['status'] ?? 'investigating',
      createdAt: _parseDate(m['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(m['updated_at']) ?? DateTime.now(),
      incidentDate: _parseDate(m['missing_date']) ?? DateTime.now(),
      location: m['last_seen_location'],
      policeInvolved: m['police_informed'] ?? false,
      policeReference: m['police_reference'],
      reportedToFamily: m['family_informed'] ?? false,
      reportedToCqc: false,
      createdBy: m['created_by'],
      organisationId: m['organisation_id'],
      extra: {
        'item_name': m['item_name'],
        'item_description': m['item_description'],
        'item_value': m['item_value'],
        'circumstances': m['circumstances'],
        'insurance_claim_filed': m['insurance_claim_filed'] ?? false,
        'insurance_reference': m['insurance_reference'],
        'internal_investigation': m['internal_investigation'],
        'outcome': m['outcome'],
      },
    );
  }

  // ─── Helpers ──────────────────────────────────────────────

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String get typeDisplayName {
    switch (type) {
      case 'accident':
        return 'Accident';
      case 'complaint':
        return 'Complaint';
      case 'medication':
        return 'Medication Incident';
      case 'missing_person':
        return 'Missing Person';
      case 'serious':
        return 'Serious Incident';
      case 'missing_item':
        return 'Missing Item';
      default:
        return type;
    }
  }
}