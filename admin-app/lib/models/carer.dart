class Carer {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? employeeNumber;
  final String? dbsNumber;
  final DateTime? dbsExpiryDate;
  final String? dbsCertificateUrl;
  final String? idDocumentUrl;
  final DateTime? idExpiryDate;
  final String? proofOfResidenceUrl;
  final DateTime? proofOfResidenceExpiry;
  final String? infectionControlUrl;
  final DateTime? infectionControlExpiry;
  final String? manualHandlingUrl;
  final DateTime? manualHandlingExpiry;
  final String? safeguardingUrl;
  final DateTime? safeguardingExpiry;
  final DateTime? fitnessToWorkExpiry;
  final String? sortCode;
  final String? accountNumber;
  final String? photoUrl;
  final DateTime? rightToWorkExpiry;
  final Map<String, dynamic>? trainingRecords;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dateOfBirth;
  final String? address;
  final String? organisationId;
  final String? jobRole;
  final String? staffType;
  final String? inviteStatus;

  Carer({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.employeeNumber,
    this.dbsNumber,
    this.dbsExpiryDate,
    this.dbsCertificateUrl,
    this.idDocumentUrl,
    this.idExpiryDate,
    this.proofOfResidenceUrl,
    this.proofOfResidenceExpiry,
    this.infectionControlUrl,
    this.infectionControlExpiry,
    this.manualHandlingUrl,
    this.manualHandlingExpiry,
    this.safeguardingUrl,
    this.safeguardingExpiry,
    this.fitnessToWorkExpiry,
    this.sortCode,
    this.accountNumber,
    this.photoUrl,
    this.rightToWorkExpiry,
    this.trainingRecords,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.dateOfBirth,
    this.address,
    this.organisationId,
    this.jobRole,
    this.staffType,
    this.inviteStatus,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
      'employee_number': employeeNumber,
      'dbs_number': dbsNumber,
      'dbs_expiry_date': dbsExpiryDate?.toIso8601String(),
      'dbs_certificate_url': dbsCertificateUrl,
      'id_document_url': idDocumentUrl,
      'id_expiry_date': idExpiryDate?.toIso8601String(),
      'proof_of_residence_url': proofOfResidenceUrl,
      'proof_of_residence_expiry': proofOfResidenceExpiry?.toIso8601String(),
      'infection_control_url': infectionControlUrl,
      'infection_control_expiry': infectionControlExpiry?.toIso8601String(),
      'manual_handling_url': manualHandlingUrl,
      'manual_handling_expiry': manualHandlingExpiry?.toIso8601String(),
      'safeguarding_url': safeguardingUrl,
      'safeguarding_expiry': safeguardingExpiry?.toIso8601String(),
      'fitness_to_work_expiry': fitnessToWorkExpiry?.toIso8601String(),
      'sort_code': sortCode,
      'account_number': accountNumber,
      'photo_url': photoUrl,
      'right_to_work_expiry': rightToWorkExpiry?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'address': address,
      'organisation_id': organisationId,
    };
    
    // CRITICAL: Only add ID if it has a value - NEVER add null
    if (id.isNotEmpty && id != 'null') {
      map['id'] = id;
    }
    
    return map;
  }

  factory Carer.fromMap(Map<String, dynamic> map) {
    return Carer(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      employeeNumber: map['employee_number'],
      dbsNumber: map['dbs_number'],
      dbsExpiryDate: _parseDateTime(map['dbs_expiry_date']),
      dbsCertificateUrl: map['dbs_certificate_url'],
      idDocumentUrl: map['id_document_url'],
      idExpiryDate: _parseDateTime(map['id_expiry_date']),
      proofOfResidenceUrl: map['proof_of_residence_url'],
      proofOfResidenceExpiry: _parseDateTime(map['proof_of_residence_expiry']),
      infectionControlUrl: map['infection_control_url'],
      infectionControlExpiry: _parseDateTime(map['infection_control_expiry']),
      manualHandlingUrl: map['manual_handling_url'],
      manualHandlingExpiry: _parseDateTime(map['manual_handling_expiry']),
      safeguardingUrl: map['safeguarding_url'],
      safeguardingExpiry: _parseDateTime(map['safeguarding_expiry']),
      fitnessToWorkExpiry: _parseDateTime(map['fitness_to_work_expiry']),
      sortCode: map['sort_code'],
      accountNumber: map['account_number'],
      photoUrl: map['photo_url'],
      rightToWorkExpiry: _parseDateTime(map['right_to_work_expiry']),
      trainingRecords: map['training_records'] as Map<String, dynamic>?,
      isActive: map['is_active'] ?? true,
      createdAt: _parseDateTime(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updated_at']) ?? DateTime.now(),
      dateOfBirth: _parseDateTime(map['date_of_birth']),
      address: map['address'],
      jobRole: map['job_role'],
      staffType: map['staff_type'],
      inviteStatus: map['invite_status'],
    );
  }

  /// Helper method to parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        // Handle PostgreSQL timestamp format: "2026-04-12 01:10:46.794354+00"
        // Remove the timezone offset part if present
        String cleaned = value.trim();
        if (cleaned.contains('+')) {
          cleaned = cleaned.split('+')[0];
        }
        if (cleaned.contains('-') && cleaned.contains(':') && !cleaned.contains('T')) {
          // Replace space with T for ISO format
          cleaned = cleaned.replaceAll(' ', 'T');
        }
        return DateTime.parse(cleaned);
      } catch (e) {
        print('Failed to parse date: $value, error: $e');
        return null;
      }
    }
    return null;
  }
}
