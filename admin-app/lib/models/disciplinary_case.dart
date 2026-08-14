import 'package:flutter/material.dart';

/// Represents a disciplinary case
class DisciplinaryCase {
  final String id;
  final String? staffId;
  final String staffName;
  final String? employeeNumber;
  final String? department;
  final String? jobTitle;
  final String? carerId;
  final String? carerName;
  final bool serviceUserInvolved;
  final String? serviceUserId;
  final String? serviceUserName;
  final String? caseReference;
  final DateTime incidentDate;
  final DateTime reportDate;
  final String? reportedById;
  final String? reportedByName;
  final String? incidentType;
  final String? severity;
  final String description;
  final String? investigationNotes;
  final bool investigationCompleted;
  final DateTime? investigationCompletedDate;
  final String? investigationOfficer;
  final String? investigationFindings;
  final List<dynamic> witnesses;
  final DateTime? hearingDate;
  final String? hearingNotes;
  final String? hearingOutcome;
  final String? decision;
  final DateTime? decisionDate;
  final String? decisionMadeById;
  final String? decisionMadeByName;
  final String? actionTaken;
  final DateTime? actionStartDate;
  final DateTime? actionEndDate;
  final String? actionNotes;
  final bool appealRaised;
  final DateTime? appealDate;
  final String? appealOutcome;
  final String? appealNotes;
  final String? outcomeType;
  final String? outcomeDetails;
  final String status;
  final String? notes;
  final bool isConfidential;
  final bool complianceRisk;
  final bool hrReviewRequired;
  final DateTime? hrReviewDate;
  final String? hrNotes;
  final String? organisationId;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? signatureUrl;

  DisciplinaryCase({
    required this.id,
    this.staffId,
    required this.staffName,
    this.employeeNumber,
    this.department,
    this.jobTitle,
    this.carerId,
    this.carerName,
    this.serviceUserInvolved = false,
    this.serviceUserId,
    this.serviceUserName,
    this.caseReference,
    required this.incidentDate,
    required this.reportDate,
    this.reportedById,
    this.reportedByName,
    this.incidentType,
    this.severity,
    required this.description,
    this.investigationNotes,
    this.investigationCompleted = false,
    this.investigationCompletedDate,
    this.investigationOfficer,
    this.investigationFindings,
    this.witnesses = const [],
    this.hearingDate,
    this.hearingNotes,
    this.hearingOutcome,
    this.decision,
    this.decisionDate,
    this.decisionMadeById,
    this.decisionMadeByName,
    this.actionTaken,
    this.actionStartDate,
    this.actionEndDate,
    this.actionNotes,
    this.appealRaised = false,
    this.appealDate,
    this.appealOutcome,
    this.appealNotes,
    this.outcomeType,
    this.outcomeDetails,
    this.status = 'open',
    this.notes,
    this.isConfidential = true,
    this.complianceRisk = false,
    this.hrReviewRequired = false,
    this.hrReviewDate,
    this.hrNotes,
    this.organisationId,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.signatureUrl,
  });

