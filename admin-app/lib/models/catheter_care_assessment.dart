import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase/supabase.dart';

class CatheterCareAssessment {
  final String? id;
  final String? serviceUserId;
  final String? assessorId;
  final DateTime assessmentDate;
  
  // Catheter Information
  final String catheterType;
  final DateTime? insertionDate;
  final DateTime? nextChangeDate;
  final String? catheterSize;
  final String? balloonVolume;
  
  // Urine Monitoring
  final int? urineOutputMorning;
  final int? urineOutputAfternoon;
  final int? urineOutputNight;
  final String? urineAppearance;
  final String? urineAppearanceNotes;
  
  // Infection Monitoring
  final bool feverPresent;
  final bool painPresent;
  final bool urineOdourPresent;
  final String? infectionNotes;
  
  // Skin Condition
  final String? skinCondition;
  final String? skinConditionNotes;
  
  // Drainage System
  final bool bagPositionCorrect;
  final bool bagSecure;
  final bool tubingSecure;
  final String? drainageNotes;
  
  // Patient Comfort
  final int? painLevel;
  final int? comfortLevel;
  final String? patientComplaints;
  
  // Risk Assessment
  final bool infectionRisk;
  final bool blockageRisk;
  final bool dislodgementRisk;
  final bool skinBreakdownRisk;
  final String? overallRiskLevel;
  
  // Actions and Monitoring
  final bool actionsRequired;
  final String? actionsDetails;
  final String? monitoringFrequency;
  final DateTime? nextReviewDate;
  
