class LeaveRequest {
  final String id;
  final String? staffId;
  final String staffName;
  final String? employeeNumber;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final double totalDays;
  final String payRateType;
  final int payPercentage;
  final double? hourlyRate;
  final double? dailyRate;
  final String status;
  final String? requestedById;
  final DateTime? requestedAt;
  final String? approvedById;
  final DateTime? approvedAt;
  final String? rejectedReason;
  final bool payrollProcessed;
  final DateTime? payrollProcessedAt;
  final String? payrollNotes;
  final String? notes;
  final String? attachmentUrl;
  final String? organisationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeaveRequest({
    required this.id,
    this.staffId,
    required this.staffName,
    this.employeeNumber,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    this.totalDays = 1.0,
    this.payRateType = 'statutory',
    this.payPercentage = 100,
    this.hourlyRate,
    this.dailyRate,
    this.status = 'pending',
    this.requestedById,
    this.requestedAt,
    this.approvedById,
    this.approvedAt,
    this.rejectedReason,
    this.payrollProcessed = false,
    this.payrollProcessedAt,
    this.payrollNotes,
    this.notes,
    this.attachmentUrl,
    this.organisationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] ?? '',
      staffId: json['staff_id'],
      staffName: json['staff_name'] ?? '',
      employeeNumber: json['employee_number'],
      leaveType: json['leave_type'] ?? 'annual_holiday',
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : DateTime.now(),
      totalDays: (json['total_days'] ?? 1).toDouble(),
      payRateType: json['pay_rate_type'] ?? 'statutory',
      payPercentage: json['pay_percentage'] ?? 100,
      hourlyRate: json['hourly_rate']?.toDouble(),
      dailyRate: json['daily_rate']?.toDouble(),
      status: json['status'] ?? 'pending',
      requestedById: json['requested_by'],
      requestedAt: json['requested_at'] != null ? DateTime.parse(json['requested_at']) : null,
      approvedById: json['approved_by'],
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      rejectedReason: json['rejected_reason'],
      payrollProcessed: json['payroll_processed'] ?? false,
      payrollProcessedAt: json['payroll_processed_at'] != null ? DateTime.parse(json['payroll_processed_at']) : null,
      payrollNotes: json['payroll_notes'],
      notes: json['notes'],
      attachmentUrl: json['attachment_url'],
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
      'leave_type': leaveType,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'pay_rate_type': payRateType,
      'pay_percentage': payPercentage,
      'hourly_rate': hourlyRate,
      'daily_rate': dailyRate,
      'status': status,
      'requested_by': requestedById,
      'approved_by': approvedById,
      'approved_at': approvedAt?.toIso8601String(),
      'rejected_reason': rejectedReason,
      'payroll_processed': payrollProcessed,
      'payroll_processed_at': payrollProcessedAt?.toIso8601String(),
      'payroll_notes': payrollNotes,
      'notes': notes,
      'attachment_url': attachmentUrl,
      'organisation_id': organisationId,
    };
  }

  String getLeaveTypeDisplay() {
    switch (leaveType) {
      case 'annual_holiday': return 'Annual Holiday';
      case 'sick_leave': return 'Sick Leave';
      case 'compassionate_leave': return 'Compassionate Leave';
      case 'bereavement_leave': return 'Bereavement Leave';
      case 'maternity_leave': return 'Maternity Leave';
      case 'paternity_leave': return 'Paternity Leave';
      case 'adoption_leave': return 'Adoption Leave';
      case 'parental_leave': return 'Parental Leave';
      case 'carers_leave': return 'Carers Leave';
      case 'study_leave': return 'Study Leave';
      case 'emergency_leave': return 'Emergency Leave';
      case 'unpaid_leave': return 'Unpaid Leave';
      default: return leaveType;
    }
  }

  String getStatusDisplay() {
    switch (status) {
      case 'pending': return 'Pending';
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
      case 'cancelled': return 'Cancelled';
      case 'withdrawn': return 'Withdrawn';
      default: return status;
    }
  }
}