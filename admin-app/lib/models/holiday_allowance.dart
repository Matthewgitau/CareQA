class HolidayAllowance {
  final String id;
  final String? staffId;
  final int year;
  final double totalAllowanceDays;
  final double takenDays;
  final double remainingDays;
  final double carriedOverDays;
  final String? notes;
  final String? organisationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  HolidayAllowance({
    required this.id,
    this.staffId,
    required this.year,
    this.totalAllowanceDays = 28.0,
    this.takenDays = 0.0,
    this.remainingDays = 28.0,
    this.carriedOverDays = 0.0,
    this.notes,
    this.organisationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HolidayAllowance.fromJson(Map<String, dynamic> json) {
    return HolidayAllowance(
      id: json['id'] ?? '',
      staffId: json['staff_id'],
      year: json['year'] ?? DateTime.now().year,
      totalAllowanceDays: (json['total_allowance_days'] ?? 28).toDouble(),
      takenDays: (json['taken_days'] ?? 0).toDouble(),
      remainingDays: (json['remaining_days'] ?? 28).toDouble(),
      carriedOverDays: (json['carried_over_days'] ?? 0).toDouble(),
      notes: json['notes'],
      organisationId: json['organisation_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'staff_id': staffId,
      'year': year,
      'total_allowance_days': totalAllowanceDays,
      'taken_days': takenDays,
      'carried_over_days': carriedOverDays,
      'notes': notes,
    };
  }

  double get utilizationPercentage {
    if (totalAllowanceDays <= 0) return 0;
    return (takenDays / totalAllowanceDays) * 100;
  }
}