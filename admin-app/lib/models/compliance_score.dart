
class ComplianceScore {
  final String id;
  final String carerId;
  final String? careHomeId;
  final DateTime scoreDate;
  final double? overallScore;
  final double? durationCompliance;
  final double? documentationCompliance;
  final double? medicationCompliance;
  final double? incidentReportingCompliance;
  final int? flagsCount;
  final DateTime createdAt;

  /// Per-category scores (16 categories) keyed by slug, e.g. "mar_audit": 85.0
  final Map<String, double> categoryScores;

  ComplianceScore({
    required this.id,
    required this.carerId,
    this.careHomeId,
    required this.scoreDate,
    this.overallScore,
    this.durationCompliance,
    this.documentationCompliance,
    this.medicationCompliance,
    this.incidentReportingCompliance,
    this.flagsCount,
    required this.createdAt,
    this.categoryScores = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'carer_id': carerId,
      'care_home_id': careHomeId,
      'score_date': scoreDate,
      'overall_score': overallScore,
      'duration_compliance': durationCompliance,
      'documentation_compliance': documentationCompliance,
      'medication_compliance': medicationCompliance,
      'incident_reporting_compliance': incidentReportingCompliance,
      'flags_count': flagsCount,
      'created_at': createdAt,
      'category_scores': categoryScores,
    };
  }

  factory ComplianceScore.fromMap(Map<String, dynamic> map) {
    // Parse category_scores – may come as a JSONB map or a Dart Map
    Map<String, double> parsedCategories = {};
    final raw = map['category_scores'];
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is num) {
          parsedCategories[key.toString()] = value.toDouble();
        }
      });
    }

    return ComplianceScore(
      id: map['id'] ?? '',
      carerId: map['carer_id'] ?? '',
      careHomeId: map['care_home_id'],
      scoreDate: _parseDate(map['score_date']) ?? DateTime.now(),
      overallScore: (map['overall_score'] as num?)?.toDouble(),
      durationCompliance: (map['duration_compliance'] as num?)?.toDouble(),
      documentationCompliance:
          (map['documentation_compliance'] as num?)?.toDouble(),
      medicationCompliance:
          (map['medication_compliance'] as num?)?.toDouble(),
      incidentReportingCompliance:
          (map['incident_reporting_compliance'] as num?)?.toDouble(),
      flagsCount: map['flags_count'] as int?,
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      categoryScores: parsedCategories,
    );
  }

  /// Safe date parser – handles both [DateTime] and [String] ISO-8601 values
  /// that Supabase / PostgREST may return.
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}