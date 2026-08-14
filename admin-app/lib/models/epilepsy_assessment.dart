import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase/supabase.dart';

class EpilepsyAssessment {
  final String? id;
  final String? serviceUserId;
  final String? assessorId;
  
  // Seizure Information
  final String seizureType;
  final String seizureFrequency;
  final String? seizureFrequencyDetails;
  final List<String>? seizureTriggers;
  final DateTime? lastSeizureDate;
  
  // Medication Information
  final String? medicationName;
  final String? medicationDose;
  final List<String>? medicationTimes;
  final bool medicationCompliance;
  
  // Seizure Characteristics
  final Duration? typicalDuration;
  final String? warningSigns;
  final Duration? recoveryTime;
  final String? postSeizureBehaviour;
  
  // Risk Assessment
  final List<String>? injuryRiskFactors;
  final bool safeguardingConcerns;
  final List<String>? unwitnessedSeizureLocations;
  
  // Emergency Protocol
  final String emergencyProtocol;
  final String? rescueMedicationName;
  final String? rescueMedicationDose;
  final bool rescueMedicationAdministered;
  final String? rescueMedicationResponse;
  
  // Assessment Metadata
  final String? overallRiskLevel;
  final List<String>? riskFactorsIdentified;
  final String? monitoringRequirements;
  final DateTime? nextReviewDate;
  
