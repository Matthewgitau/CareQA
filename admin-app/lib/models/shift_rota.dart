class ShiftRota {
  final String id;
  final String serviceUserId;
  final String? carerId;
  final String? carerName;
  final DateTime startDate;
  final DateTime endDate;
  final String shiftType; // Morning, Lunch, Tea, Evening
  final String dayOfWeek; // Monday, Tuesday, etc.
  final String weekRange; // w/c 10 Mar 2026
  final String notes;
  final bool isRecurring;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String status; // Scheduled, Completed, Cancelled, Swapped, Confirmed, Booked

  ShiftRota({
    required this.id,
    required this.serviceUserId,
    this.carerId,
    this.carerName,
    required this.startDate,
    required this.endDate,
    required this.shiftType,
    required this.dayOfWeek,
    required this.weekRange,
    required this.notes,
    required this.isRecurring,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.status,
  });

  factory ShiftRota.fromMap(Map<String, dynamic> map) {
    return ShiftRota(
      id: map['id'] ?? '',
      serviceUserId: map['service_user_id'] ?? '',
      carerId: map['carer_id'],
      carerName: map['carer_name'],
      startDate: map['start_date'] != null
          ? DateTime.tryParse(map['start_date']) ?? DateTime.now()
          : DateTime.now(),
      endDate: map['end_date'] != null
          ? DateTime.tryParse(map['end_date']) ?? DateTime.now()
          : DateTime.now(),
      shiftType: map['shift_type'] ?? '',
      dayOfWeek: map['day_of_week'] ?? '',
      weekRange: map['week_range'] ?? '',
      notes: map['notes'] ?? '',
      isRecurring: map['is_recurring'] ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at']) ?? DateTime.now()
          : DateTime.now(),
      createdBy: map['created_by'] ?? '',
      status: map['status'] ?? 'Scheduled',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'service_user_id': serviceUserId,
      'carer_id': carerId,
      'carer_name': carerName,
      'start_date': startDate,
      'end_date': endDate,
      'shift_type': shiftType,
      'day_of_week': dayOfWeek,
      'week_range': weekRange,
      'notes': notes,
      'is_recurring': isRecurring,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'created_by': createdBy,
      'status': status,
    };
  }

  ShiftRota copyWith({
    String? id,
    String? serviceUserId,
    String? carerId,
    DateTime? startDate,
    DateTime? endDate,
    String? shiftType,
    String? dayOfWeek,
    String? weekRange,
    String? notes,
    bool? isRecurring,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? status,
  }) {
    return ShiftRota(
      id: id ?? this.id,
      serviceUserId: serviceUserId ?? this.serviceUserId,
      carerId: carerId ?? this.carerId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      shiftType: shiftType ?? this.shiftType,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      weekRange: weekRange ?? this.weekRange,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
    );
  }
}