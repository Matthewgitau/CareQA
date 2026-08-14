class McaAssessment {
  final String? id;
  final String serviceUserId;
  final String serviceUserName;
  final String? establishmentName;
  final String decisionType;
  final String? reasonForAssessment;
  final bool? q1Impairment;
  final String? q1Condition;
  final bool? q2aUnderstands;
  final String? q2aNotes;
  final bool? q2bRetains;
  final String? q2bNotes;
  final bool? q2cWeighs;
  final String? q2cNotes;
  final bool? q2dCommunicates;
  final String? q2dNotes;
  final DateTime assessmentDate;
  final String? assessmentTime;
  final String? howCompleted;
  final String? outcome;
  final bool hasFluctuatingCapacity;
  final DateTime? reassessmentDate;
  final String? assessorName;
  final String? assessorSignature;
  final String status;
  final DateTime? createdAt;

  McaAssessment({
    this.id,
    required this.serviceUserId,
    required this.serviceUserName,
    this.establishmentName,
    required this.decisionType,
    this.reasonForAssessment,
    this.q1Impairment,
    this.q1Condition,
    this.q2aUnderstands,
    this.q2aNotes,
    this.q2bRetains,
    this.q2bNotes,
    this.q2cWeighs,
    this.q2cNotes,
    this.q2dCommunicates,
    this.q2dNotes,
    required this.assessmentDate,
    this.assessmentTime,
    this.howCompleted,
    this.outcome,
    this.hasFluctuatingCapacity = false,
    this.reassessmentDate,
    this.assessorName,
    this.assessorSignature,
    this.status = 'draft',
    this.createdAt,
  });

  static const Map<String, String> decisionTypeLabels = {
    'personal_care': 'Personal Care',
    'communication': 'Communication',
    'continence': 'Continence',
    'medication_support': 'Medication Support',
    'mobility': 'Mobility',
    'nutrition': 'Nutrition',
    'skin_care': 'Skin Care',
  };

  static const Map<String, List<String>> decisionTypePrompts = {
    'personal_care': [
      'What support if any they need from staff to help them maintain a level of hygiene they are happy with?',
      'What support they need with taking a bath or shower?',
      'What the outcome may be if they were unable to meet their hygiene needs?',
      'What personal care options are available to them?',
    ],
    'communication': [
      'Any specific communication needs?',
      'The reason for use of any physical touch or aids/equipment?',
      'Any specific recommendations from other professionals regarding communication?',
      'Any assistance they might need with their communication and why?',
    ],
    'continence': [
      'The support if any they need from staff to maintain their hygiene?',
      'The support they need if any to get to the toilet?',
      'What help do they need from staff to get to the toilet?',
      'The risks of continued poor hygiene both to personal health and social relationships?',
      'What continence care options are available to them?',
    ],
    'medication_support': [
      'Whether they have any medication prescribed by their Doctor?',
      'In broad terms - what is the medication for?',
      'Whether they need any help from staff to manage their medication?',
      'The importance of taking the tablets as the Doctor instructed?',
      'Any side effects related to the prescribed medication?',
      'What the risks to them might be if they did not take their tablets?',
    ],
    'mobility': [
      'What their own level of mobility is now?',
      'What mobility aids they may require to move about safely?',
      'If they have any specific professional advice regarding mobility?',
      'Advice on safe levels of activity?',
      'What support they may need from staff to get from A to B?',
      'Any assistive technology in place?',
    ],
    'nutrition': [
      'Whether they have any specific dietary needs?',
      'Any professional advice they have had regarding nutrition?',
      'The importance of food and drink in relation to a happy and healthy life?',
      'Any professional instruction around SALT or dietician advice?',
      'Any assistance they might need with eating and drinking?',
    ],
    'skin_care': [
      'Any pre-existing conditions that may affect their skin?',
      'Any advice they have been given regarding how often they should change position?',
      'What support they require to help keep their skin in good condition?',
      'The use of barrier creams and repositioning aids?',
    ],
  };

  bool get lacksCapacity {
    if (q1Impairment != true) return false;
    return q2aUnderstands == false ||
        q2bRetains == false ||
        q2cWeighs == false ||
        q2dCommunicates == false;
  }

  String get decisionTypeLabel =>
      decisionTypeLabels[decisionType] ?? decisionType;

  factory McaAssessment.fromMap(Map<String, dynamic> map) {
    return McaAssessment(
      id: map['id'],
      serviceUserId: map['service_user_id'] ?? '',
      serviceUserName: map['service_user_name'] ?? '',
      establishmentName: map['establishment_name'],
      decisionType: map['decision_type'] ?? 'personal_care',
      reasonForAssessment: map['reason_for_assessment'],
      q1Impairment: map['q1_impairment'],
      q1Condition: map['q1_condition'],
      q2aUnderstands: map['q2a_understands'],
      q2aNotes: map['q2a_notes'],
      q2bRetains: map['q2b_retains'],
      q2bNotes: map['q2b_notes'],
      q2cWeighs: map['q2c_weighs'],
      q2cNotes: map['q2c_notes'],
      q2dCommunicates: map['q2d_communicates'],
      q2dNotes: map['q2d_notes'],
      assessmentDate: map['assessment_date'] != null
          ? DateTime.tryParse(map['assessment_date']) ?? DateTime.now()
          : DateTime.now(),
      assessmentTime: map['assessment_time'],
      howCompleted: map['how_completed'],
      outcome: map['outcome'],
      hasFluctuatingCapacity: map['has_fluctuating_capacity'] ?? false,
      reassessmentDate: map['reassessment_date'] != null
          ? DateTime.tryParse(map['reassessment_date'])
          : null,
      assessorName: map['assessor_name'],
      assessorSignature: map['assessor_signature'],
      status: map['status'] ?? 'draft',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'service_user_id': serviceUserId,
      'service_user_name': serviceUserName,
      'establishment_name': establishmentName,
      'decision_type': decisionType,
      'reason_for_assessment': reasonForAssessment,
      'q1_impairment': q1Impairment,
      'q1_condition': q1Condition,
      'q2a_understands': q2aUnderstands,
      'q2a_notes': q2aNotes,
      'q2b_retains': q2bRetains,
      'q2b_notes': q2bNotes,
      'q2c_weighs': q2cWeighs,
      'q2c_notes': q2cNotes,
      'q2d_communicates': q2dCommunicates,
      'q2d_notes': q2dNotes,
      'assessment_date': assessmentDate.toIso8601String().split('T').first,
      'assessment_time': assessmentTime,
      'how_completed': howCompleted,
      'outcome': outcome,
      'has_fluctuating_capacity': hasFluctuatingCapacity,
      'reassessment_date': reassessmentDate?.toIso8601String().split('T').first,
      'assessor_name': assessorName,
      'assessor_signature': assessorSignature,
      'status': status,
    };
  }
}