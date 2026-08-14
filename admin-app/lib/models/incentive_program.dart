class IncentiveProgram {
  final String id;
  final String programName;
  final String programType;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final double? totalBudget;
  final double budgetSpent;
  final String? eligibilityCriteria;
  final String? rules;
  final int maxAwardsPerEmployee;
  final bool isActive;
  final String? organisationId;
  final String? createdById;
  final DateTime createdAt;
  final DateTime updatedAt;

  IncentiveProgram({
    required this.id,
    required this.programName,
    required this.programType,
    this.description,
    required this.startDate,
    this.endDate,
    this.totalBudget,
    this.budgetSpent = 0,
    this.eligibilityCriteria,
    this.rules,
    this.maxAwardsPerEmployee = 1,
    this.isActive = true,
    this.organisationId,
    this.createdById,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IncentiveProgram.fromJson(Map<String, dynamic> json) {
    return IncentiveProgram(
      id: json['id'] ?? '',
      programName: json['program_name'] ?? '',
      programType: json['program_type'] ?? 'other',
      description: json['description'],
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      totalBudget: json['total_budget']?.toDouble(),
      budgetSpent: json['budget_spent']?.toDouble() ?? 0,
      eligibilityCriteria: json['eligibility_criteria'],
      rules: json['rules'],
      maxAwardsPerEmployee: json['max_awards_per_employee'] ?? 1,
      isActive: json['is_active'] ?? true,
      organisationId: json['organisation_id'],
      createdById: json['created_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'program_name': programName,
      'program_type': programType,
      'description': description,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'total_budget': totalBudget,
      'budget_spent': budgetSpent,
      'eligibility_criteria': eligibilityCriteria,
      'rules': rules,
      'max_awards_per_employee': maxAwardsPerEmployee,
      'is_active': isActive,
      'organisation_id': organisationId,
      'created_by': createdById,
    };
  }

  String getProgramTypeDisplay() {
    switch (programType) {
      case 'points_based': return 'Points Based';
      case 'monetary_bonus': return 'Monetary Bonus';
      case 'recognition_award': return 'Recognition Award';
      case 'performance_bonus': return 'Performance Bonus';
      case 'referral_bonus': return 'Referral Bonus';
      case 'retention_bonus': return 'Retention Bonus';
      case 'team_bonus': return 'Team Bonus';
      case 'service_award': return 'Service Award';
      default: return programType;
    }
  }

  double getBudgetRemaining() {
    if (totalBudget == null) return 0;
    return totalBudget! - budgetSpent;
  }

  bool get isOverBudget => totalBudget != null && budgetSpent > totalBudget!;
}