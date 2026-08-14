class Shift {
  final String id;
  final String serviceUserId;
  final String? carerId;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String status;

  Shift({
    required this.id,
    required this.serviceUserId,
    this.carerId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceUserId': serviceUserId,
      'carerId': carerId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
    };
  }

  factory Shift.fromMap(Map<String, dynamic> map, String id) {
    return Shift(
      id: id,
      serviceUserId: map['serviceUserId'] ?? '',
      carerId: map['carerId'],
      date: (map['date'] as DateTime?) ?? DateTime.now(),
      startTime: (map['startTime'] as DateTime?) ?? DateTime.now(),
      endTime: (map['endTime'] as DateTime?) ?? DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }
}