/// All models for the Daily Five quiz engine.
///
/// KEY DESIGN: [DailyFiveSession] is intentionally ephemeral — it is never
/// written to the database. Only [DailyFiveStreak] is persisted centrally.
/// This is a deliberate product decision per Agent.md Section 6.
library;

// ── Question ──────────────────────────────────────────────────────────────────

/// One question from the `question_bank` table.
class DailyFiveQuestion {
  final String id;
  final String questionText;
  /// Four answer choices (index 0–3 = A–D).
  final List<String> options;
  /// 0-based index of the correct answer.
  final int correctOption;
  final String topic;
  final String difficulty;
  /// Whether this question is active in the pool. Inactive questions are
  /// excluded from daily draws but retained for historical accuracy.
  final bool isActive;

  const DailyFiveQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctOption,
    required this.topic,
    required this.difficulty,
    this.isActive = true,
  });

  factory DailyFiveQuestion.fromMap(Map<String, dynamic> data) {
    final rawOptions = data['options'];
    List<String> opts;
    if (rawOptions is List) {
      opts = rawOptions.map((e) => e.toString()).toList();
    } else {
      opts = ['A', 'B', 'C', 'D'];
    }
    return DailyFiveQuestion(
      id: data['id'] as String,
      questionText: data['question_text'] as String,
      options: opts,
      correctOption: data['correct_option'] as int,
      topic: data['topic'] as String,
      difficulty: data['difficulty'] as String,
      isActive: data['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'question_text': questionText,
        'options': options,
        'correct_option': correctOption,
        'topic': topic,
        'difficulty': difficulty,
        'is_active': isActive,
      };
}

// ── Ephemeral Session ─────────────────────────────────────────────────────────

/// One daily session — 5 questions + the student's answers.
/// NEVER persisted to the database. Lives only in memory for the duration
/// of the quiz and the results screen (including the AI explanation window).
/// After that it is discarded.
class DailyFiveSession {
  final List<DailyFiveQuestion> questions;
  /// Index into [questions] of the question currently being shown.
  final int currentIndex;
  /// Answers given by the student so far. Null means not yet answered.
  final List<int?> selectedAnswers;
  final bool isComplete;
  final DateTime startedAt;

  DailyFiveSession({
    required this.questions,
    this.currentIndex = 0,
    List<int?>? selectedAnswers,
    this.isComplete = false,
    DateTime? startedAt,
  })  : selectedAnswers =
            selectedAnswers ?? List.filled(questions.length, null),
        startedAt = startedAt ?? DateTime.now();

  bool get isLastQuestion => currentIndex == questions.length - 1;
  bool get allAnswered => selectedAnswers.every((a) => a != null);

  DailyFiveQuestion get currentQuestion => questions[currentIndex];

  /// Number of correct answers in a completed session.
  int get correctCount {
    int count = 0;
    for (var i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == questions[i].correctOption) count++;
    }
    return count;
  }

  /// Accuracy rate as a 0.0–1.0 value for storage in [DailyFiveStreak].
  double get accuracyRate => correctCount / questions.length;

  /// Returns a copy with the given answer selected for [index].
  DailyFiveSession withAnswer(int questionIndex, int answerIndex) {
    final updated = List<int?>.from(selectedAnswers);
    updated[questionIndex] = answerIndex;
    return DailyFiveSession(
      questions: questions,
      currentIndex: currentIndex,
      selectedAnswers: updated,
      isComplete: isComplete,
      startedAt: startedAt,
    );
  }

  /// Returns a copy with optional overrides (used by provider state management).
  DailyFiveSession copyWith({
    List<DailyFiveQuestion>? questions,
    int? currentIndex,
    List<int?>? selectedAnswers,
    bool? isComplete,
    DateTime? startedAt,
  }) {
    return DailyFiveSession(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      isComplete: isComplete ?? this.isComplete,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  /// Advances to the next question.
  DailyFiveSession next() => DailyFiveSession(
        questions: questions,
        currentIndex: currentIndex + 1,
        selectedAnswers: selectedAnswers,
        startedAt: startedAt,
      );

  /// Returns a completed session (all questions answered, ready to grade).
  DailyFiveSession complete() => DailyFiveSession(
        questions: questions,
        currentIndex: currentIndex,
        selectedAnswers: selectedAnswers,
        isComplete: true,
        startedAt: startedAt,
      );
}

// ── Streak ────────────────────────────────────────────────────────────────────

/// Persisted streak state for one user. Stored in `daily_five_streaks`.
/// This is the ONLY data about the Daily Five that lives in the database.
class DailyFiveStreak {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final int freezesRemaining;
  /// The month (YYYY-MM) in which the current freeze quota was issued.
  final String freezesResetMonth;
  final DateTime? lastCompletedDate;
  /// Accuracy rate from the most recent session (0.0–1.0). Null if never played.
  final double? lastAccuracyRate;
  final DateTime updatedAt;

  const DailyFiveStreak({
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.freezesRemaining,
    required this.freezesResetMonth,
    this.lastCompletedDate,
    this.lastAccuracyRate,
    required this.updatedAt,
  });

  factory DailyFiveStreak.fromMap(Map<String, dynamic> data) {
    return DailyFiveStreak(
      userId: data['user_id'] as String,
      currentStreak: data['current_streak'] as int? ?? 0,
      longestStreak: data['longest_streak'] as int? ?? 0,
      freezesRemaining: data['freezes_remaining'] as int? ?? 2,
      freezesResetMonth: data['freezes_reset_month'] as String? ??
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
      lastCompletedDate: data['last_completed_date'] != null
          ? DateTime.tryParse(data['last_completed_date'].toString())
          : null,
      lastAccuracyRate: data['last_accuracy_rate'] != null
          ? double.tryParse(data['last_accuracy_rate'].toString())
          : null,
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }

  /// True if today's session has already been completed.
  bool get completedToday {
    if (lastCompletedDate == null) return false;
    final today = DateTime.now();
    return lastCompletedDate!.year == today.year &&
        lastCompletedDate!.month == today.month &&
        lastCompletedDate!.day == today.day;
  }

  bool get hasFreeze => freezesRemaining > 0;

  /// Whether this streak is at a milestone (e.g. 100, 200, ...).
  bool get isAtMilestone => currentStreak > 0 && currentStreak % 100 == 0;

  @override
  String toString() =>
      'DailyFiveStreak($currentStreak 🔥, longest: $longestStreak)';
}
