class CoshhRiskAssessment {
  final String? id;
  final String? serviceUserId;
  final String? assessorId;
  final DateTime assessmentDate;
  
  // Core substance information
  final String substanceName;
  final String typeOfHarm;
  final String description;
  final String howCausesHarm;
  final List<String> whoExposed;
  final String frequencyOfUse;
  final String purposeActivity;
  
  // Risk assessment decisions
  final bool canBeEliminated;
  final String? eliminationReason;
  
  // Control measures
  final Map<String, dynamic> controlMeasures;
  final Map<String, dynamic> emergencyProcedures;
  
  // Staff awareness and training
  final bool staffAware;
  final bool trainingRequired;
  final String? trainingDetails;
  
  // Final risk assessment
  final bool riskAcceptable;
  final String? riskLevel;
  final String? reconsiderControls;
  
  // Assessment metadata
  final String? signature;
  final String? assessorSignature;
  final DateTime? reviewDate;
  final String? reassessmentFrequency;
  final String? organisationId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  CoshhRiskAssessment({
    this.id,
    this.serviceUserId,
    this.assessorId,
    required this.assessmentDate,
    required this.substanceName,
    required this.typeOfHarm,
    required this.description,
    required this.howCausesHarm,
    required this.whoExposed,
    required this.frequencyOfUse,
    required this.purposeActivity,
    required this.canBeEliminated,
    this.eliminationReason,
    required this.controlMeasures,
    required this.emergencyProcedures,
    required this.staffAware,
    required this.trainingRequired,
    this.trainingDetails,
    required this.riskAcceptable,
    this.riskLevel,
    this.reconsiderControls,
    this.signature,
    this.assessorSignature,
    this.reviewDate,
    this.reassessmentFrequency,
    this.organisationId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    if (value is String) return DateTime.parse(value).toLocal();
    return null;
  }

  factory CoshhRiskAssessment.fromMap(Map<String, dynamic> map) {
    return CoshhRiskAssessment(
      id: map['id'],
      serviceUserId: map['service_user_id'],
      assessorId: map['assessor_id'],
      assessmentDate: _parseDate(map['assessment_date']) ?? DateTime.now(),
      substanceName: map['substance_name'] ?? '',
      typeOfHarm: map['type_of_harm'] ?? '',
      description: map['description'] ?? '',
      howCausesHarm: map['how_causes_harm'] ?? '',
      whoExposed: List<String>.from(map['who_exposed'] ?? []),
      frequencyOfUse: map['frequency_of_use'] ?? '',
      purposeActivity: map['purpose_activity'] ?? '',
      canBeEliminated: map['can_be_eliminated'] ?? false,
      eliminationReason: map['elimination_reason'],
      controlMeasures: map['control_measures'] ?? {},
      emergencyProcedures: map['emergency_procedures'] ?? {},
      staffAware: map['staff_aware'] ?? false,
      trainingRequired: map['training_required'] ?? false,
      trainingDetails: map['training_details'],
      riskAcceptable: map['risk_acceptable'] ?? false,
      riskLevel: map['risk_level'],
      reconsiderControls: map['reconsider_controls'],
      signature: map['signature'],
      assessorSignature: map['assessor_signature'],
      reviewDate: _parseDate(map['review_date']),
      reassessmentFrequency: map['reassessment_frequency'],
      organisationId: map['organisation_id'] as String?,
      status: map['status'] ?? 'draft',
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updated_at']) ?? DateTime.now(),
    );
  }

  String? _nullIfEmpty(String? value) {
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_user_id': _nullIfEmpty(serviceUserId),
      'assessor_id': _nullIfEmpty(assessorId),
      'assessment_date': assessmentDate.toIso8601String().split('T').first,
      'substance_name': substanceName,
      'type_of_harm': typeOfHarm,
      'description': description,
      'how_causes_harm': howCausesHarm,
      'who_exposed': whoExposed,
      'frequency_of_use': frequencyOfUse,
      'purpose_activity': purposeActivity,
      'can_be_eliminated': canBeEliminated,
      'elimination_reason': eliminationReason,
      'control_measures': controlMeasures,
      'emergency_procedures': emergencyProcedures,
      'staff_aware': staffAware,
      'training_required': trainingRequired,
      'training_details': trainingDetails,
      'risk_acceptable': riskAcceptable,
      'risk_level': riskLevel,
      'reconsider_controls': reconsiderControls,
      'assessor_signature': assessorSignature,
      'review_date': reviewDate?.toIso8601String().split('T').first,
      'reassessment_frequency': reassessmentFrequency,
      'organisation_id': organisationId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods for business logic
  String getRiskLevel() {
    if (riskLevel != null) {
      return riskLevel!;
    }
    
    // Calculate risk level based on assessment criteria
    int riskScore = 0;
    
    // Base risk score based on harm mechanism
    if (howCausesHarm.toLowerCase().contains('inhalation')) {
      riskScore += 3;
    } else if (howCausesHarm.toLowerCase().contains('ingestion') || 
               howCausesHarm.toLowerCase().contains('absorption')) {
      riskScore += 2;
    }
    
    // Frequency impact
    if (frequencyOfUse.toLowerCase().contains('daily')) {
      riskScore += 3;
    } else if (frequencyOfUse.toLowerCase().contains('weekly')) {
      riskScore += 2;
    } else if (frequencyOfUse.toLowerCase().contains('monthly')) {
      riskScore += 1;
    }
    
    // Elimination factor
    if (canBeEliminated) {
      riskScore -= 2;
    }
    
    // Final risk assessment
    if (riskAcceptable) {
      riskScore -= 1;
    }
    
    // Determine risk level
    if (riskScore <= 2) {
      return 'Low';
    } else if (riskScore <= 4) {
      return 'Medium';
    } else {
      return 'High';
    }
  }

  bool isTrainingRequired() {
    return !staffAware;
  }

  List<String> getWarnings() {
    List<String> warnings = [];
    
    if (!canBeEliminated && getRiskLevel() == 'High') {
      warnings.add('High risk substance that cannot be eliminated - consider alternative substances');
    }
    
    if (isTrainingRequired()) {
      warnings.add('Training required for staff');
    }
    
    if (!riskAcceptable) {
      warnings.add('Risk not acceptable - reconsider control measures');
    }
    
    return warnings;
  }

  bool isComplete() {
    return substanceName.isNotEmpty &&
           typeOfHarm.isNotEmpty &&
           description.isNotEmpty &&
           howCausesHarm.isNotEmpty &&
           frequencyOfUse.isNotEmpty &&
           purposeActivity.isNotEmpty &&
           canBeEliminated != null &&
           staffAware != null &&
           riskAcceptable != null;
  }

  // Database operations should be handled by CoshhRiskService
}