import 'package:flutter/material.dart';

class Policy {
  final String? id;
  final String policyTitle;
  final String policyReference;
  final String version;
  final String? department;
  final String? category;
  final String? subCategory;
  final String? summary;
  final String policyBody;
  final String? scope;
  final String? purpose;
  final List<Map<String, dynamic>>? definitions;
  final List<Map<String, dynamic>>? responsibilities;
  final List<String>? regulatoryBasis;
  final List<String>? standards;
  final String status;
  final DateTime? approvalDate;
  final String? approvedBy;
  final DateTime? publishDate;
  final String? publishedBy;
  final DateTime? effectiveDate;
  final DateTime? reviewDate;
  final DateTime? nextReviewDate;
  final DateTime? archivedDate;
  final String? ownerId;
  final String? ownerName;
  final String? authorId;
  final String? authorName;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileType;
  final bool trainingRequired;
  final String? trainingCourseId;
  final String? trainingNotes;
  final List<String>? tags;
  final List<String>? keywords;
  final List<Map<String, dynamic>> reviewHistory;
  final List<Map<String, dynamic>> readBy;
  final List<Map<String, dynamic>> acknowledgedBy;
  final bool isMandatory;
  final String? nonComplianceRisk;
  final String? enforcementNotes;
  final String? notes;
  final String? internalNotes;
  final String? createdBy;
  final DateTime createdAt;
  final String? updatedBy;
  final DateTime updatedAt;
  final String organisationId;
  final DateTime? deletedAt;

