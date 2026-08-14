import 'package:flutter/material.dart';

class ActionPlan {
  final String? id;
  final String referenceNumber;
  final String title;
  final String? description;
  final String? sourceType;
  final String? sourceId;
  final String? sourceReference;
  final String priority;
  final String riskLevel;
  final String? category;
  final String? regulatoryReference;
  final String? complianceRequirement;
  final String actionRequired;
  final String? actionType;
  final String? assignedTo;
  final String? assignedToName;
  final String? assignedBy;
  final DateTime assignedDate;
  final DateTime targetCompletionDate;
  final DateTime? actualCompletionDate;
  final String status;
  final int progressPercentage;
  final bool verificationRequired;
  final String? verifiedBy;
  final DateTime? verifiedDate;
  final String? verificationNotes;
  final List<String>? evidenceUrls;
  final String? notes;
  final List<Map<String, dynamic>> updateLog;
  final List<String>? relatedActionPlanIds;
  final List<String>? dependsOn;
  final DateTime? reviewDate;
  final DateTime? nextReviewDate;
  final String? createdBy;
  final DateTime createdAt;
  final String? updatedBy;
  final DateTime updatedAt;
  final String organisationId;
  final DateTime? deletedAt;

  ActionPlan({
    this.id,
    required this.referenceNumber,
    required this.title,
    this.description,
    this.sourceType,
    this.sourceId,
    this.sourceReference,
    this.priority = 'medium',
    this.riskLevel = 'medium',
    this.category,
    this.regulatoryReference,
    this.complianceRequirement,
    required this.actionRequired,
    this.actionType,
    this.assignedTo,
    this.assignedToName,
    this.assignedBy,
    required this.assignedDate,
    required this.targetCompletionDate,
    this.actualCompletionDate,
    this.status = 'open',
    this.progressPercentage = 0,
    this.verificationRequired = false,
    this.verifiedBy,
    this.verifiedDate,
    this.verificationNotes,
    this.evidenceUrls,
    this.notes,
    this.updateLog = const [],
    this.relatedActionPlanIds,
    this.dependsOn,
    this.reviewDate,
    this.nextReviewDate,
    this.createdBy,
    required this.createdAt,
    this.updatedBy,
    required this.updatedAt,
    required this.organisationId,
    this.deletedAt,
  });

