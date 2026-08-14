class Visit {
  final String id;
  final String shiftId;
  final String carerId;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String notes;

  Visit({
    required this.id,
    required this.shiftId,
    required this.carerId,
    this.checkInTime,
    this.checkOutTime,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'shift_id': shiftId,
      'carer_id': carerId,
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'notes': notes,
    };
  }

  factory Visit.fromMap(Map<String, dynamic> map) {
    return Visit(
      id: map['id'] ?? '',
      shiftId: map['shift_id'] ?? '',
      carerId: map['carer_id'] ?? '',
      checkInTime: map['check_in_time'] != null ? DateTime.tryParse(map['check_in_time']) : null,
      checkOutTime: map['check_out_time'] != null ? DateTime.tryParse(map['check_out_time']) : null,
      notes: map['notes'] ?? '',
    );
  }
}