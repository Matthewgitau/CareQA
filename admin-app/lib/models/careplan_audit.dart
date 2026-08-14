import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class CarePlanAuditItem {
  final int id;
  final String documentName;
  final String? category;
  final int displayOrder;
  final bool isActive;

  CarePlanAuditItem({
    required this.id,
    required this.documentName,
    this.category,
    required this.displayOrder,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_name': documentName,
      'category': category,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }

  factory CarePlanAuditItem.fromMap(Map<String, dynamic> map) {
    return CarePlanAuditItem(
      id: map['id'] as int,
      documentName: map['document_name'] as String,
      category: map['category'],
      displayOrder: map['display_order'] as int,
      isActive: map['is_active'] as bool,
    );
  }
}

class CarePlanAuditAnswer {
  final String id;
  final String auditId;
  final int itemId;
  bool present;
  String? comment;
  String? actionNeeded;

  CarePlanAuditAnswer({
    required this.id,
    required this.auditId,
    required this.itemId,
    required this.present,
    this.comment,
    this.actionNeeded,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'audit_id': auditId,
      'item_id': itemId,
      'present': present,
      'comment': comment,
      'action_needed': actionNeeded,
    };
  }

  factory CarePlanAuditAnswer.fromMap(Map<String, dynamic> map) {
    return CarePlanAuditAnswer(
      id: map['id'] ?? '',
      auditId: map['audit_id'] ?? '',
      itemId: map['item_id'] as int,
      present: map['present'] as bool,
      comment: map['comment'],
      actionNeeded: map['action_needed'],
    );
  }
}

class CarePlanAudit {
  final String id;
  final String serviceUserId;
  final String serviceUserName;
  final String auditorId;
  final String auditorName;
  final DateTime auditDate;
  final String carePlanName;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Calculated metrics
  int get totalItems => answers.length;
  int get presentItems => answers.values.where((a) => a.present).length;
  int get missingItems => answers.values.where((a) => !a.present).length;
  int get itemsWithComments => answers.values.where((a) => a.comment != null && a.comment!.isNotEmpty).length;
  int get itemsWithActions => answers.values.where((a) => a.actionNeeded != null && a.actionNeeded!.isNotEmpty).length;

  // Answers map (itemId -> answer)
  final Map<int, CarePlanAuditAnswer> answers;

  CarePlanAudit({
    required this.id,
    required this.serviceUserId,
    required this.serviceUserName,
    required this.auditorId,
    required this.auditorName,
    required this.auditDate,
    required this.carePlanName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.answers,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_user_id': serviceUserId,
      'service_user_name': serviceUserName,
      'auditor_id': auditorId,
      'auditor_name': auditorName,
      'audit_date': auditDate.toIso8601String(),
      'care_plan_name': carePlanName,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CarePlanAudit.fromMap(Map<String, dynamic> map) {
    return CarePlanAudit(
      id: map['id'] ?? '',
      serviceUserId: map['service_user_id'] ?? '',
      serviceUserName: map['service_user_name'] ?? '',
      auditorId: map['auditor_id'] ?? '',
      auditorName: map['auditor_name'] ?? '',
      auditDate: (map['audit_date'] as DateTime?) ?? DateTime.now(),
      carePlanName: map['care_plan_name'] ?? '',
      status: map['status'] ?? 'draft',
      createdAt: (map['created_at'] as DateTime?) ?? DateTime.now(),
      updatedAt: (map['updated_at'] as DateTime?) ?? DateTime.now(),
      answers: {},
    );
  }

  // Factory for creating from audit with answers
  factory CarePlanAudit.fromAuditWithAnswers(Map<String, dynamic> auditData, List<Map<String, dynamic>> answersData) {
    final audit = CarePlanAudit.fromMap(auditData);
    
    // Convert answers data to map
    final answers = <int, CarePlanAuditAnswer>{};
    for (final answerData in answersData) {
      final answer = CarePlanAuditAnswer.fromMap(answerData);
      answers[answer.itemId] = answer;
    }
    
    return CarePlanAudit(
      id: audit.id,
      serviceUserId: audit.serviceUserId,
      serviceUserName: audit.serviceUserName,
      auditorId: audit.auditorId,
      auditorName: audit.auditorName,
      auditDate: audit.auditDate,
      carePlanName: audit.carePlanName,
      status: audit.status,
      createdAt: audit.createdAt,
      updatedAt: audit.updatedAt,
      answers: answers,
    );
  }
}

class CarePlanAuditSummary {
  final int totalItems;
  final int presentItems;
  final int missingItems;
  final int itemsWithComments;
  final int itemsWithActions;
  final DateTime auditDate;
  final String auditorName;
  final String serviceUserName;
  final String carePlanName;
  final String status;

  CarePlanAuditSummary({
    required this.totalItems,
    required this.presentItems,
    required this.missingItems,
    required this.itemsWithComments,
    required this.itemsWithActions,
    required this.auditDate,
    required this.auditorName,
    required this.serviceUserName,
    required this.carePlanName,
    required this.status,
  });

  factory CarePlanAuditSummary.fromMap(Map<String, dynamic> map) {
    return CarePlanAuditSummary(
      totalItems: map['total_items'] as int,
      presentItems: map['present_items'] as int,
      missingItems: map['missing_items'] as int,
      itemsWithComments: map['items_with_comments'] as int,
      itemsWithActions: map['items_with_actions'] as int,
      auditDate: (map['audit_date'] as DateTime?) ?? DateTime.now(),
      auditorName: map['auditor_name'] as String,
      serviceUserName: map['service_user_name'] as String,
      carePlanName: map['care_plan_name'] as String,
      status: map['status'] as String,
    );
  }
}

class CarePlanAuditValidation {
  final bool isComplete;
  final int missingItems;
  final List<String> warnings;

  CarePlanAuditValidation({
    required this.isComplete,
    required this.missingItems,
    required this.warnings,
  });

  factory CarePlanAuditValidation.fromMap(Map<String, dynamic> map) {
    return CarePlanAuditValidation(
      isComplete: map['is_complete'] as bool,
      missingItems: map['missing_items'] as int,
      warnings: List<String>.from(map['warnings'] ?? []),
    );
  }
}

class CarePlanAuditSearchResult {
  final String auditId;
  final String serviceUserName;
  final DateTime auditDate;
  final String auditorName;
  final String carePlanName;
  final String status;
  final DateTime createdAt;

  CarePlanAuditSearchResult({
    required this.auditId,
    required this.serviceUserName,
    required this.auditDate,
    required this.auditorName,
    required this.carePlanName,
    required this.status,
    required this.createdAt,
  });

  factory CarePlanAuditSearchResult.fromMap(Map<String, dynamic> map) {
    return CarePlanAuditSearchResult(
      auditId: map['audit_id'] ?? '',
      serviceUserName: map['service_user_name'] ?? '',
      auditDate: (map['audit_date'] as DateTime?) ?? DateTime.now(),
      auditorName: map['auditor_name'] as String,
      carePlanName: map['care_plan_name'] as String,
      status: map['status'] as String,
      createdAt: (map['created_at'] as DateTime?) ?? DateTime.now(),
    );
  }
}

class CarePlanAuditCategory {
  final String category;
  final List<CarePlanAuditItem> items;

  CarePlanAuditCategory({
    required this.category,
    required this.items,
  });

  factory CarePlanAuditCategory.fromMap(Map<String, dynamic> map) {
    final itemsData = map['items'] as List<dynamic>;
    final items = itemsData.map((i) => CarePlanAuditItem.fromMap(i)).toList();
    
    return CarePlanAuditCategory(
      category: map['category'] as String,
      items: items,
    );
  }
}

// Helper classes for answer options
class CarePlanAuditAnswerOption {
  final bool value;
  final String label;
  final Color color;

  CarePlanAuditAnswerOption(this.value, this.label, this.color);

  @override
  String toString() => label;
}

// Constants for answer options
class CarePlanAuditConstants {
  static final List<CarePlanAuditAnswerOption> answerOptions = [
    CarePlanAuditAnswerOption(true, 'Present', Colors.green),
    CarePlanAuditAnswerOption(false, 'Missing', Colors.red),
  ];

  static final List<String> categories = [
    'Legal',
    'Personal',
    'Operational',
    'Clinical',
    'Admission',
    'Social',
    'Care Planning',
    'Risk',
    'Communication',
    'Health',
    'Mental Health',
    'Personal Care',
    'Continence',
    'Mobility',
    'Behaviour',
    'Specialist',
    'Nutrition',
    'Medication',
    'Skin',
    'Finance',
    'Cultural',
    'Safety',
    'Sleep',
    'End of Life',
  ];
}