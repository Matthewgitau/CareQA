/// Automated competency scoring utility.
/// 
/// Scoring rules:
/// - > 65% correct  -> COMPETENT (passed = true, no action plan)
/// - 20-65% correct -> REQUIRES REASSESSMENT (passed = false, needs another assessment)
/// - < 20% correct  -> NOT COMPETENT (passed = false, action plan for retraining)
///
/// "N/A" answers are excluded from the calculation (not counted as correct or incorrect).
class CompetencyScoring {
  /// Calculate the competency score from assessment answers.
  /// Returns a map with:
  /// - `score`: percentage of correct answers (0-100)
  /// - `totalQuestions`: number of questions answered (excluding N/A)
  /// - `correctCount`: number of "yes" answers
  /// - `incorrectCount`: number of "no" answers
  /// - `naCount`: number of "N/A" answers
  /// - `overallRating`: 'competent', 'requires_reassessment', or 'not_competent'
  /// - `passed`: bool
  /// - `actionPlan`: String recommendation
  static Map<String, dynamic> calculate(Map<String, String> answers) {
    final correctCount = answers.values.where((v) => v == 'yes').length;
    final incorrectCount = answers.values.where((v) => v == 'no').length;
    final naCount = answers.values.where((v) => v == 'na').length;
    final totalScored = correctCount + incorrectCount;
    
    // Default to 0 if no scored questions
    final double percentage = totalScored > 0 
        ? (correctCount / totalScored) * 100 
        : 0.0;
    final score = percentage.round();

    String overallRating;
    bool passed;
    String actionPlan;

    if (score > 65) {
      overallRating = 'competent';
      passed = true;
      actionPlan = '';
    } else if (score >= 20) {
      overallRating = 'requires_reassessment';
      passed = false;
      actionPlan = 'Score of $score% indicates gaps. A reassessment must be scheduled within 30 days with targeted support.';
    } else {
      overallRating = 'not_competent';
      passed = false;
      actionPlan = 'Score of $score% is below the minimum standard. Staff member must undergo full retraining and be reassessed within 14 days.';
    }

    return {
      'score': score,
      'totalQuestions': totalScored,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'naCount': naCount,
      'overallRating': overallRating,
      'passed': passed,
      'actionPlan': actionPlan,
    };
  }

  /// Calculate score from multiple answer maps (combined).
  static Map<String, dynamic> calculateFromMaps(List<Map<String, String>> answerMaps) {
    final combined = <String, String>{};
    for (final map in answerMaps) {
      combined.addAll(map);
    }
    return calculate(combined);
  }

  /// Get a display-friendly rating label.
  static String getRatingLabel(String rating) {
    switch (rating) {
      case 'competent':
        return 'Competent';
      case 'requires_reassessment':
        return 'Requires Reassessment';
      case 'not_competent':
        return 'Not Competent';
      default:
        return rating;
    }
  }
}