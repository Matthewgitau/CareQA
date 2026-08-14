import 'package:flutter/material.dart';

class LessonLearnt {
  final String? id;
  final String referenceNumber;
  final String title;
  final String description;
  final String? sourceType;
  final String? sourceId;
  final String? sourceReference;
  final DateTime? incidentDate;
  final String severity;
  final String? category;
  final String? rootCause;
  final List<String>? contributingFactors;
  final String? rootCauseCategory;
  final String keyLearning;
  final String? recommendations;
  final String? changesMade;
  final List<String>? evidenceUrls;
  final String? actionPlanId;
  final String? actionPlanReference;
  final bool implemented;
  final DateTime? implementationDate;
  final String? implementedBy;
  final String? implementationNotes;
  final String? reviewedBy;
  final DateTime? reviewedDate;
  final String? reviewNotes;
  final int? effectivenessRating;
  final bool sharedWithTeam;
  final DateTime? sharedDate;
  final String? sharedMethod;
  final String? sharedNotes;
  final bool isConfidential;
  final bool isTrainingRequired;
  final String? trainingCourseId;
  final String status;
  final String? createdBy;
  final DateTime createdAt;
  final String? updatedBy;
  final DateTime updatedAt;
  final String organisationId;
  final DateTime? deletedAt;

  LessonLearnt({
    this.id,
    required this.referenceNumber,
    required this.title,
    required this.description,
    this.sourceType,
    this.sourceId,
    this.sourceReference,
    this.incidentDate,
    this.severity = 'medium',
    this.category,
    this.rootCause,
    this.contributingFactors,
    this.rootCauseCategory,
    required this.keyLearning,
    this.recommendations,
    this.changesMade,
    this.evidenceUrls,
    this.actionPlanId,
    this.actionPlanReference,
    this.implemented = false,
    this.implementationDate,
    this.implementedBy,
    this.implementationNotes,
    this.reviewedBy,
    this.reviewedDate,
    this.reviewNotes,
    this.effectivenessRating,
    this.sharedWithTeam = false,
    this.sharedDate,
    this.sharedMethod,
    this.sharedNotes,
    this.isConfidential = false,
    this.isTrainingRequired = false,
    this.trainingCourseId,
    this.status = 'draft',
    this.createdBy,
    required this.createdAt,
    this.updatedBy,
    required this.updatedAt,
    required this.organisationId,
    this.deletedAt,
  });

