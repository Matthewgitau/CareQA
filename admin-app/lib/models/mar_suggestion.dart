// Pure Dart model — no Flutter imports

class MarSuggestion {
  final String? id;
  final String? originalMedicationId;
  final String? serviceUserId;
  final String? serviceUserName;

  // Suggested changes
  final String suggestionType; // 'create', 'update', 'delete', 'stop'

  // Suggested medication fields
  final String? medicationName;
  final String? dosage;
  final String? dosageUnit;
  final String? strength;
  final String? form;
  final String? frequency;
  final List<String>? frequencyTimes;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isOngoing;
  final String? specialInstructions;
  final String? administrationRoute;

  // Suggestion metadata
  final String? suggestedBy;
  final String? suggestedByName;
  final DateTime? suggestedAt;
  final String? suggestionReason;

  // Status
  final String status; // 'pending', 'approved', 'rejected'
  final String? reviewedBy;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final String? approvedActionId;

  final String? organisationId;

  MarSuggestion({
    this.id,
    this.originalMedicationId,
    this.serviceUserId,
    this.serviceUserName,
    required this.suggestionType,
    this.medicationName,
    this.dosage,
    this.dosageUnit,
    this.strength,
    this.form,
    this.frequency,
    this.frequencyTimes,
    this.startDate,
    this.endDate,
    this.isOngoing,
    this.specialInstructions,
    this.administrationRoute,
    this.suggestedBy,
    this.suggestedByName,
    this.suggestedAt,
    this.suggestionReason,
    this.status = 'pending',
    this.reviewedBy,
    this.reviewedByName,
    this.reviewedAt,
    this.reviewNotes,
    this.approvedActionId,
    this.organisationId,
  });

  factory MarSuggestion.fromMap(Map<String, dynamic> map) {
    DateTime? _parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value.toLocal();
      return DateTime.tryParse(value.toString())?.toLocal();
    }

    return MarSuggestion(
      id: map['id'],
      originalMedicationId: map['original_medication_id'],
      serviceUserId: map['service_user_id'],
      serviceUserName: map['service_user_name'],
      suggestionType: map['suggestion_type'] as String? ?? 'create',
      medicationName: map['medication_name'],
      dosage: map['dosage'],
      dosageUnit: map['dosage_unit'],
      strength: map['strength'],
      form: map['form'],
      frequency: map['frequency'],
      frequencyTimes: map['frequency_times'] != null
          ? List<String>.from(map['frequency_times'])
          : null,
      startDate: _parseNullableDate(map['start_date']),
      endDate: _parseNullableDate(map['end_date']),
      isOngoing: map['is_ongoing'] as bool?,
      specialInstructions: map['special_instructions'],
      administrationRoute: map['administration_route'],
      suggestedBy: map['suggested_by'],
      suggestedByName: map['suggested_by_name'],
      suggestedAt: _parseNullableDate(map['suggested_at']),
      suggestionReason: map['suggestion_reason'],
      status: map['status'] as String? ?? 'pending',
      reviewedBy: map['reviewed_by'],
      reviewedByName: map['reviewed_by_name'],
      reviewedAt: _parseNullableDate(map['reviewed_at']),
      reviewNotes: map['review_notes'],
      approvedActionId: map['approved_action_id'],
      organisationId: map['organisation_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'original_medication_id': originalMedicationId,
      'service_user_id': serviceUserId,
      'service_user_name': serviceUserName,
      'suggestion_type': suggestionType,
      'medication_name': medicationName,
      'dosage': dosage,
      'dosage_unit': dosageUnit,
      'strength': strength,
      'form': form,
      'frequency': frequency,
      'frequency_times': frequencyTimes,
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'is_ongoing': isOngoing,
      'special_instructions': specialInstructions,
      'administration_route': administrationRoute,
      'suggested_by': suggestedBy,
      'suggested_by_name': suggestedByName,
      'suggested_at': suggestedAt?.toIso8601String(),
      'suggestion_reason': suggestionReason,
      'status': status,
      'reviewed_by': reviewedBy,
      'reviewed_by_name': reviewedByName,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'review_notes': reviewNotes,
      'approved_action_id': approvedActionId,
      'organisation_id': organisationId,
    };
  }

  /// Get display-friendly suggestion type label
  String get suggestionTypeLabel {
    switch (suggestionType) {
      case 'create':
        return 'New Medication';
      case 'update':
        return 'Change Details';
      case 'delete':
        return 'Remove Medication';
      case 'stop':
        return 'Stop Medication';
      default:
        return suggestionType;
    }
  }

  /// Get icon for suggestion type
  String get suggestionTypeIcon {
    switch (suggestionType) {
      case 'create':
        return '➕';
      case 'update':
        return '✏️';
      case 'delete':
        return '🗑️';
      case 'stop':
        return '⏹️';
      default:
        return '📋';
    }
  }

  /// Get status label
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }
}

/// Helper class for suggestion type options
class SuggestionTypeHelper {
  static const Map<String, String> labels = {
    'create': 'New Medication',
    'update': 'Change Details',
    'delete': 'Remove Medication',
    'stop': 'Stop Medication',
  };

  static const List<String> values = [
    'create',
    'update',
    'delete',
    'stop',
  ];
}