  factory DisciplinaryCase.fromJson(Map<String, dynamic> json) {
    return DisciplinaryCase(
      id: json['id'] ?? '',
      staffId: json['staff_id'],
      staffName: json['staff_name'] ?? '',
      employeeNumber: json['employee_number'],
      department: json['department'],
      jobTitle: json['job_title'],
      carerId: json['carer_id'],
      carerName: json['carer_name'],
      serviceUserInvolved: json['service_user_involved'] ?? false,
      serviceUserId: json['service_user_id'],
      serviceUserName: json['service_user_name'],
      caseReference: json['case_reference'],
      incidentDate: json['incident_date'] != null
          ? DateTime.parse(json['incident_date'])
          : DateTime.now(),
      reportDate: json['report_date'] != null
          ? DateTime.parse(json['report_date'])
          : DateTime.now(),
      reportedById: json['reported_by'],
      reportedByName: json['reported_by_name'],
      incidentType: json['incident_type'],
      severity: json['severity'],
      description: json['description'] ?? '',
      investigationNotes: json['investigation_notes'],
      investigationCompleted: json['investigation_completed'] ?? false,
      investigationCompletedDate: json['investigation_completed_date'] != null
          ? DateTime.parse(json['investigation_completed_date'])
          : null,
      investigationOfficer: json['investigation_officer'],
      investigationFindings: json['investigation_findings'],
      witnesses: json['witnesses'] ?? [],
      hearingDate: json['hearing_date'] != null
          ? DateTime.parse(json['hearing_date'])
          : null,
      hearingNotes: json['hearing_notes'],
      hearingOutcome: json['hearing_outcome'],
      decision: json['decision'],
      decisionDate: json['decision_date'] != null
          ? DateTime.parse(json['decision_date'])
          : null,
      decisionMadeById: json['decision_made_by'],
      decisionMadeByName: json['decision_made_by_name'],
      actionTaken: json['action_taken'],
      actionStartDate: json['action_start_date'] != null
          ? DateTime.parse(json['action_start_date'])
          : null,
      actionEndDate: json['action_end_date'] != null
          ? DateTime.parse(json['action_end_date'])
          : null,
      actionNotes: json['action_notes'],
      appealRaised: json['appeal_raised'] ?? false,
      appealDate: json['appeal_date'] != null
          ? DateTime.parse(json['appeal_date'])
          : null,
      appealOutcome: json['appeal_outcome'],
      appealNotes: json['appeal_notes'],
      outcomeType: json['outcome_type'],
      outcomeDetails: json['outcome_details'],
      status: json['status'] ?? 'open',
      notes: json['notes'],
      isConfidential: json['is_confidential'] ?? true,
      complianceRisk: json['compliance_risk'] ?? false,
      hrReviewRequired: json['hr_review_required'] ?? false,
      hrReviewDate: json['hr_review_date'] != null
          ? DateTime.parse(json['hr_review_date'])
          : null,
      hrNotes: json['hr_notes'],
      organisationId: json['organisation_id'],
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      signatureUrl: json['signature_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'staff_id': staffId,
      'staff_name': staffName,
      'employee_number': employeeNumber,
      'department': department,
      'job_title': jobTitle,
      'carer_id': carerId,
      'carer_name': carerName,
      'service_user_involved': serviceUserInvolved,
      'service_user_id': serviceUserId,
      'service_user_name': serviceUserName,
      'incident_date': incidentDate.toIso8601String().split('T').first,
      'report_date': reportDate.toIso8601String().split('T').first,
      'reported_by': reportedById,
      'reported_by_name': reportedByName,
      'incident_type': incidentType,
      'severity': severity,
      'description': description,
      'investigation_notes': investigationNotes,
      'investigation_completed': investigationCompleted,
      'investigation_completed_date': investigationCompletedDate?.toIso8601String().split('T').first,
      'investigation_officer': investigationOfficer,
      'investigation_findings': investigationFindings,
      'witnesses': witnesses,
      'hearing_date': hearingDate?.toIso8601String().split('T').first,
      'hearing_notes': hearingNotes,
      'hearing_outcome': hearingOutcome,
      'decision': decision,
      'decision_date': decisionDate?.toIso8601String().split('T').first,
      'decision_made_by': decisionMadeById,
      'decision_made_by_name': decisionMadeByName,
      'action_taken': actionTaken,
      'action_start_date': actionStartDate?.toIso8601String().split('T').first,
      'action_end_date': actionEndDate?.toIso8601String().split('T').first,
      'action_notes': actionNotes,
      'appeal_raised': appealRaised,
      'appeal_date': appealDate?.toIso8601String().split('T').first,
      'appeal_outcome': appealOutcome,
      'appeal_notes': appealNotes,
      'outcome_type': outcomeType,
      'outcome_details': outcomeDetails,
      'status': status,
      'notes': notes,
      'is_confidential': isConfidential,
      'compliance_risk': complianceRisk,
      'hr_review_required': hrReviewRequired,
      'hr_review_date': hrReviewDate?.toIso8601String().split('T').first,
      'hr_notes': hrNotes,
      'organisation_id': organisationId,
      'created_by': createdBy,
      'signature_url': signatureUrl,
    };
  }

  DisciplinaryCase copyWith({
    String? id,
    String? staffId,
    String? staffName,
    String? employeeNumber,
    String? department,
    String? jobTitle,
    String? caseReference,
    DateTime? incidentDate,
    DateTime? reportDate,
    String? reportedById,
    String? reportedByName,
    String? incidentType,
    String? severity,
    String? description,
    String? investigationNotes,
    bool? investigationCompleted,
    DateTime? investigationCompletedDate,
    String? investigationOfficer,
    String? investigationFindings,
    List<dynamic>? witnesses,
    DateTime? hearingDate,
    String? hearingNotes,
    String? hearingOutcome,
    String? decision,
    DateTime? decisionDate,
    String? decisionMadeById,
    String? decisionMadeByName,
    String? actionTaken,
    DateTime? actionStartDate,
    DateTime? actionEndDate,
    String? actionNotes,
    bool? appealRaised,
    DateTime? appealDate,
    String? appealOutcome,
    String? appealNotes,
    String? outcomeType,
    String? outcomeDetails,
    String? status,
    String? notes,
    bool? isConfidential,
    bool? complianceRisk,
    bool? hrReviewRequired,
    DateTime? hrReviewDate,
    String? hrNotes,
    String? organisationId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? signatureUrl,
  }) {
    return DisciplinaryCase(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      department: department ?? this.department,
      jobTitle: jobTitle ?? this.jobTitle,
      carerId: carerId ?? this.carerId,
      carerName: carerName ?? this.carerName,
      serviceUserInvolved: serviceUserInvolved ?? this.serviceUserInvolved,
      serviceUserId: serviceUserId ?? this.serviceUserId,
      serviceUserName: serviceUserName ?? this.serviceUserName,
      caseReference: caseReference ?? this.caseReference,
      incidentDate: incidentDate ?? this.incidentDate,
      reportDate: reportDate ?? this.reportDate,
      reportedById: reportedById ?? this.reportedById,
      reportedByName: reportedByName ?? this.reportedByName,
      incidentType: incidentType ?? this.incidentType,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      investigationNotes: investigationNotes ?? this.investigationNotes,
      investigationCompleted: investigationCompleted ?? this.investigationCompleted,
      investigationCompletedDate: investigationCompletedDate ?? this.investigationCompletedDate,
      investigationOfficer: investigationOfficer ?? this.investigationOfficer,
      investigationFindings: investigationFindings ?? this.investigationFindings,
      witnesses: witnesses ?? this.witnesses,
      hearingDate: hearingDate ?? this.hearingDate,
      hearingNotes: hearingNotes ?? this.hearingNotes,
      hearingOutcome: hearingOutcome ?? this.hearingOutcome,
      decision: decision ?? this.decision,
      decisionDate: decisionDate ?? this.decisionDate,
      decisionMadeById: decisionMadeById ?? this.decisionMadeById,
      decisionMadeByName: decisionMadeByName ?? this.decisionMadeByName,
      actionTaken: actionTaken ?? this.actionTaken,
      actionStartDate: actionStartDate ?? this.actionStartDate,
      actionEndDate: actionEndDate ?? this.actionEndDate,
      actionNotes: actionNotes ?? this.actionNotes,
      appealRaised: appealRaised ?? this.appealRaised,
      appealDate: appealDate ?? this.appealDate,
      appealOutcome: appealOutcome ?? this.appealOutcome,
      appealNotes: appealNotes ?? this.appealNotes,
      outcomeType: outcomeType ?? this.outcomeType,
      outcomeDetails: outcomeDetails ?? this.outcomeDetails,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isConfidential: isConfidential ?? this.isConfidential,
      complianceRisk: complianceRisk ?? this.complianceRisk,
      hrReviewRequired: hrReviewRequired ?? this.hrReviewRequired,
      hrReviewDate: hrReviewDate ?? this.hrReviewDate,
      hrNotes: hrNotes ?? this.hrNotes,
      organisationId: organisationId ?? this.organisationId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      signatureUrl: signatureUrl ?? this.signatureUrl,
    );
  }

  String getStatusDisplay() {
    switch (status) {
      case 'open':
        return 'Open';
      case 'investigating':
        return 'Investigating';
      case 'hearing_scheduled':
        return 'Hearing Scheduled';
      case 'decision_pending':
        return 'Decision Pending';
      case 'closed':
        return 'Closed';
      case 'appealed':
        return 'Appealed';
      default:
        return status;
    }
  }

  String getSeverityDisplay() {
    switch (severity) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'critical':
        return 'Critical';
      default:
        return severity ?? 'Unknown';
    }
  }

