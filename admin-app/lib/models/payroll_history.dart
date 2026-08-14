class PayrollHistory {
  final String id;
  final String? staffId;
  final String staffName;
  final String? employeeNumber;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String periodLabel;
  final double regularHours;
  final double overtimeHours;
  final double totalHours;
  final double? hourlyRate;
  final double? overtimeRate;
  final double? regularPay;
  final double? overtimePay;
  final double holidayPay;
  final double sickPay;
  final double bonusPay;
  final double deductions;
  final double grossPay;
  final double taxDeducted;
  final double niDeducted;
  final String status;
  final DateTime? processedAt;
  final DateTime? paidAt;
  final String? notes;
  final String? organisationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  PayrollHistory({
    required this.id,
    this.staffId,
    required this.staffName,
    this.employeeNumber,
    required this.periodStart,
    required this.periodEnd,
    this.periodLabel = '',
    this.regularHours = 0,
    this.overtimeHours = 0,
    this.totalHours = 0,
    this.hourlyRate,
    this.overtimeRate,
    this.regularPay,
    this.overtimePay,
    this.holidayPay = 0,
    this.sickPay = 0,
    this.bonusPay = 0,
    this.deductions = 0,
    this.grossPay = 0,
    this.taxDeducted = 0,
    this.niDeducted = 0,
    this.status = 'draft',
    this.processedAt,
    this.paidAt,
    this.notes,
    this.organisationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PayrollHistory.fromJson(Map<String, dynamic> json) {
    return PayrollHistory(
      id: json['id'] ?? '',
      staffId: json['staff_id'],
      staffName: json['staff_name'] ?? '',
      employeeNumber: json['employee_number'],
      periodStart: json['period_start'] != null ? DateTime.parse(json['period_start']) : DateTime.now(),
      periodEnd: json['period_end'] != null ? DateTime.parse(json['period_end']) : DateTime.now(),
      periodLabel: json['period_label'] ?? '',
      regularHours: (json['regular_hours'] ?? 0).toDouble(),
      overtimeHours: (json['overtime_hours'] ?? 0).toDouble(),
      totalHours: (json['total_hours'] ?? 0).toDouble(),
      hourlyRate: json['hourly_rate']?.toDouble(),
      overtimeRate: json['overtime_rate']?.toDouble(),
      regularPay: json['regular_pay']?.toDouble(),
      overtimePay: json['overtime_pay']?.toDouble(),
      holidayPay: (json['holiday_pay'] ?? 0).toDouble(),
      sickPay: (json['sick_pay'] ?? 0).toDouble(),
      bonusPay: (json['bonus_pay'] ?? 0).toDouble(),
      deductions: (json['deductions'] ?? 0).toDouble(),
      grossPay: (json['gross_pay'] ?? 0).toDouble(),
      taxDeducted: (json['tax_deducted'] ?? 0).toDouble(),
      niDeducted: (json['ni_deducted'] ?? 0).toDouble(),
      status: json['status'] ?? 'draft',
      processedAt: json['processed_at'] != null ? DateTime.parse(json['processed_at']) : null,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
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
      'staff_name': staffName,
      'employee_number': employeeNumber,
      'period_start': periodStart.toIso8601String().split('T').first,
      'period_end': periodEnd.toIso8601String().split('T').first,
      'regular_hours': regularHours,
      'overtime_hours': overtimeHours,
      'hourly_rate': hourlyRate,
      'overtime_rate': overtimeRate,
      'regular_pay': regularPay,
      'overtime_pay': overtimePay,
      'holiday_pay': holidayPay,
      'sick_pay': sickPay,
      'bonus_pay': bonusPay,
      'deductions': deductions,
      'tax_deducted': taxDeducted,
      'ni_deducted': niDeducted,
      'status': status,
      'processed_at': processedAt?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'notes': notes,
    };
  }

  String getStatusDisplay() {
    switch (status) {
      case 'draft': return 'Draft';
      case 'processed': return 'Processed';
      case 'paid': return 'Paid';
      case 'approved': return 'Approved';
      default: return status;
    }
  }

  double get netPay => grossPay - taxDeducted - niDeducted;
}