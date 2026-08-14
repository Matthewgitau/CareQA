class Shift {
  final String id;
  final String serviceUserId;
  final String? carerId;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String? notes;

  Shift({
    required this.id,
    required this.serviceUserId,
    this.carerId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'service_user_id': serviceUserId,
      'carer_id': carerId,
      'date': date.toIso8601String(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'] ?? '',
      serviceUserId: map['service_user_id'] ?? '',
      carerId: map['carer_id'],
      date: map['date'] != null ? DateTime.tryParse(map['date']) ?? DateTime.now() : DateTime.now(),
      startTime: map['start_time'] != null ? DateTime.tryParse(map['start_time']) ?? DateTime.now() : DateTime.now(),
      endTime: map['end_time'] != null ? DateTime.tryParse(map['end_time']) ?? DateTime.now() : DateTime.now(),
      status: map['status'] ?? 'pending',
      notes: map['notes'],
    );
  }
}
