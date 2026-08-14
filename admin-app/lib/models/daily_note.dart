// Pure Dart model — no Flutter imports

class DailyNote {
  final String? id;
  final String? serviceUserId;
  final String? serviceUserName;
  final String? carerId;
  final String? carerName;
  final DateTime visitDate;
  final String visitTime;
  final String visitType; // morning, lunch, tea, evening
  final String careAccepted; // accepted, refused, partial
  final String? refusalReason;
  final List<String>? emotionalState;
  final bool padChanged;
  final bool padUrinePresent;
  final String? padUrineAmount;
  final bool padFaecesPresent;
  final String? padFaecesAmount;
  final String? stoolLogId;
  final bool foodOffered;
  final int? foodEatenPercentage;
  final String? foodDetails;
  final bool fluidOffered;
  final int? fluidMl;
  final String? fluidDetails;
  final bool medicationObserved;
  final bool medicationTaken;
  final bool medicationRefused;
  final String? medicationNotes;
  final String? skinCondition;
  final String? skinNotes;
  final String? mobilityNotes;
  final String? communicationNotes;
  final bool incidentOccurred;
  final String? incidentDescription;
  final String? incidentReportedTo;
  final String? manualNotes;
  final bool useManualNotes;
  final String? carerSignature;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyNote({
    this.id,
    this.serviceUserId,
    this.serviceUserName,
    this.carerId,
    this.carerName,
    required this.visitDate,
    required this.visitTime,
    required this.visitType,
    required this.careAccepted,
    this.refusalReason,
    this.emotionalState,
    this.padChanged = false,
    this.padUrinePresent = false,
    this.padUrineAmount,
    this.padFaecesPresent = false,
    this.padFaecesAmount,
    this.stoolLogId,
    this.foodOffered = false,
    this.foodEatenPercentage,
    this.foodDetails,
    this.fluidOffered = false,
    this.fluidMl,
    this.fluidDetails,
    this.medicationObserved = false,
    this.medicationTaken = false,
    this.medicationRefused = false,
    this.medicationNotes,
    this.skinCondition,
    this.skinNotes,
    this.mobilityNotes,
    this.communicationNotes,
    this.incidentOccurred = false,
    this.incidentDescription,
    this.incidentReportedTo,
    this.manualNotes,
    this.useManualNotes = false,
    this.carerSignature,
    this.status = 'draft',
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyNote.fromMap(Map<String, dynamic> map) {
    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value.toLocal();
      return DateTime.parse(value).toLocal();
    }

    return DailyNote(
      id: map['id'],
      serviceUserId: map['service_user_id'],
      serviceUserName: map['service_user_name'],
      carerId: map['carer_id'],
      carerName: map['carer_name'],
      visitDate: _parseDate(map['visit_date']),
      visitTime: map['visit_time'] as String? ?? '00:00:00',
      visitType: map['visit_type'] as String? ?? 'morning',
      careAccepted: map['care_accepted'] as String? ?? 'accepted',
      refusalReason: map['refusal_reason'],
      emotionalState: map['emotional_state'] != null ? List<String>.from(map['emotional_state']) : null,
      padChanged: map['pad_changed'] as bool? ?? false,
      padUrinePresent: map['pad_urine_present'] as bool? ?? false,
      padUrineAmount: map['pad_urine_amount'],
      padFaecesPresent: map['pad_faeces_present'] as bool? ?? false,
      padFaecesAmount: map['pad_faeces_amount'],
      stoolLogId: map['stool_log_id'],
      foodOffered: map['food_offered'] as bool? ?? false,
      foodEatenPercentage: map['food_eaten_percentage'],
      foodDetails: map['food_details'],
      fluidOffered: map['fluid_offered'] as bool? ?? false,
      fluidMl: map['fluid_ml'],
      fluidDetails: map['fluid_details'],
      medicationObserved: map['medication_observed'] as bool? ?? false,
      medicationTaken: map['medication_taken'] as bool? ?? false,
      medicationRefused: map['medication_refused'] as bool? ?? false,
      medicationNotes: map['medication_notes'],
      skinCondition: map['skin_condition'],
      skinNotes: map['skin_notes'],
      mobilityNotes: map['mobility_notes'],
      communicationNotes: map['communication_notes'],
      incidentOccurred: map['incident_occurred'] as bool? ?? false,
      incidentDescription: map['incident_description'],
      incidentReportedTo: map['incident_reported_to'],
      manualNotes: map['manual_notes'],
      useManualNotes: map['use_manual_notes'] as bool? ?? false,
      carerSignature: map['carer_signature'],
      status: map['status'] as String? ?? 'draft',
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'service_user_id': serviceUserId,
      'service_user_name': serviceUserName,
      'carer_id': carerId,
      'carer_name': carerName,
      'visit_date': visitDate.toIso8601String().split('T').first,
      'visit_time': visitTime,
      'visit_type': visitType,
      'care_accepted': careAccepted,
      'refusal_reason': refusalReason,
      'emotional_state': emotionalState,
      'pad_changed': padChanged,
      'pad_urine_present': padUrinePresent,
      'pad_urine_amount': padUrineAmount,
      'pad_faeces_present': padFaecesPresent,
      'pad_faeces_amount': padFaecesAmount,
      'stool_log_id': stoolLogId,
      'food_offered': foodOffered,
      'food_eaten_percentage': foodEatenPercentage,
      'food_details': foodDetails,
      'fluid_offered': fluidOffered,
      'fluid_ml': fluidMl,
      'fluid_details': fluidDetails,
      'medication_observed': medicationObserved,
      'medication_taken': medicationTaken,
      'medication_refused': medicationRefused,
      'medication_notes': medicationNotes,
      'skin_condition': skinCondition,
      'skin_notes': skinNotes,
      'mobility_notes': mobilityNotes,
      'communication_notes': communicationNotes,
      'incident_occurred': incidentOccurred,
      'incident_description': incidentDescription,
      'incident_reported_to': incidentReportedTo,
      'manual_notes': manualNotes,
      'use_manual_notes': useManualNotes,
      'carer_signature': carerSignature,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// Emotional state display helpers
class EmotionalStateHelper {
  static const Map<String, String> emojis = {
    'happy': '😊', 'sad': '😔', 'anxious': '😟', 'frustrated': '😤',
    'withdrawn': '🚶', 'agitated': '😠', 'calm': '😌', 'confused': '😕',
    'tired': '😴', 'in_pain': '😣',
  };
  static const Map<String, String> labels = {
    'happy': 'Happy', 'sad': 'Sad', 'anxious': 'Anxious', 'frustrated': 'Frustrated',
    'withdrawn': 'Withdrawn', 'agitated': 'Agitated', 'calm': 'Calm', 'confused': 'Confused',
    'tired': 'Tired', 'in_pain': 'In Pain',
  };
}