  String getIncidentTypeDisplay() {
    switch (incidentType) {
      case 'gross_misconduct':
        return 'Gross Misconduct';
      case 'misconduct':
        return 'Misconduct';
      case 'poor_performance':
        return 'Poor Performance';
      case 'attendance':
        return 'Attendance';
      case 'health_and_safety':
        return 'Health & Safety';
      case 'bullying_harassment':
        return 'Bullying/Harassment';
      case 'theft_fraud':
        return 'Theft/Fraud';
      case 'data_breach':
        return 'Data Breach';
      case 'confidentiality_breach':
        return 'Confidentiality Breach';
      case 'conduct_outside_work':
        return 'Conduct Outside Work';
      case 'other':
        return 'Other';
      default:
        return incidentType ?? 'Unknown';
    }
  }

  String getOutcomeTypeDisplay() {
    switch (outcomeType) {
      case 'dismissed':
        return 'Dismissed';
      case 'final_written_warning':
        return 'Final Written Warning';
      case 'written_warning':
        return 'Written Warning';
      case 'verbal_warning':
        return 'Verbal Warning';
      case 'suspension':
        return 'Suspension';
      case 'demotion':
        return 'Demotion';
      case 'training_required':
        return 'Training Required';
      case 'monitoring_required':
        return 'Monitoring Required';
      case 'no_action':
        return 'No Action';
      default:
        return outcomeType ?? 'Unknown';
    }
  }

  Color getSeverityColor() {
    switch (severity) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}