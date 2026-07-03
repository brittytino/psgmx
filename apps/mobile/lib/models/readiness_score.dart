/// A snapshot of a student's computed readiness score.
/// Stored in `readiness_scores` as a daily/weekly record so the student
/// can see their progress over time.
class ReadinessScore {
  final String id;
  final String userId;
  final String? userName;
  final String? avatarUrl;
  final String? gender;
  /// The overall score (0–100).
  final double score;
  final DateTime computedAt;
  /// Breakdown of each of the 5 components (values 0–100).
  final ReadinessComponents components;

  const ReadinessScore({
    required this.id,
    required this.userId,
    this.userName,
    this.avatarUrl,
    this.gender,
    required this.score,
    required this.computedAt,
    required this.components,
  });

  factory ReadinessScore.fromMap(Map<String, dynamic> data) {
    final comps = data['components_json'];
    String? parsedName;
    String? parsedAvatarUrl;
    if (data['users'] != null && data['users'] is Map) {
      parsedName = data['users']['name'] as String?;
      parsedAvatarUrl = data['users']['avatar_url'] as String?;
    }
    final parsedGender = (data['users'] is Map) ? data['users']['gender'] as String? : null;
    
    return ReadinessScore(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      userName: parsedName,
      avatarUrl: parsedAvatarUrl,
      gender: parsedGender,
      score: double.tryParse(data['score'].toString()) ?? 0,
      computedAt: DateTime.parse(data['computed_at'] as String),
      components: comps is Map<String, dynamic>
          ? ReadinessComponents.fromMap(comps)
          : const ReadinessComponents(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'score': score,
        'computed_at': computedAt.toIso8601String(),
        'components_json': components.toMap(),
      };

  /// A letter grade based on the score (for display).
  String get grade {
    if (score >= 90) return 'A+';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B';
    if (score >= 60) return 'C';
    if (score >= 50) return 'D';
    return 'F';
  }
}

/// The 5 weighted components of the readiness score formula:
/// Readiness = 0.30×PlacementAtt + 0.20×DailyFiveAdherence
///           + 0.20×TaskCompletion + 0.15×DailyFiveAccuracy
///           + 0.15×LeetCodeMomentum
class ReadinessComponents {
  /// From placement_attendance_summary (0–100). Weight: 0.30
  final double placementAttendancePct;

  /// Days the daily-five was fully completed ÷ eligible days, trailing 30d (0–100). Weight: 0.20
  final double dailyFiveAdherencePct;

  /// Verified completed tasks ÷ assigned tasks, trailing 30d (0–100). Weight: 0.20
  final double taskCompletionRatePct;

  /// Correct answers ÷ total answered across sessions (0–100). Weight: 0.15
  final double dailyFiveAccuracyPct;

  /// Problems solved in trailing 30 days, as a within-batch percentile (0–100). Weight: 0.15
  final double leetcodeMomentumPercentile;

  const ReadinessComponents({
    this.placementAttendancePct = 0,
    this.dailyFiveAdherencePct = 0,
    this.taskCompletionRatePct = 0,
    this.dailyFiveAccuracyPct = 0,
    this.leetcodeMomentumPercentile = 0,
  });

  factory ReadinessComponents.fromMap(Map<String, dynamic> data) {
    double parse(String key) =>
        double.tryParse(data[key]?.toString() ?? '0') ?? 0;

    return ReadinessComponents(
      placementAttendancePct: parse('placement_attendance_pct'),
      dailyFiveAdherencePct: parse('daily_five_adherence_pct'),
      taskCompletionRatePct: parse('task_completion_rate_pct'),
      dailyFiveAccuracyPct: parse('daily_five_accuracy_pct'),
      leetcodeMomentumPercentile: parse('leetcode_momentum_percentile'),
    );
  }

  Map<String, dynamic> toMap() => {
        'placement_attendance_pct': placementAttendancePct,
        'daily_five_adherence_pct': dailyFiveAdherencePct,
        'task_completion_rate_pct': taskCompletionRatePct,
        'daily_five_accuracy_pct': dailyFiveAccuracyPct,
        'leetcode_momentum_percentile': leetcodeMomentumPercentile,
      };

  /// Recomputes the overall score from the components using the formula weights.
  double get computedScore =>
      (0.30 * placementAttendancePct) +
      (0.20 * dailyFiveAdherencePct) +
      (0.20 * taskCompletionRatePct) +
      (0.15 * dailyFiveAccuracyPct) +
      (0.15 * leetcodeMomentumPercentile);
}
