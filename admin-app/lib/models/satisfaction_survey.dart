class SatisfactionSurvey {
  final String id;
  final String? staffId;
  final String? staffName;
  final String? employeeNumber;
  final String? department;
  final String? jobRole;
  final DateTime surveyDate;
  final String surveyType;
  final int? overallSatisfaction;
  final int? engagementScore;
  final int? motivationScore;
  final int? workEnvironmentScore;
  final int? teamCollaborationScore;
  final int? resourcesAvailableScore;
  final int? managementSupportScore;
  final int? leadershipTrustScore;
  final int? communicationScore;
  final int? feedbackEffectivenessScore;
  final int? careerDevelopmentScore;
  final int? trainingOpportunitiesScore;
  final int? recognitionScore;
  final int? workLifeBalanceScore;
  final int? flexibilityScore;
  final String? whatDoYouEnjoy;
  final String? whatCouldImprove;
  final String? suggestionsForImprovement;
  final String? additionalComments;
  final String? topDriver;
  final String? topConcern;
  final bool? feelValued;
  final bool? feelHeard;
  final bool? feelSupported;
  final bool? feelDeveloped;
  final bool? feelRecognized;
  final bool isAnonymous;
  final int? responseTimeSeconds;
  final String completionStatus;
  final bool hrReviewed;
  final DateTime? hrReviewDate;
  final String? hrNotes;
  final String? actionPlan;
  final DateTime? actionDeadline;
  final String? actionOwner;
  final bool actionCompleted;
  final String? organisationId;
  final String? createdById;
  final DateTime createdAt;
  final DateTime updatedAt;

  SatisfactionSurvey({
    required this.id,
    this.staffId,
    this.staffName,
    this.employeeNumber,
    this.department,
    this.jobRole,
    required this.surveyDate,
    this.surveyType = 'standard',
    this.overallSatisfaction,
    this.engagementScore,
    this.motivationScore,
    this.workEnvironmentScore,
    this.teamCollaborationScore,
    this.resourcesAvailableScore,
    this.managementSupportScore,
    this.leadershipTrustScore,
    this.communicationScore,
    this.feedbackEffectivenessScore,
    this.careerDevelopmentScore,
    this.trainingOpportunitiesScore,
    this.recognitionScore,
    this.workLifeBalanceScore,
    this.flexibilityScore,
    this.whatDoYouEnjoy,
    this.whatCouldImprove,
    this.suggestionsForImprovement,
    this.additionalComments,
    this.topDriver,
    this.topConcern,
    this.feelValued,
    this.feelHeard,
    this.feelSupported,
    this.feelDeveloped,
    this.feelRecognized,
    this.isAnonymous = false,
    this.responseTimeSeconds,
    this.completionStatus = 'completed',
    this.hrReviewed = false,
    this.hrReviewDate,
    this.hrNotes,
    this.actionPlan,
    this.actionDeadline,
    this.actionOwner,
    this.actionCompleted = false,
    this.organisationId,
    this.createdById,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SatisfactionSurvey.fromJson(Map<String, dynamic> json) {
    return SatisfactionSurvey(
      id: json['id'] ?? '',
      staffId: json['staff_id'],
      staffName: json['staff_name'],
      employeeNumber: json['employee_number'],
      department: json['department'],
      jobRole: json['job_role'],
      surveyDate: json['survey_date'] != null ? DateTime.parse(json['survey_date']) : DateTime.now(),
      surveyType: json['survey_type'] ?? 'standard',
      overallSatisfaction: json['overall_satisfaction'],
      engagementScore: json['engagement_score'],
      motivationScore: json['motivation_score'],
      workEnvironmentScore: json['work_environment_score'],
      teamCollaborationScore: json['team_collaboration_score'],
      resourcesAvailableScore: json['resources_available_score'],
      managementSupportScore: json['management_support_score'],
      leadershipTrustScore: json['leadership_trust_score'],
      communicationScore: json['communication_score'],
      feedbackEffectivenessScore: json['feedback_effectiveness_score'],
      careerDevelopmentScore: json['career_development_score'],
      trainingOpportunitiesScore: json['training_opportunities_score'],
      recognitionScore: json['recognition_score'],
      workLifeBalanceScore: json['work_life_balance_score'],
      flexibilityScore: json['flexibility_score'],
      whatDoYouEnjoy: json['what_do_you_enjoy'],
      whatCouldImprove: json['what_could_improve'],
      suggestionsForImprovement: json['suggestions_for_improvement'],
      additionalComments: json['additional_comments'],
      topDriver: json['top_driver'],
      topConcern: json['top_concern'],
      feelValued: json['feel_valued'],
      feelHeard: json['feel_heard'],
      feelSupported: json['feel_supported'],
      feelDeveloped: json['feel_developed'],
      feelRecognized: json['feel_recognized'],
      isAnonymous: json['is_anonymous'] ?? false,
      responseTimeSeconds: json['response_time_seconds'],
      completionStatus: json['completion_status'] ?? 'completed',
      hrReviewed: json['hr_reviewed'] ?? false,
      hrReviewDate: json['hr_review_date'] != null ? DateTime.parse(json['hr_review_date']) : null,
      hrNotes: json['hr_notes'],
      actionPlan: json['action_plan'],
      actionDeadline: json['action_deadline'] != null ? DateTime.parse(json['action_deadline']) : null,
      actionOwner: json['action_owner'],
      actionCompleted: json['action_completed'] ?? false,
      organisationId: json['organisation_id'],
      createdById: json['created_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'staff_id': staffId,
      'staff_name': staffName,
      'employee_number': employeeNumber,
      'department': department,
      'job_role': jobRole,
      'survey_date': surveyDate.toIso8601String().split('T').first,
      'survey_type': surveyType,
      'overall_satisfaction': overallSatisfaction,
      'engagement_score': engagementScore,
      'motivation_score': motivationScore,
      'work_environment_score': workEnvironmentScore,
      'team_collaboration_score': teamCollaborationScore,
      'resources_available_score': resourcesAvailableScore,
      'management_support_score': managementSupportScore,
      'leadership_trust_score': leadershipTrustScore,
      'communication_score': communicationScore,
      'feedback_effectiveness_score': feedbackEffectivenessScore,
      'career_development_score': careerDevelopmentScore,
      'training_opportunities_score': trainingOpportunitiesScore,
      'recognition_score': recognitionScore,
      'work_life_balance_score': workLifeBalanceScore,
      'flexibility_score': flexibilityScore,
      'what_do_you_enjoy': whatDoYouEnjoy,
      'what_could_improve': whatCouldImprove,
      'suggestions_for_improvement': suggestionsForImprovement,
      'additional_comments': additionalComments,
      'top_driver': topDriver,
      'top_concern': topConcern,
      'feel_valued': feelValued,
      'feel_heard': feelHeard,
      'feel_supported': feelSupported,
      'feel_developed': feelDeveloped,
      'feel_recognized': feelRecognized,
      'is_anonymous': isAnonymous,
      'response_time_seconds': responseTimeSeconds,
      'completion_status': completionStatus,
      'hr_reviewed': hrReviewed,
      'hr_review_date': hrReviewDate?.toIso8601String().split('T').first,
      'hr_notes': hrNotes,
      'action_plan': actionPlan,
      'action_deadline': actionDeadline?.toIso8601String().split('T').first,
      'action_owner': actionOwner,
      'action_completed': actionCompleted,
      'organisation_id': organisationId,
      'created_by': createdById,
    };
  }

  String getSurveyTypeDisplay() {
    switch (surveyType) {
      case 'standard': return 'Standard Survey';
      case 'quarterly': return 'Quarterly Survey';
      case 'annual': return 'Annual Survey';
      case 'pulse': return 'Pulse Survey';
      case 'exit': return 'Exit Survey';
      case 'onboarding': return 'Onboarding Survey';
      case 'project_feedback': return 'Project Feedback';
      default: return surveyType;
    }
  }

  String getSatisfactionStatus() {
    if (overallSatisfaction == null) return 'Not assessed';
    if (overallSatisfaction! >= 8) return 'Highly Satisfied';
    if (overallSatisfaction! >= 5) return 'Moderately Satisfied';
    return 'Needs Attention';
  }

  int getSatisfactionColorValue() {
    if (overallSatisfaction == null) return 0xFF9E9E9E; // grey
    if (overallSatisfaction! >= 8) return 0xFF4CAF50; // green
    if (overallSatisfaction! >= 5) return 0xFFFF9800; // orange
    return 0xFFF44336; // red
  }

  double getAverageScore() {
    final scores = <int?>[
      overallSatisfaction,
      engagementScore,
      motivationScore,
      workEnvironmentScore,
      teamCollaborationScore,
      resourcesAvailableScore,
      managementSupportScore,
      leadershipTrustScore,
      communicationScore,
      feedbackEffectivenessScore,
      careerDevelopmentScore,
      trainingOpportunitiesScore,
      recognitionScore,
      workLifeBalanceScore,
      flexibilityScore,
    ];
    final validScores = scores.where((s) => s != null).cast<int>().toList();
    if (validScores.isEmpty) return 0;
    return validScores.reduce((a, b) => a + b) / validScores.length;
  }
}