  Policy({
    this.id,
    required this.policyTitle,
    required this.policyReference,
    this.version = '1.0',
    this.department,
    this.category,
    this.subCategory,
    this.summary,
    required this.policyBody,
    this.scope,
    this.purpose,
    this.definitions,
    this.responsibilities,
    this.regulatoryBasis,
    this.standards,
    this.status = 'draft',
    this.approvalDate,
    this.approvedBy,
    this.publishDate,
    this.publishedBy,
    this.effectiveDate,
    this.reviewDate,
    this.nextReviewDate,
    this.archivedDate,
    this.ownerId,
    this.ownerName,
    this.authorId,
    this.authorName,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileType,
    this.trainingRequired = false,
    this.trainingCourseId,
    this.trainingNotes,
    this.tags,
    this.keywords,
    this.reviewHistory = const [],
    this.readBy = const [],
    this.acknowledgedBy = const [],
    this.isMandatory = true,
    this.nonComplianceRisk,
    this.enforcementNotes,
    this.notes,
    this.internalNotes,
    this.createdBy,
    required this.createdAt,
    this.updatedBy,
    required this.updatedAt,
    required this.organisationId,
    this.deletedAt,
  });

  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      id: json['id']?.toString(),
      policyTitle: json['policy_title'] ?? '',
      policyReference: json['policy_reference'] ?? '',
      version: json['version'] ?? '1.0',
      department: json['department'],
      category: json['category'],
      subCategory: json['sub_category'],
      summary: json['summary'],
      policyBody: json['policy_body'] ?? '',
      scope: json['scope'],
      purpose: json['purpose'],
      definitions: json['definitions'] != null ? List<Map<String, dynamic>>.from(json['definitions']) : null,
      responsibilities: json['responsibilities'] != null ? List<Map<String, dynamic>>.from(json['responsibilities']) : null,
      regulatoryBasis: json['regulatory_basis'] != null ? List<String>.from(json['regulatory_basis']) : null,
      standards: json['standards'] != null ? List<String>.from(json['standards']) : null,
      status: json['status'] ?? 'draft',
      approvalDate: json['approval_date'] != null ? DateTime.parse(json['approval_date']) : null,
      approvedBy: json['approved_by']?.toString(),
      publishDate: json['publish_date'] != null ? DateTime.parse(json['publish_date']) : null,
      publishedBy: json['published_by']?.toString(),
      effectiveDate: json['effective_date'] != null ? DateTime.parse(json['effective_date']) : null,
      reviewDate: json['review_date'] != null ? DateTime.parse(json['review_date']) : null,
      nextReviewDate: json['next_review_date'] != null ? DateTime.parse(json['next_review_date']) : null,
      archivedDate: json['archived_date'] != null ? DateTime.parse(json['archived_date']) : null,
      ownerId: json['owner_id']?.toString(),
      ownerName: json['owner_name'],
      authorId: json['author_id']?.toString(),
      authorName: json['author_name'],
      fileUrl: json['file_url'],
      fileName: json['file_name'],
      fileSize: json['file_size'],
      fileType: json['file_type'],
      trainingRequired: json['training_required'] ?? false,
      trainingCourseId: json['training_course_id']?.toString(),
      trainingNotes: json['training_notes'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      keywords: json['keywords'] != null ? List<String>.from(json['keywords']) : null,
      reviewHistory: json['review_history'] != null ? List<Map<String, dynamic>>.from(json['review_history']) : [],
      readBy: json['read_by'] != null ? List<Map<String, dynamic>>.from(json['read_by']) : [],
      acknowledgedBy: json['acknowledged_by'] != null ? List<Map<String, dynamic>>.from(json['acknowledged_by']) : [],
      isMandatory: json['is_mandatory'] ?? true,
      nonComplianceRisk: json['non_compliance_risk'],
      enforcementNotes: json['enforcement_notes'],
      notes: json['notes'],
      internalNotes: json['internal_notes'],
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
      'policy_title': policyTitle,
      'policy_reference': policyReference,
      'version': version,
      'department': department,
      'category': category,
      'sub_category': subCategory,
      'summary': summary,
      'policy_body': policyBody,
      'scope': scope,
      'purpose': purpose,
      'definitions': definitions,
      'responsibilities': responsibilities,
      'regulatory_basis': regulatoryBasis,
      'standards': standards,
      'status': status,
      'approval_date': approvalDate?.toIso8601String().split('T')[0],
      'approved_by': approvedBy,
      'publish_date': publishDate?.toIso8601String().split('T')[0],
      'published_by': publishedBy,
      'effective_date': effectiveDate?.toIso8601String().split('T')[0],
      'review_date': reviewDate?.toIso8601String().split('T')[0],
      'next_review_date': nextReviewDate?.toIso8601String().split('T')[0],
      'archived_date': archivedDate?.toIso8601String().split('T')[0],
      'owner_id': ownerId,
      'owner_name': ownerName,
      'author_id': authorId,
      'author_name': authorName,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'file_type': fileType,
      'training_required': trainingRequired,
      'training_course_id': trainingCourseId,
      'training_notes': trainingNotes,
      'tags': tags,
      'keywords': keywords,
      'review_history': reviewHistory,
      'read_by': readBy,
      'acknowledged_by': acknowledgedBy,
      'is_mandatory': isMandatory,
      'non_compliance_risk': nonComplianceRisk,
      'enforcement_notes': enforcementNotes,
      'notes': notes,
      'internal_notes': internalNotes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_by': updatedBy,
      'updated_at': updatedAt.toIso8601String(),
      'organisation_id': organisationId,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  Policy copyWith({
    String? id,
    String? policyTitle,
    String? policyReference,
    String? version,
    String? department,
    String? category,
    String? subCategory,
    String? summary,
    String? policyBody,
    String? scope,
    String? purpose,
    List<Map<String, dynamic>>? definitions,
    List<Map<String, dynamic>>? responsibilities,
    List<String>? regulatoryBasis,
    List<String>? standards,
    String? status,
    DateTime? approvalDate,
    String? approvedBy,
    DateTime? publishDate,
    String? publishedBy,
    DateTime? effectiveDate,
    DateTime? reviewDate,
    DateTime? nextReviewDate,
    DateTime? archivedDate,
    String? ownerId,
    String? ownerName,
    String? authorId,
    String? authorName,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? fileType,
    bool? trainingRequired,
    String? trainingCourseId,
    String? trainingNotes,
    List<String>? tags,
    List<String>? keywords,
    List<Map<String, dynamic>>? reviewHistory,
    List<Map<String, dynamic>>? readBy,
    List<Map<String, dynamic>>? acknowledgedBy,
    bool? isMandatory,
    String? nonComplianceRisk,
    String? enforcementNotes,
    String? notes,
    String? internalNotes,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    String? organisationId,
    DateTime? deletedAt,
  }) {
    return Policy(
      id: id ?? this.id,
      policyTitle: policyTitle ?? this.policyTitle,
      policyReference: policyReference ?? this.policyReference,
      version: version ?? this.version,
      department: department ?? this.department,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      summary: summary ?? this.summary,
      policyBody: policyBody ?? this.policyBody,
      scope: scope ?? this.scope,
      purpose: purpose ?? this.purpose,
      definitions: definitions ?? this.definitions,
      responsibilities: responsibilities ?? this.responsibilities,
      regulatoryBasis: regulatoryBasis ?? this.regulatoryBasis,
      standards: standards ?? this.standards,
      status: status ?? this.status,
      approvalDate: approvalDate ?? this.approvalDate,
      approvedBy: approvedBy ?? this.approvedBy,
      publishDate: publishDate ?? this.publishDate,
      publishedBy: publishedBy ?? this.publishedBy,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      reviewDate: reviewDate ?? this.reviewDate,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      archivedDate: archivedDate ?? this.archivedDate,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      trainingRequired: trainingRequired ?? this.trainingRequired,
      trainingCourseId: trainingCourseId ?? this.trainingCourseId,
      trainingNotes: trainingNotes ?? this.trainingNotes,
      tags: tags ?? this.tags,
      keywords: keywords ?? this.keywords,
      reviewHistory: reviewHistory ?? this.reviewHistory,
      readBy: readBy ?? this.readBy,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      isMandatory: isMandatory ?? this.isMandatory,
      nonComplianceRisk: nonComplianceRisk ?? this.nonComplianceRisk,
      enforcementNotes: enforcementNotes ?? this.enforcementNotes,
      notes: notes ?? this.notes,
      internalNotes: internalNotes ?? this.internalNotes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      organisationId: organisationId ?? this.organisationId,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  // Helper methods
  Color get statusColor {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'review_pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'published':
        return Colors.green;
      case 'archived':
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
      case 'published':
        return 'Published';
      case 'archived':
        return 'Archived';
      default:
        return status.toUpperCase();
    }
  }

  String get categoryLabel {
    return category?.replaceAll('_', ' ').toUpperCase() ?? 'OTHER';
  }

  bool get isReviewDue {
    if (nextReviewDate == null) return false;
    return nextReviewDate!.isBefore(DateTime.now());
  }

  int get daysUntilReview {
    if (nextReviewDate == null) return 0;
    return nextReviewDate!.difference(DateTime.now()).inDays;
  }

  bool hasStaffRead(String staffId) {
    return readBy.any((entry) => entry['staff_id'] == staffId);
  }

  bool hasStaffAcknowledged(String staffId) {
    return acknowledgedBy.any((entry) => entry['staff_id'] == staffId);
  }
}