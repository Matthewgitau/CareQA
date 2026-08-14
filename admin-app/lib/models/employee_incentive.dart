class EmployeeIncentive {
  final String id;
  final String? staffId;
  final String staffName;
  final String? employeeNumber;
  final String? department;
  final String? jobRole;
  final String incentiveType;
  final String? incentiveProgramId;
  final int pointsAwarded;
  final int pointsBalance;
  final double monetaryValue;
  final String currency;
  final DateTime awardDate;
  final String awardTitle;
  final String? awardDescription;
  final String awardReason;
  final String? nominatedById;
  final String? nominatedByName;
  final String? nominationNotes;
  final String? approvedById;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? approvalNotes;
  final bool isPublic;
  final String? certificateUrl;
  final String? photoUrl;
  final String? socialSharePost;
  final bool redeemed;
  final DateTime? redeemedAt;
  final String? redemptionDetails;
  final String? employeeFeedback;
  final String? managerFeedback;
  final String? organisationId;
  final String? createdById;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmployeeIncentive({
    required this.id,
    this.staffId,
    required this.staffName,
    this.employeeNumber,
    this.department,
    this.jobRole,
    required this.incentiveType,
    this.incentiveProgramId,
    this.pointsAwarded = 0,
    this.pointsBalance = 0,
    this.monetaryValue = 0,
    this.currency = 'GBP',
    required this.awardDate,
    required this.awardTitle,
    this.awardDescription,
    required this.awardReason,
    this.nominatedById,
    this.nominatedByName,
    this.nominationNotes,
    this.approvedById,
    this.approvedByName,
    this.approvedAt,
    this.approvalNotes,
    this.isPublic = true,
    this.certificateUrl,
    this.photoUrl,
    this.socialSharePost,
    this.redeemed = false,
    this.redeemedAt,
    this.redemptionDetails,
    this.employeeFeedback,
    this.managerFeedback,
    this.organisationId,
    this.createdById,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmployeeIncentive.fromJson(Map<String, dynamic> json) {
    return EmployeeIncentive(
      id: json['id'] ?? '',
      staffId: json['staff_id'],
      staffName: json['staff_name'] ?? '',
      employeeNumber: json['employee_number'],
      department: json['department'],
      jobRole: json['job_role'],
      incentiveType: json['incentive_type'] ?? 'other',
      incentiveProgramId: json['incentive_program_id'],
      pointsAwarded: json['points_awarded'] ?? 0,
      pointsBalance: json['points_balance'] ?? 0,
      monetaryValue: (json['monetary_value'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'GBP',
      awardDate: json['award_date'] != null ? DateTime.parse(json['award_date']) : DateTime.now(),
      awardTitle: json['award_title'] ?? '',
      awardDescription: json['award_description'],
      awardReason: json['award_reason'] ?? '',
      nominatedById: json['nominated_by'],
      nominatedByName: json['nominated_by_name'],
      nominationNotes: json['nomination_notes'],
      approvedById: json['approved_by'],
      approvedByName: json['approved_by_name'],
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      approvalNotes: json['approval_notes'],
      isPublic: json['is_public'] ?? true,
      certificateUrl: json['certificate_url'],
      photoUrl: json['photo_url'],
      socialSharePost: json['social_share_post'],
      redeemed: json['redeemed'] ?? false,
      redeemedAt: json['redeemed_at'] != null ? DateTime.parse(json['redeemed_at']) : null,
      redemptionDetails: json['redemption_details'],
      employeeFeedback: json['employee_feedback'],
      managerFeedback: json['manager_feedback'],
      organisationId: json['organisation_id'],
      createdById: json['created_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'staff_id': staffId,
      'staff_name': staffName,
      'employee_number': employeeNumber,
      'department': department,
      'job_role': jobRole,
      'incentive_type': incentiveType,
      'incentive_program_id': incentiveProgramId,
      'points_awarded': pointsAwarded,
      'points_balance': pointsBalance,
      'monetary_value': monetaryValue,
      'currency': currency,
      'award_date': awardDate.toIso8601String().split('T').first,
      'award_title': awardTitle,
      'award_description': awardDescription,
      'award_reason': awardReason,
      'nominated_by': nominatedById,
      'nominated_by_name': nominatedByName,
      'nomination_notes': nominationNotes,
      'approved_by': approvedById,
      'approved_by_name': approvedByName,
      'approved_at': approvedAt?.toIso8601String(),
      'approval_notes': approvalNotes,
      'is_public': isPublic,
      'certificate_url': certificateUrl,
      'photo_url': photoUrl,
      'social_share_post': socialSharePost,
      'redeemed': redeemed,
      'redeemed_at': redeemedAt?.toIso8601String(),
      'redemption_details': redemptionDetails,
      'employee_feedback': employeeFeedback,
      'manager_feedback': managerFeedback,
      'organisation_id': organisationId,
      'created_by': createdById,
    };
  }

  String getIncentiveTypeDisplay() {
    switch (incentiveType) {
      case 'employee_of_month': return 'Employee of the Month';
      case 'employee_of_quarter': return 'Employee of the Quarter';
      case 'employee_of_year': return 'Employee of the Year';
      case 'spot_award': return 'Spot Award';
      case 'performance_bonus': return 'Performance Bonus';
      case 'referral_bonus': return 'Referral Bonus';
      case 'retention_bonus': return 'Retention Bonus';
      case 'team_award': return 'Team Award';
      case 'long_service_award': return 'Long Service Award';
      case 'outstanding_care': return 'Outstanding Care Award';
      case 'innovation_award': return 'Innovation Award';
      case 'leadership_award': return 'Leadership Award';
      case 'safety_hero': return 'Safety Hero';
      case 'customer_service_excellence': return 'Customer Service Excellence';
      default: return incentiveType;
    }
  }
}