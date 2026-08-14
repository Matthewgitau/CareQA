/// Represents a carer's training record
class CarerTrainingRecord {
  final String id;
  final String carerId;
  final String? carerName;
  final String trainingCourseId;
  final String? courseName;
  final DateTime completedDate;
  final DateTime? expiryDate;
  final String? certificateUrl;
  final String status; // 'active', 'expired', 'revoked'
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  CarerTrainingRecord({
    required this.id,
    required this.carerId,
    this.carerName,
    required this.trainingCourseId,
    this.courseName,
    required this.completedDate,
    this.expiryDate,
    this.certificateUrl,
    this.status = 'active',
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CarerTrainingRecord.fromJson(Map<String, dynamic> json) {
    return CarerTrainingRecord(
      id: json['id'] ?? '',
      carerId: json['carer_id'] ?? '',
      carerName: json['carer_name'],
      trainingCourseId: json['training_course_id'] ?? '',
      courseName: json['course_name'],
      completedDate: json['completed_date'] != null
          ? DateTime.parse(json['completed_date'])
          : DateTime.now(),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : null,
      certificateUrl: json['certificate_url'],
      status: json['status'] ?? 'active',
      notes: json['notes'],
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'carer_id': carerId,
      'training_course_id': trainingCourseId,
      'completed_date': completedDate.toIso8601String().split('T').first,
      'expiry_date': expiryDate?.toIso8601String().split('T').first,
      'certificate_url': certificateUrl,
      'status': status,
      'notes': notes,
      'created_by': createdBy,
    };
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  }

  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  CarerTrainingRecord copyWith({
    String? id,
    String? carerId,
    String? carerName,
    String? trainingCourseId,
    String? courseName,
    DateTime? completedDate,
    DateTime? expiryDate,
    String? certificateUrl,
    String? status,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CarerTrainingRecord(
      id: id ?? this.id,
      carerId: carerId ?? this.carerId,
      carerName: carerName ?? this.carerName,
      trainingCourseId: trainingCourseId ?? this.trainingCourseId,
      courseName: courseName ?? this.courseName,
      completedDate: completedDate ?? this.completedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      certificateUrl: certificateUrl ?? this.certificateUrl,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}