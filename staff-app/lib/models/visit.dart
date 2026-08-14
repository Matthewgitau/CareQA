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
      'id': id,
      'shiftId': shiftId,
      'carerId': carerId,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'notes': notes,
    };
  }

  factory Visit.fromMap(Map<String, dynamic> map, String id) {
    return Visit(
      id: id,
      shiftId: map['shiftId'] ?? '',
      carerId: map['carerId'] ?? '',
      checkInTime: map['checkInTime'] as DateTime?,
      checkOutTime: map['checkOutTime'] as DateTime?,
      notes: map['notes'] ?? '',
    );
  }
}