  // Status and Signatures
  final String? signature;
  final String status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  EpilepsyAssessment({
    this.id,
    this.serviceUserId,
    this.assessorId,
    required this.seizureType,
    required this.seizureFrequency,
    this.seizureFrequencyDetails,
    this.seizureTriggers,
    this.lastSeizureDate,
    this.medicationName,
    this.medicationDose,
    this.medicationTimes,
    required this.medicationCompliance,
    this.typicalDuration,
    this.warningSigns,
    this.recoveryTime,
    this.postSeizureBehaviour,
    this.injuryRiskFactors,
    required this.safeguardingConcerns,
    this.unwitnessedSeizureLocations,
    required this.emergencyProtocol,
    this.rescueMedicationName,
    this.rescueMedicationDose,
    required this.rescueMedicationAdministered,
    this.rescueMedicationResponse,
    this.overallRiskLevel,
    this.riskFactorsIdentified,
    this.monitoringRequirements,
    this.nextReviewDate,
    this.signature,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    if (value is String) return DateTime.parse(value).toLocal();
    return null;
  }

  factory EpilepsyAssessment.fromMap(Map<String, dynamic> map) {
    return EpilepsyAssessment(
      id: map['id'],
      serviceUserId: map['service_user_id'],
      assessorId: map['assessor_id'],
      seizureType: map['seizure_type'] ?? '',
      seizureFrequency: map['seizure_frequency'] ?? '',
      seizureFrequencyDetails: map['seizure_frequency_details'],
      seizureTriggers: (map['seizure_triggers'] as List?)?.cast<String>(),
      lastSeizureDate: _parseDate(map['last_seizure_date']),
      medicationName: map['medication_name'],
      medicationDose: map['medication_dose'],
      medicationTimes: (map['medication_times'] as List?)?.cast<String>(),
      medicationCompliance: map['medication_compliance'] ?? true,
      typicalDuration: map['typical_duration'] != null 
          ? Duration(seconds: map['typical_duration'].inSeconds) 
          : null,
      warningSigns: map['warning_signs'],
      recoveryTime: map['recovery_time'] != null 
          ? Duration(seconds: map['recovery_time'].inSeconds) 
          : null,
      postSeizureBehaviour: map['post_seizure_behaviour'],
      injuryRiskFactors: (map['injury_risk_factors'] as List?)?.cast<String>(),
      safeguardingConcerns: map['safeguarding_concerns'] ?? false,
      unwitnessedSeizureLocations: (map['unwitnessed_seizure_locations'] as List?)?.cast<String>(),
      emergencyProtocol: map['emergency_protocol'] ?? '',
      rescueMedicationName: map['rescue_medication_name'],
      rescueMedicationDose: map['rescue_medication_dose'],
      rescueMedicationAdministered: map['rescue_medication_administered'] ?? false,
      rescueMedicationResponse: map['rescue_medication_response'],
      overallRiskLevel: map['overall_risk_level'],
      riskFactorsIdentified: (map['risk_factors_identified'] as List?)?.cast<String>(),
      monitoringRequirements: map['monitoring_requirements'],
      nextReviewDate: _parseDate(map['next_review_date']),
      signature: map['signature'],
      status: map['status'] ?? 'draft',
      reviewedBy: map['reviewed_by'],
      reviewedAt: _parseDate(map['reviewed_at']),
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_user_id': serviceUserId,
      'assessor_id': assessorId,
      'seizure_type': seizureType,
      'seizure_frequency': seizureFrequency,
      'seizure_frequency_details': seizureFrequencyDetails,
      'seizure_triggers': seizureTriggers,
      'last_seizure_date': lastSeizureDate?.toIso8601String().split('T').first,
      'medication_name': medicationName,
      'medication_dose': medicationDose,
      'medication_times': medicationTimes,
      'medication_compliance': medicationCompliance,
      'typical_duration': typicalDuration?.inSeconds,
      'warning_signs': warningSigns,
      'recovery_time': recoveryTime?.inSeconds,
      'post_seizure_behaviour': postSeizureBehaviour,
      'injury_risk_factors': injuryRiskFactors,
      'safeguarding_concerns': safeguardingConcerns,
      'unwitnessed_seizure_locations': unwitnessedSeizureLocations,
      'emergency_protocol': emergencyProtocol,
      'rescue_medication_name': rescueMedicationName,
      'rescue_medication_dose': rescueMedicationDose,
      'rescue_medication_administered': rescueMedicationAdministered,
      'rescue_medication_response': rescueMedicationResponse,
      'overall_risk_level': overallRiskLevel,
      'risk_factors_identified': riskFactorsIdentified,
      'monitoring_requirements': monitoringRequirements,
      'next_review_date': nextReviewDate?.toIso8601String().split('T').first,
      'signature': signature,
      'status': status,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  // Helper methods for business logic
  String getSeizureFrequencyDisplay() {
    switch (seizureFrequency) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'rarely':
        return 'Rarely';
      case 'none':
        return 'None';
      default:
        return seizureFrequency;
    }
  }

  String getSeizureTypeDisplay() {
    switch (seizureType) {
      case 'tonic-clonic':
        return 'Tonic-Clonic';
      case 'absence':
        return 'Absence';
      case 'focal':
        return 'Focal';
      case 'atonic':
        return 'Atonic';
      case 'myoclonic':
        return 'Myoclonic';
      case 'unknown':
        return 'Unknown';
      default:
        return seizureType;
    }
  }

  bool isHighRisk() {
    return overallRiskLevel == 'high' || 
           seizureFrequency == 'daily' || 
           seizureFrequency == 'weekly' ||
           !medicationCompliance ||
           safeguardingConcerns;
  }

  bool isMedicationCompliant() {
    return medicationCompliance;
  }

  String getDaysSinceLastSeizure() {
    if (lastSeizureDate == null) {
      return 'Unknown';
    }
    
    int days = DateTime.now().difference(lastSeizureDate!).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return '1 day ago';
    return '$days days ago';
  }

  String getTypicalDurationDisplay() {
    if (typicalDuration == null) return 'Unknown';
    
    int minutes = typicalDuration!.inMinutes;
    int seconds = typicalDuration!.inSeconds % 60;
    
    if (minutes > 0) {
      return '${minutes}min ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String getRecoveryTimeDisplay() {
    if (recoveryTime == null) return 'Unknown';
    
    int minutes = recoveryTime!.inMinutes;
    int hours = recoveryTime!.inHours;
    
    if (hours > 0) {
      return '${hours} hours';
    } else if (minutes > 0) {
      return '${minutes} minutes';
    } else {
      return 'Less than 1 minute';
    }
  }

  List<String> getRiskFactors() {
    List<String> factors = [];
    
    if (!medicationCompliance) {
      factors.add('Medication non-compliance');
    }
    
    if (safeguardingConcerns) {
      factors.add('Safeguarding concerns');
    }
    
    if (injuryRiskFactors != null && injuryRiskFactors!.isNotEmpty) {
      factors.addAll(injuryRiskFactors!);
    }
    
    if (seizureFrequency == 'daily' || seizureFrequency == 'weekly') {
      factors.add('Frequent seizures');
    }
    
    return factors;
  }

  String getMonitoringRequirements() {
    if (monitoringRequirements != null && monitoringRequirements!.isNotEmpty) {
      return monitoringRequirements!;
    }
    
    // Default monitoring based on risk level
    if (overallRiskLevel == 'high') {
      return 'Continuous monitoring required';
    } else if (overallRiskLevel == 'medium') {
      return 'Regular monitoring every 2-4 hours';
    } else {
      return 'Standard monitoring as per care plan';
    }
  }

  bool needsReview() {
    if (nextReviewDate == null) return false;
    return nextReviewDate!.isBefore(DateTime.now());
  }

  String getSummary() {
    return 'Type: ${getSeizureTypeDisplay()} | Frequency: ${getSeizureFrequencyDisplay()} | Risk: ${overallRiskLevel?.toUpperCase() ?? 'Unknown'} | Compliance: ${isMedicationCompliant() ? 'Good' : 'Poor'}';
  }

  bool hasRescueMedication() {
    return rescueMedicationName != null && rescueMedicationName!.isNotEmpty;
  }

  String getRescueMedicationInfo() {
    if (!hasRescueMedication()) return 'No rescue medication';
    
    String info = '$rescueMedicationName';
    if (rescueMedicationDose != null) {
      info += ' (${rescueMedicationDose})';
    }
    return info;
  }

  List<String> getCommonTriggers() {
    return [
      'Stress',
      'Fatigue',
      'Lack of sleep',
      'Alcohol',
      'Missed medication',
      'Flashing lights',
      'Illness/fever',
      'Hormonal changes',
      'Dehydration',
      'Low blood sugar'
    ];
  }

  List<String> getCommonInjuryRisks() {
    return [
      'Falls',
      'Burns',
      'Drowning',
      'Head injury',
      'Broken bones',
      'Choking',
      'Traffic accidents'
    ];
  }

  String getEmergencyProtocolSummary() {
    if (emergencyProtocol != null && emergencyProtocol!.isNotEmpty) {
      return emergencyProtocol!;
    }
    return 'Call ambulance if seizure lasts >5 minutes or multiple seizures occur';
  }

  bool isComplete() {
    return seizureType.isNotEmpty &&
           seizureFrequency.isNotEmpty &&
           emergencyProtocol.isNotEmpty &&
           overallRiskLevel != null;
  }
}