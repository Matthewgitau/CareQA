class Driver {
  final String id;
  final String? carerId;
  final bool isExclusiveDriver;
  final String staffName;
  final String? employeeId;
  final String? jobRole;
  final String? contactPhone;
  final DateTime? dateOfBirth;
  final String? licenseNumber;
  final DateTime? licenseExpiry;
  final String? licenseCategories;
  final DateTime? licenseIssueDate;
  final bool licenseChecked;
  final bool hasEndorsements;
  final String? endorsementDetails;
  final String? licenseCopyUrl;
  final bool isActive;
  final DateTime createdAt;

  Driver({
    required this.id,
    this.carerId,
    this.isExclusiveDriver = false,
    required this.staffName,
    this.employeeId,
    this.jobRole,
    this.contactPhone,
    this.dateOfBirth,
    this.licenseNumber,
    this.licenseExpiry,
    this.licenseCategories,
    this.licenseIssueDate,
    this.licenseChecked = false,
    this.hasEndorsements = false,
    this.endorsementDetails,
    this.licenseCopyUrl,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'is_exclusive_driver': isExclusiveDriver,
      'staff_name': staffName,
      'license_checked': licenseChecked,
      'has_endorsements': hasEndorsements,
      'is_active': isActive,
    };

    // Only include id if it's not empty (for updates)
    if (id.isNotEmpty) {
      map['id'] = id;
    }

    // Only include carer_id if it's not empty
    if (carerId != null && carerId!.isNotEmpty) {
      map['carer_id'] = carerId;
    }

    // Only include optional fields if they have values
    if (employeeId != null && employeeId!.isNotEmpty) {
      map['employee_id'] = employeeId;
    }
    if (jobRole != null && jobRole!.isNotEmpty) {
      map['job_role'] = jobRole;
    }
    if (contactPhone != null && contactPhone!.isNotEmpty) {
      map['contact_phone'] = contactPhone;
    }
    if (dateOfBirth != null) {
      map['date_of_birth'] = dateOfBirth!.toIso8601String();
    }
    if (licenseNumber != null && licenseNumber!.isNotEmpty) {
      map['license_number'] = licenseNumber;
    }
    if (licenseExpiry != null) {
      map['license_expiry'] = licenseExpiry!.toIso8601String();
    }
    if (licenseCategories != null && licenseCategories!.isNotEmpty) {
      map['license_categories'] = licenseCategories;
    }
    if (licenseIssueDate != null) {
      map['license_issue_date'] = licenseIssueDate!.toIso8601String();
    }
    if (endorsementDetails != null && endorsementDetails!.isNotEmpty) {
      map['endorsement_details'] = endorsementDetails;
    }
    if (licenseCopyUrl != null && licenseCopyUrl!.isNotEmpty) {
      map['license_copy_url'] = licenseCopyUrl;
    }

    return map;
  }

  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: map['id'] ?? '',
      carerId: map['carer_id'],
      isExclusiveDriver: map['is_exclusive_driver'] ?? false,
      staffName: map['staff_name'] ?? '',
      employeeId: map['employee_id'],
      jobRole: map['job_role'],
      contactPhone: map['contact_phone'],
      dateOfBirth: _parseDate(map['date_of_birth']),
      licenseNumber: map['license_number'],
      licenseExpiry: _parseDate(map['license_expiry']),
      licenseCategories: map['license_categories'],
      licenseIssueDate: _parseDate(map['license_issue_date']),
      licenseChecked: map['license_checked'] ?? false,
      hasEndorsements: map['has_endorsements'] ?? false,
      endorsementDetails: map['endorsement_details'],
      licenseCopyUrl: map['license_copy_url'],
      isActive: map['is_active'] ?? true,
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        String cleaned = value.trim();
        if (cleaned.contains('+')) cleaned = cleaned.split('+')[0];
        if (cleaned.contains('-') && cleaned.contains(':') && !cleaned.contains('T')) {
          cleaned = cleaned.replaceAll(' ', 'T');
        }
        return DateTime.parse(cleaned);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}