  factory ActionPlan.fromJson(Map<String, dynamic> json) {
    return ActionPlan(
      id: json['id']?.toString(),
      referenceNumber: json['reference_number'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      sourceType: json['source_type'],
      sourceId: json['source_id']?.toString(),
      sourceReference: json['source_reference'],
      priority: json['priority'] ?? 'medium',
      riskLevel: json['risk_level'] ?? 'medium',
      category: json['category'],
      regulatoryReference: json['regulatory_reference'],
      complianceRequirement: json['compliance_requirement'],
      actionRequired: json['action_required'] ?? '',
      actionType: json['action_type'],
      assignedTo: json['assigned_to']?.toString(),
      assignedToName: json['assigned_to_name'],
      assignedBy: json['assigned_by']?.toString(),
      assignedDate: json['assigned_date'] != null ? DateTime.parse(json['assigned_date']) : DateTime.now(),
      targetCompletionDate: json['target_completion_date'] != null ? DateTime.parse(json['target_completion_date']) : DateTime.now(),
      actualCompletionDate: json['actual_completion_date'] != null ? DateTime.parse(json['actual_completion_date']) : null,
      status: json['status'] ?? 'open',
      progressPercentage: json['progress_percentage'] ?? 0,
      verificationRequired: json['verification_required'] ?? false,
      verifiedBy: json['verified_by']?.toString(),
      verifiedDate: json['verified_date'] != null ? DateTime.parse(json['verified_date']) : null,
      verificationNotes: json['verification_notes'],
      evidenceUrls: json['evidence_urls'] != null ? List<String>.from(json['evidence_urls']) : null,
      notes: json['notes'],
      updateLog: json['update_log'] != null ? List<Map<String, dynamic>>.from(json['update_log']) : [],
      relatedActionPlanIds: json['related_action_plan_ids'] != null ? List<String>.from(json['related_action_plan_ids']) : null,
      dependsOn: json['depends_on'] != null ? List<String>.from(json['depends_on']) : null,
      reviewDate: json['review_date'] != null ? DateTime.parse(json['review_date']) : null,
      nextReviewDate: json['next_review_date'] != null ? DateTime.parse(json['next_review_date']) : null,
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedBy: json['updated_by']?.toString(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      organisationId: json['organisation_id']?.toString() ?? '',
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'reference_number': referenceNumber,
      'title': title,
      'description': description,
      'source_type': sourceType,
      'source_id': sourceId,
      'source_reference': sourceReference,
      'priority': priority,
      'risk_level': riskLevel,
      'category': category,
      'regulatory_reference': regulatoryReference,
      'compliance_requirement': complianceRequirement,
      'action_required': actionRequired,
      'action_type': actionType,
      'assigned_to': assignedTo,
      'assigned_to_name': assignedToName,
      'assigned_by': assignedBy,
      'assigned_date': assignedDate.toIso8601String().split('T')[0],
      'target_completion_date': targetCompletionDate.toIso8601String().split('T')[0],
      'actual_completion_date': actualCompletionDate?.toIso8601String().split('T')[0],
      'status': status,
      'progress_percentage': progressPercentage,
      'verification_required': verificationRequired,
      'verified_by': verifiedBy,
      'verified_date': verifiedDate?.toIso8601String().split('T')[0],
      'verification_notes': verificationNotes,
      'evidence_urls': evidenceUrls,
      'notes': notes,
      'update_log': updateLog,
      'related_action_plan_ids': relatedActionPlanIds,
      'depends_on': dependsOn,
      'review_date': reviewDate?.toIso8601String().split('T')[0],
      'next_review_date': nextReviewDate?.toIso8601String().split('T')[0],
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_by': updatedBy,
      'updated_at': updatedAt.toIso8601String(),
      'organisation_id': organisationId,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  ActionPlan copyWith({
    String? id,
    String? referenceNumber,
    String? title,
    String? description,
    String? sourceType,
    String? sourceId,
    String? sourceReference,
    String? priority,
    String? riskLevel,
    String? category,
    String? regulatoryReference,
    String? complianceRequirement,
    String? actionRequired,
    String? actionType,
    String? assignedTo,
    String? assignedToName,
    String? assignedBy,
    DateTime? assignedDate,
    DateTime? targetCompletionDate,
    DateTime? actualCompletionDate,
    String? status,
    int? progressPercentage,
    bool? verificationRequired,
    String? verifiedBy,
    DateTime? verifiedDate,
    String? verificationNotes,
    List<String>? evidenceUrls,
    String? notes,
    List<Map<String, dynamic>>? updateLog,
    List<String>? relatedActionPlanIds,
    List<String>? dependsOn,
    DateTime? reviewDate,
    DateTime? nextReviewDate,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    String? organisationId,
    DateTime? deletedAt,
  }) {
    return ActionPlan(
      id: id ?? this.id,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      sourceReference: sourceReference ?? this.sourceReference,
      priority: priority ?? this.priority,
      riskLevel: riskLevel ?? this.riskLevel,
      category: category ?? this.category,
      regulatoryReference: regulatoryReference ?? this.regulatoryReference,
      complianceRequirement: complianceRequirement ?? this.complianceRequirement,
      actionRequired: actionRequired ?? this.actionRequired,
      actionType: actionType ?? this.actionType,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedDate: assignedDate ?? this.assignedDate,
      targetCompletionDate: targetCompletionDate ?? this.targetCompletionDate,
      actualCompletionDate: actualCompletionDate ?? this.actualCompletionDate,
      status: status ?? this.status,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      verificationRequired: verificationRequired ?? this.verificationRequired,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedDate: verifiedDate ?? this.verifiedDate,
      verificationNotes: verificationNotes ?? this.verificationNotes,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      notes: notes ?? this.notes,
      updateLog: updateLog ?? this.updateLog,
      relatedActionPlanIds: relatedActionPlanIds ?? this.relatedActionPlanIds,
      dependsOn: dependsOn ?? this.dependsOn,
      reviewDate: reviewDate ?? this.reviewDate,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      organisationId: organisationId ?? this.organisationId,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  // Helper methods
  bool get isOverdue {
    if (status == 'completed' || status == 'verified' || status == 'closed') return false;
    return targetCompletionDate.isBefore(DateTime.now());
  }

  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(targetCompletionDate).inDays;
  }

  int get daysRemaining {
    if (isOverdue) return 0;
    return targetCompletionDate.difference(DateTime.now()).inDays;
  }

  Color get priorityColor {
    switch (priority) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'under_review':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'verified':
        return Colors.teal;
      case 'closed':
        return Colors.grey;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'under_review':
        return 'Under Review';
      case 'completed':
        return 'Completed';
      case 'verified':
        return 'Verified';
      case 'closed':
        return 'Closed';
      case 'overdue':
        return 'Overdue';
      default:
        return status.toUpperCase();
    }
  }
}