  factory LessonLearnt.fromJson(Map<String, dynamic> json) {
    return LessonLearnt(
      id: json['id']?.toString(),
      referenceNumber: json['reference_number'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      sourceType: json['source_type'],
      sourceId: json['source_id']?.toString(),
      sourceReference: json['source_reference'],
      incidentDate: json['incident_date'] != null ? DateTime.parse(json['incident_date']) : null,
      severity: json['severity'] ?? 'medium',
      category: json['category'],
      rootCause: json['root_cause'],
      contributingFactors: json['contributing_factors'] != null ? List<String>.from(json['contributing_factors']) : null,
      rootCauseCategory: json['root_cause_category'],
      keyLearning: json['key_learning'] ?? '',
      recommendations: json['recommendations'],
      changesMade: json['changes_made'],
      evidenceUrls: json['evidence_urls'] != null ? List<String>.from(json['evidence_urls']) : null,
      actionPlanId: json['action_plan_id']?.toString(),
      actionPlanReference: json['action_plan_reference'],
      implemented: json['implemented'] ?? false,
      implementationDate: json['implementation_date'] != null ? DateTime.parse(json['implementation_date']) : null,
      implementedBy: json['implemented_by']?.toString(),
      implementationNotes: json['implementation_notes'],
      reviewedBy: json['reviewed_by']?.toString(),
      reviewedDate: json['reviewed_date'] != null ? DateTime.parse(json['reviewed_date']) : null,
      reviewNotes: json['review_notes'],
      effectivenessRating: json['effectiveness_rating'],
      sharedWithTeam: json['shared_with_team'] ?? false,
      sharedDate: json['shared_date'] != null ? DateTime.parse(json['shared_date']) : null,
      sharedMethod: json['shared_method'],
      sharedNotes: json['shared_notes'],
      isConfidential: json['is_confidential'] ?? false,
      isTrainingRequired: json['is_training_required'] ?? false,
      trainingCourseId: json['training_course_id']?.toString(),
      status: json['status'] ?? 'draft',
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
      'incident_date': incidentDate?.toIso8601String().split('T')[0],
      'severity': severity,
      'category': category,
      'root_cause': rootCause,
      'contributing_factors': contributingFactors,
      'root_cause_category': rootCauseCategory,
      'key_learning': keyLearning,
      'recommendations': recommendations,
      'changes_made': changesMade,
      'evidence_urls': evidenceUrls,
      'action_plan_id': actionPlanId,
      'action_plan_reference': actionPlanReference,
      'implemented': implemented,
      'implementation_date': implementationDate?.toIso8601String().split('T')[0],
      'implemented_by': implementedBy,
      'implementation_notes': implementationNotes,
      'reviewed_by': reviewedBy,
      'reviewed_date': reviewedDate?.toIso8601String().split('T')[0],
      'review_notes': reviewNotes,
      'effectiveness_rating': effectivenessRating,
      'shared_with_team': sharedWithTeam,
      'shared_date': sharedDate?.toIso8601String().split('T')[0],
      'shared_method': sharedMethod,
      'shared_notes': sharedNotes,
      'is_confidential': isConfidential,
      'is_training_required': isTrainingRequired,
      'training_course_id': trainingCourseId,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_by': updatedBy,
      'updated_at': updatedAt.toIso8601String(),
      'organisation_id': organisationId,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  LessonLearnt copyWith({
    String? id,
    String? referenceNumber,
    String? title,
    String? description,
    String? sourceType,
    String? sourceId,
    String? sourceReference,
    DateTime? incidentDate,
    String? severity,
    String? category,
    String? rootCause,
    List<String>? contributingFactors,
    String? rootCauseCategory,
    String? keyLearning,
    String? recommendations,
    String? changesMade,
    List<String>? evidenceUrls,
    String? actionPlanId,
    String? actionPlanReference,
    bool? implemented,
    DateTime? implementationDate,
    String? implementedBy,
    String? implementationNotes,
    String? reviewedBy,
    DateTime? reviewedDate,
    String? reviewNotes,
    int? effectivenessRating,
    bool? sharedWithTeam,
    DateTime? sharedDate,
    String? sharedMethod,
    String? sharedNotes,
    bool? isConfidential,
    bool? isTrainingRequired,
    String? trainingCourseId,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    String? organisationId,
    DateTime? deletedAt,
  }) {
    return LessonLearnt(
      id: id ?? this.id,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      sourceReference: sourceReference ?? this.sourceReference,
      incidentDate: incidentDate ?? this.incidentDate,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      rootCause: rootCause ?? this.rootCause,
      contributingFactors: contributingFactors ?? this.contributingFactors,
      rootCauseCategory: rootCauseCategory ?? this.rootCauseCategory,
      keyLearning: keyLearning ?? this.keyLearning,
      recommendations: recommendations ?? this.recommendations,
      changesMade: changesMade ?? this.changesMade,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      actionPlanId: actionPlanId ?? this.actionPlanId,
      actionPlanReference: actionPlanReference ?? this.actionPlanReference,
      implemented: implemented ?? this.implemented,
      implementationDate: implementationDate ?? this.implementationDate,
      implementedBy: implementedBy ?? this.implementedBy,
      implementationNotes: implementationNotes ?? this.implementationNotes,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedDate: reviewedDate ?? this.reviewedDate,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      effectivenessRating: effectivenessRating ?? this.effectivenessRating,
      sharedWithTeam: sharedWithTeam ?? this.sharedWithTeam,
      sharedDate: sharedDate ?? this.sharedDate,
      sharedMethod: sharedMethod ?? this.sharedMethod,
      sharedNotes: sharedNotes ?? this.sharedNotes,
      isConfidential: isConfidential ?? this.isConfidential,
      isTrainingRequired: isTrainingRequired ?? this.isTrainingRequired,
      trainingCourseId: trainingCourseId ?? this.trainingCourseId,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      organisationId: organisationId ?? this.organisationId,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  // Helper methods
  Color get severityColor {
    switch (severity) {
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
      case 'draft':
        return Colors.grey;
      case 'review_pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'implemented':
        return Colors.green;
      case 'shared':
        return Colors.purple;
      case 'closed':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'review_pending':
        return 'Review Pending';
      case 'approved':
        return 'Approved';
      case 'implemented':
        return 'Implemented';
      case 'shared':
        return 'Shared';
      case 'closed':
        return 'Closed';
      default:
        return status.toUpperCase();
    }
  }

  String get severityLabel {
    switch (severity) {
      case 'critical':
        return 'Critical';
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      default:
        return severity.toUpperCase();
    }
  }

  String get categoryLabel {
    return category?.replaceAll('_', ' ').toUpperCase() ?? 'OTHER';
  }

  String get sourceTypeLabel {
    return sourceType?.replaceAll('_', ' ').toUpperCase() ?? 'OTHER';
  }
}