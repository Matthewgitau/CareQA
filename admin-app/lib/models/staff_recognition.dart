class StaffRecognition {
  final String id;
  final String? staffId;
  final String staffName;
  final String recognitionType;
  final DateTime recognitionDate;
  final String reason;
  final String? nominatedById;
  final String? nominatedByName;
  final String? awardDetails;
  final String? certificateUrl;
  final String? organisationId;
  final DateTime createdAt;

  StaffRecognition({
    required this.id,
    this.staffId,
    required this.staffName,
    required this.recognitionType,
    required this.recognitionDate,
    required this.reason,
    this.nominatedById,
    this.nominatedByName,
    this.awardDetails,
    this.certificateUrl,
    this.organisationId,
    required this.createdAt,
  });

  factory StaffRecognition.fromJson(Map<String, dynamic> json) {
    return StaffRecognition(
      id: json['id'] ?? '',
      staffId: json['staff_id'],
      staffName: json['staff_name'] ?? '',
      recognitionType: json['recognition_type'] ?? 'other',
      recognitionDate: json['recognition_date'] != null ? DateTime.parse(json['recognition_date']) : DateTime.now(),
      reason: json['reason'] ?? '',
      nominatedById: json['nominated_by'],
      nominatedByName: json['nominated_by_name'],
      awardDetails: json['award_details'],
      certificateUrl: json['certificate_url'],
      organisationId: json['organisation_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'staff_id': staffId,
      'staff_name': staffName,
      'recognition_type': recognitionType,
      'recognition_date': recognitionDate.toIso8601String().split('T').first,
      'reason': reason,
      'nominated_by': nominatedById,
      'nominated_by_name': nominatedByName,
      'award_details': awardDetails,
      'certificate_url': certificateUrl,
      'organisation_id': organisationId,
    };
  }

  String getRecognitionTypeDisplay() {
    switch (recognitionType) {
      case 'employee_of_month': return 'Employee of the Month';
      case 'employee_of_quarter': return 'Employee of the Quarter';
      case 'employee_of_year': return 'Employee of the Year';
      case 'spot_award': return 'Spot Award';
      case 'team_award': return 'Team Award';
      case 'long_service': return 'Long Service Award';
      case 'exceptional_care': return 'Exceptional Care Award';
      case 'innovation': return 'Innovation Award';
      case 'leadership': return 'Leadership Award';
      default: return recognitionType;
    }
  }
}