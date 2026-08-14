class SatisfactionTrend {
  final String id;
  final String? organisationId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String? periodLabel;
  final double? avgOverallSatisfaction;
  final double? avgEngagementScore;
  final double? avgManagementSupport;
  final double? avgWorkEnvironment;
  final double? avgCareerDevelopment;
  final int? totalSurveysSent;
  final int? totalSurveysCompleted;
  final double? responseRate;
  final List<String> topStrengths;
  final List<String> topAreasForImprovement;
  final DateTime createdAt;

  SatisfactionTrend({
    required this.id,
    this.organisationId,
    required this.periodStart,
    required this.periodEnd,
    this.periodLabel,
    this.avgOverallSatisfaction,
    this.avgEngagementScore,
    this.avgManagementSupport,
    this.avgWorkEnvironment,
    this.avgCareerDevelopment,
    this.totalSurveysSent,
    this.totalSurveysCompleted,
    this.responseRate,
    this.topStrengths = const [],
    this.topAreasForImprovement = const [],
    required this.createdAt,
  });

  factory SatisfactionTrend.fromJson(Map<String, dynamic> json) {
    return SatisfactionTrend(
      id: json['id'] ?? '',
      organisationId: json['organisation_id'],
      periodStart: json['period_start'] != null ? DateTime.parse(json['period_start']) : DateTime.now(),
      periodEnd: json['period_end'] != null ? DateTime.parse(json['period_end']) : DateTime.now(),
      periodLabel: json['period_label'],
      avgOverallSatisfaction: json['avg_overall_satisfaction']?.toDouble(),
      avgEngagementScore: json['avg_engagement_score']?.toDouble(),
      avgManagementSupport: json['avg_management_support']?.toDouble(),
      avgWorkEnvironment: json['avg_work_environment']?.toDouble(),
      avgCareerDevelopment: json['avg_career_development']?.toDouble(),
      totalSurveysSent: json['total_surveys_sent'],
      totalSurveysCompleted: json['total_surveys_completed'],
      responseRate: json['response_rate']?.toDouble(),
      topStrengths: json['top_strengths'] != null ? List<String>.from(json['top_strengths']) : [],
      topAreasForImprovement: json['top_areas_for_improvement'] != null ? List<String>.from(json['top_areas_for_improvement']) : [],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'organisation_id': organisationId,
      'period_start': periodStart.toIso8601String().split('T').first,
      'period_end': periodEnd.toIso8601String().split('T').first,
      'period_label': periodLabel,
      'avg_overall_satisfaction': avgOverallSatisfaction,
      'avg_engagement_score': avgEngagementScore,
      'avg_management_support': avgManagementSupport,
      'avg_work_environment': avgWorkEnvironment,
      'avg_career_development': avgCareerDevelopment,
      'total_surveys_sent': totalSurveysSent,
      'total_surveys_completed': totalSurveysCompleted,
      'response_rate': responseRate,
      'top_strengths': topStrengths,
      'top_areas_for_improvement': topAreasForImprovement,
    };
  }

  String getTrendStatus() {
    if (avgOverallSatisfaction == null) return 'No data';
    if (avgOverallSatisfaction! >= 8) return 'Excellent';
    if (avgOverallSatisfaction! >= 6) return 'Good';
    if (avgOverallSatisfaction! >= 4) return 'Fair';
    return 'Needs Improvement';
  }

  int getTrendColorValue() {
    if (avgOverallSatisfaction == null) return 0xFF9E9E9E; // grey
    if (avgOverallSatisfaction! >= 8) return 0xFF4CAF50; // green
    if (avgOverallSatisfaction! >= 6) return 0xFF8BC34A; // light green
    if (avgOverallSatisfaction! >= 4) return 0xFFFF9800; // orange
    return 0xFFF44336; // red
  }
}