/// Represents a staff appraisal record
class Appraisal {
  final String id;
  final String employeeId;
  final String? employeeName; // Read from join with profiles
  final String reviewerId;
  final String? reviewerName; // Read from join with profiles
  final DateTime appraisalDate;
  final String? previousGoalsAchieved;
  final String? areasForImprovement;
  final String? newGoals;
  final int? overallRating; // 1-5
  final DateTime? nextAppraisalDate;
  final String? comments;
  final String status; // 'draft', 'completed', 'signed_off'
  final DateTime createdAt;
  final DateTime updatedAt;

  // Compliance fields
  final String? employeeSignature;
  final DateTime? employeeSignatureDate;
  final String? reviewerSignature;
  final DateTime? reviewerSignatureDate;
  final String? witnessName;
  final String? witnessSignature;
  final String? authorisedBy;
  final DateTime? authorisedDate;
  final DateTime? completedDate;

  Appraisal({
    required this.id,
    required this.employeeId,
    this.employeeName,
    required this.reviewerId,
    this.reviewerName,
    required this.appraisalDate,
    this.previousGoalsAchieved,
    this.areasForImprovement,
    this.newGoals,
    this.overallRating,
    this.nextAppraisalDate,
    this.comments,
    this.status = 'draft',
    required this.createdAt,
    required this.updatedAt,
    this.employeeSignature,
    this.employeeSignatureDate,
    this.reviewerSignature,
    this.reviewerSignatureDate,
    this.witnessName,
    this.witnessSignature,
    this.authorisedBy,
    this.authorisedDate,
    this.completedDate,
  });

  factory Appraisal.fromJson(Map<String, dynamic> json) {
    return Appraisal(
      id: json['id'] ?? '',
      employeeId: json['employee_id'] ?? '',
      employeeName: json['employee_name'],
      reviewerId: json['reviewer_id'] ?? '',
      reviewerName: json['reviewer_name'],
      appraisalDate: json['appraisal_date'] != null
          ? DateTime.parse(json['appraisal_date'])
          : DateTime.now(),
      previousGoalsAchieved: json['previous_goals_achieved'],
      areasForImprovement: json['areas_for_improvement'],
      newGoals: json['new_goals'],
      overallRating: json['overall_rating'],
      nextAppraisalDate: json['next_appraisal_date'] != null
          ? DateTime.parse(json['next_appraisal_date'])
          : null,
      comments: json['comments'],
      status: json['status'] ?? 'draft',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      employeeSignature: json['employee_signature'],
      employeeSignatureDate: json['employee_signature_date'] != null
          ? DateTime.parse(json['employee_signature_date'])
          : null,
      reviewerSignature: json['reviewer_signature'],
      reviewerSignatureDate: json['reviewer_signature_date'] != null
          ? DateTime.parse(json['reviewer_signature_date'])
          : null,
      witnessName: json['witness_name'],
      witnessSignature: json['witness_signature'],
      authorisedBy: json['authorised_by'],
      authorisedDate: json['authorised_date'] != null
          ? DateTime.parse(json['authorised_date'])
          : null,
      completedDate: json['completed_date'] != null
          ? DateTime.parse(json['completed_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'employee_id': employeeId,
      'reviewer_id': reviewerId,
      'appraisal_date': appraisalDate.toIso8601String().split('T').first,
      'previous_goals_achieved': previousGoalsAchieved,
      'areas_for_improvement': areasForImprovement,
      'new_goals': newGoals,
      'overall_rating': overallRating,
      'next_appraisal_date': nextAppraisalDate?.toIso8601String().split('T').first,
      'comments': comments,
      'status': status,
      'employee_signature': employeeSignature,
      'employee_signature_date': employeeSignatureDate?.toIso8601String().split('T').first,
      'reviewer_signature': reviewerSignature,
      'reviewer_signature_date': reviewerSignatureDate?.toIso8601String().split('T').first,
      'witness_name': witnessName,
      'witness_signature': witnessSignature,
      'authorised_by': authorisedBy,
      'authorised_date': authorisedDate?.toIso8601String().split('T').first,
      'completed_date': completedDate?.toIso8601String().split('T').first,
    };
  }

  /// Check if all compliance fields are filled (for signed-off)
  bool get isFullySigned {
    return employeeSignature != null &&
        employeeSignatureDate != null &&
        reviewerSignature != null &&
        reviewerSignatureDate != null &&
        authorisedBy != null &&
        authorisedDate != null &&
        completedDate != null;
  }

  /// Get rating color based on overall rating
  String get ratingColor {
    if (overallRating == null) return 'grey';
    if (overallRating! >= 4) return 'green';
    if (overallRating! >= 3) return 'orange';
    return 'red';
  }

  /// Get rating label
  String get ratingLabel {
    if (overallRating == null) return 'Not rated';
    return '$overallRating/5';
  }

  /// Get status display text
  String get statusDisplay {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'completed':
        return 'Completed';
      case 'signed_off':
        return 'Signed Off';
      default:
        return status;
    }
  }

  /// Calculate days since last appraisal
  int get daysSinceAppraisal {
    return DateTime.now().difference(appraisalDate).inDays;
  }

  /// Calculate days until next appraisal (negative if overdue)
  int get daysUntilNextAppraisal {
    if (nextAppraisalDate == null) return 365;
    return nextAppraisalDate!.difference(DateTime.now()).inDays;
  }

  /// Check if next appraisal is due soon (within 60 days)
  bool get isNextAppraisalDueSoon => daysUntilNextAppraisal <= 60 && daysUntilNextAppraisal > 30;

  /// Check if next appraisal is overdue (within 30 days)
  bool get isNextAppraisalOverdue => daysUntilNextAppraisal <= 30;

  /// Get next appraisal urgency color
  String get nextAppraisalUrgencyColor {
    if (isNextAppraisalOverdue) return 'red';
    if (isNextAppraisalDueSoon) return 'orange';
    return 'green';
  }

  /// Create a new Appraisal for insertion (without id/timestamps)
  factory Appraisal.createNew({
    required String employeeId,
    required String reviewerId,
    required DateTime appraisalDate,
    String? previousGoalsAchieved,
    String? areasForImprovement,
    String? newGoals,
    int? overallRating,
    DateTime? nextAppraisalDate,
    String? comments,
    String status = 'draft',
    String? employeeSignature,
    DateTime? employeeSignatureDate,
    String? reviewerSignature,
    DateTime? reviewerSignatureDate,
    String? witnessName,
    String? witnessSignature,
    String? authorisedBy,
    DateTime? authorisedDate,
    DateTime? completedDate,
  }) {
    final nextDate = nextAppraisalDate ?? appraisalDate.add(const Duration(days: 365));
    return Appraisal(
      id: '',
      employeeId: employeeId,
      reviewerId: reviewerId,
      appraisalDate: appraisalDate,
      previousGoalsAchieved: previousGoalsAchieved,
      areasForImprovement: areasForImprovement,
      newGoals: newGoals,
      overallRating: overallRating,
      nextAppraisalDate: nextDate,
      comments: comments,
      status: status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      employeeSignature: employeeSignature,
      employeeSignatureDate: employeeSignatureDate,
      reviewerSignature: reviewerSignature,
      reviewerSignatureDate: reviewerSignatureDate,
      witnessName: witnessName,
      witnessSignature: witnessSignature,
      authorisedBy: authorisedBy,
      authorisedDate: authorisedDate,
      completedDate: completedDate,
    );
  }
}