  // Status and Signatures
  final String? signature;
  final String status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  CatheterCareAssessment({
    this.id,
    this.serviceUserId,
    this.assessorId,
    required this.assessmentDate,
    required this.catheterType,
    this.insertionDate,
    this.nextChangeDate,
    this.catheterSize,
    this.balloonVolume,
    this.urineOutputMorning,
    this.urineOutputAfternoon,
    this.urineOutputNight,
    this.urineAppearance,
    this.urineAppearanceNotes,
    required this.feverPresent,
    required this.painPresent,
    required this.urineOdourPresent,
    this.infectionNotes,
    this.skinCondition,
    this.skinConditionNotes,
    required this.bagPositionCorrect,
    required this.bagSecure,
    required this.tubingSecure,
    this.drainageNotes,
    this.painLevel,
    this.comfortLevel,
    this.patientComplaints,
    required this.infectionRisk,
    required this.blockageRisk,
    required this.dislodgementRisk,
    required this.skinBreakdownRisk,
    this.overallRiskLevel,
    required this.actionsRequired,
    this.actionsDetails,
    this.monitoringFrequency,
    this.nextReviewDate,
    this.signature,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CatheterCareAssessment.fromMap(Map<String, dynamic> map) {
    return CatheterCareAssessment(
      id: map['id'],
      serviceUserId: map['service_user_id'],
      assessorId: map['assessor_id'],
      assessmentDate: map['assessment_date']?.toLocal() ?? DateTime.now(),
      catheterType: map['catheter_type'] ?? '',
      insertionDate: map['insertion_date'],
      nextChangeDate: map['next_change_date'],
      catheterSize: map['catheter_size'],
      balloonVolume: map['balloon_volume'],
      urineOutputMorning: map['urine_output_morning'],
      urineOutputAfternoon: map['urine_output_afternoon'],
      urineOutputNight: map['urine_output_night'],
      urineAppearance: map['urine_appearance'],
      urineAppearanceNotes: map['urine_appearance_notes'],
      feverPresent: map['fever_present'] ?? false,
      painPresent: map['pain_present'] ?? false,
      urineOdourPresent: map['urine_odour_present'] ?? false,
      infectionNotes: map['infection_notes'],
      skinCondition: map['skin_condition'],
      skinConditionNotes: map['skin_condition_notes'],
      bagPositionCorrect: map['bag_position_correct'] ?? true,
      bagSecure: map['bag_secure'] ?? true,
      tubingSecure: map['tubing_secure'] ?? true,
      drainageNotes: map['drainage_notes'],
      painLevel: map['pain_level'],
      comfortLevel: map['comfort_level'],
      patientComplaints: map['patient_complaints'],
      infectionRisk: map['infection_risk'] ?? false,
      blockageRisk: map['blockage_risk'] ?? false,
      dislodgementRisk: map['dislodgement_risk'] ?? false,
      skinBreakdownRisk: map['skin_breakdown_risk'] ?? false,
      overallRiskLevel: map['overall_risk_level'],
      actionsRequired: map['actions_required'] ?? false,
      actionsDetails: map['actions_details'],
      monitoringFrequency: map['monitoring_frequency'],
      nextReviewDate: map['next_review_date'],
      signature: map['signature'],
      status: map['status'] ?? 'draft',
      reviewedBy: map['reviewed_by'],
      reviewedAt: map['reviewed_at']?.toLocal(),
      createdAt: map['created_at']?.toLocal() ?? DateTime.now(),
      updatedAt: map['updated_at']?.toLocal() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_user_id': serviceUserId,
      'assessor_id': assessorId,
      'assessment_date': assessmentDate.toUtc(),
      'catheter_type': catheterType,
      'insertion_date': insertionDate,
      'next_change_date': nextChangeDate,
      'catheter_size': catheterSize,
      'balloon_volume': balloonVolume,
      'urine_output_morning': urineOutputMorning,
      'urine_output_afternoon': urineOutputAfternoon,
      'urine_output_night': urineOutputNight,
      'urine_appearance': urineAppearance,
      'urine_appearance_notes': urineAppearanceNotes,
      'fever_present': feverPresent,
      'pain_present': painPresent,
      'urine_odour_present': urineOdourPresent,
      'infection_notes': infectionNotes,
      'skin_condition': skinCondition,
      'skin_condition_notes': skinConditionNotes,
      'bag_position_correct': bagPositionCorrect,
      'bag_secure': bagSecure,
      'tubing_secure': tubingSecure,
      'drainage_notes': drainageNotes,
      'pain_level': painLevel,
      'comfort_level': comfortLevel,
      'patient_complaints': patientComplaints,
      'infection_risk': infectionRisk,
      'blockage_risk': blockageRisk,
      'dislodgement_risk': dislodgementRisk,
      'skin_breakdown_risk': skinBreakdownRisk,
      'overall_risk_level': overallRiskLevel,
      'actions_required': actionsRequired,
      'actions_details': actionsDetails,
      'monitoring_frequency': monitoringFrequency,
      'next_review_date': nextReviewDate,
      'signature': signature,
      'status': status,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toUtc(),
      'created_at': createdAt.toUtc(),
      'updated_at': updatedAt.toUtc(),
    };
  }

  // Helper methods for business logic
  String getUrineOutputTotal() {
    int total = 0;
    if (urineOutputMorning != null) total += urineOutputMorning!;
    if (urineOutputAfternoon != null) total += urineOutputAfternoon!;
    if (urineOutputNight != null) total += urineOutputNight!;
    return total.toString();
  }

  bool hasInfectionSigns() {
    return feverPresent || painPresent || urineOdourPresent;
  }

  bool isCatheterChangeDue() {
    if (nextChangeDate == null) return false;
    return nextChangeDate!.isBefore(DateTime.now().add(Duration(days: 7)));
  }

  bool isCatheterChangeUrgent() {
    if (nextChangeDate == null) return false;
    return nextChangeDate!.isBefore(DateTime.now().add(Duration(days: 3)));
  }

  String getDaysUntilChange() {
    if (nextChangeDate == null) return 'Unknown';
    int days = nextChangeDate!.difference(DateTime.now()).inDays;
    if (days < 0) return 'Overdue by ${days.abs()} days';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days';
  }

  String getRiskLevel() {
    if (overallRiskLevel != null) {
      return overallRiskLevel!;
    }
    
    // Calculate risk level based on risk factors
    int riskScore = 0;
    
    if (infectionRisk) riskScore += 2;
    if (blockageRisk) riskScore += 2;
    if (dislodgementRisk) riskScore += 1;
    if (skinBreakdownRisk) riskScore += 1;
    if (hasInfectionSigns()) riskScore += 2;
    if (painLevel != null && painLevel! > 5) riskScore += 1;
    if (isCatheterChangeUrgent()) riskScore += 2;
    
    if (riskScore <= 2) {
      return 'low';
    } else if (riskScore <= 4) {
      return 'medium';
    } else {
      return 'high';
    }
  }

  List<String> getRiskFactors() {
    List<String> factors = [];
    
    if (infectionRisk) factors.add('Infection Risk');
    if (blockageRisk) factors.add('Blockage Risk');
    if (dislodgementRisk) factors.add('Dislodgement Risk');
    if (skinBreakdownRisk) factors.add('Skin Breakdown Risk');
    if (feverPresent) factors.add('Fever');
    if (painPresent) factors.add('Pain');
    if (urineOdourPresent) factors.add('Urine Odour');
    if (isCatheterChangeUrgent()) factors.add('Urgent Change Required');
    
    return factors;
  }

  List<String> getWarnings() {
    List<String> warnings = [];
    
    if (hasInfectionSigns()) {
      warnings.add('Infection signs detected - monitor closely and consider medical review');
    }
    
    if (isCatheterChangeUrgent()) {
      warnings.add('Catheter change required within 3 days - urgent action needed');
    } else if (isCatheterChangeDue()) {
      warnings.add('Catheter change due within 7 days - plan accordingly');
    }
    
    if (painLevel != null && painLevel! > 5) {
      warnings.add('High pain level (${painLevel}/10) - review pain management');
    }
    
    if (overallRiskLevel == 'high') {
      warnings.add('High overall risk - increased monitoring required');
    }
    
    if (!bagPositionCorrect) {
      warnings.add('Drainage bag position incorrect - review positioning');
    }
    
    if (!bagSecure || !tubingSecure) {
      warnings.add('Drainage system not secure - risk of dislodgement');
    }
    
    return warnings;
  }

  bool isComplete() {
    return catheterType.isNotEmpty &&
           insertionDate != null &&
           nextChangeDate != null &&
           catheterSize != null &&
           balloonVolume != null &&
           urineAppearance != null &&
           skinCondition != null &&
           painLevel != null &&
           comfortLevel != null;
  }

  String getMonitoringFrequency() {
    if (monitoringFrequency != null && monitoringFrequency!.isNotEmpty) {
      return monitoringFrequency!;
    }
    
    // Default monitoring frequency based on risk level
    String risk = getRiskLevel();
    if (risk == 'high') return '4 hourly';
    if (risk == 'medium') return '8 hourly';
    return '12 hourly';
  }

  String getSummary() {
    return 'Catheter: $catheterType | Risk: ${getRiskLevel().toUpperCase()} | Change: ${getDaysUntilChange()} | Output: ${getUrineOutputTotal()}ml';
  }
}