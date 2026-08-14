class PointsAccount {
  final String id;
  final String? staffId;
  final String staffName;
  final int totalPointsEarned;
  final int totalPointsRedeemed;
  final int currentPointsBalance;
  final DateTime? lastActivityAt;
  final String? organisationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  PointsAccount({
    required this.id,
    this.staffId,
    required this.staffName,
    this.totalPointsEarned = 0,
    this.totalPointsRedeemed = 0,
    this.currentPointsBalance = 0,
    this.lastActivityAt,
    this.organisationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PointsAccount.fromJson(Map<String, dynamic> json) {
    return PointsAccount(
      id: json['id'] ?? '',
      staffId: json['staff_id'],
      staffName: json['staff_name'] ?? '',
      totalPointsEarned: json['total_points_earned'] ?? 0,
      totalPointsRedeemed: json['total_points_redeemed'] ?? 0,
      currentPointsBalance: json['current_points_balance'] ?? 0,
      lastActivityAt: json['last_activity_at'] != null ? DateTime.parse(json['last_activity_at']) : null,
      organisationId: json['organisation_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'staff_id': staffId,
      'staff_name': staffName,
      'total_points_earned': totalPointsEarned,
      'total_points_redeemed': totalPointsRedeemed,
      'last_activity_at': lastActivityAt?.toIso8601String(),
      'organisation_id': organisationId,
    };
  }

  String getBalanceStatus() {
    if (currentPointsBalance >= 1000) return 'Gold Member';
    if (currentPointsBalance >= 500) return 'Silver Member';
    if (currentPointsBalance >= 100) return 'Bronze Member';
    return 'Member';
  }

  int getPointsToNextLevel() {
    if (currentPointsBalance < 100) return 100 - currentPointsBalance;
    if (currentPointsBalance < 500) return 500 - currentPointsBalance;
    if (currentPointsBalance < 1000) return 1000 - currentPointsBalance;
    return 0;
  }
}