/// Models backing the "Project Tasks" and "Apti & DSA" tabs
/// (apps/mobile/lib/ui/tasks/tasks_screen.dart). Content is static and
/// date-keyed by day-of-year — every student sees the same day's content,
/// selected server-side via `.eq('day_of_year', doy)`.
library;

/// One day's hands-on project/practical task (`project_task_bank`).
class ProjectTask {
  final String id;
  final int dayOfYear;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final String? referenceLink;

  const ProjectTask({
    required this.id,
    required this.dayOfYear,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    this.referenceLink,
  });

  factory ProjectTask.fromMap(Map<String, dynamic> data) {
    return ProjectTask(
      id: data['id'] as String,
      dayOfYear: data['day_of_year'] as int,
      title: data['title'] as String,
      description: data['description'] as String,
      category: data['category'] as String,
      difficulty: data['difficulty'] as String,
      referenceLink: data['reference_link'] as String?,
    );
  }
}

/// One embedded aptitude question inside an [AptiDsaDailyItem].
class EmbeddedAptitudeQuestion {
  final String question;
  final List<String> options;
  final int correctOption;

  const EmbeddedAptitudeQuestion({
    required this.question,
    required this.options,
    required this.correctOption,
  });

  factory EmbeddedAptitudeQuestion.fromMap(Map<String, dynamic> data) {
    return EmbeddedAptitudeQuestion(
      question: data['question'] as String,
      options: (data['options'] as List).map((e) => e.toString()).toList(),
      correctOption: data['correct_option'] as int,
    );
  }
}

/// One day's DSA problem + embedded aptitude set (`apti_dsa_daily_bank`).
class AptiDsaDailyItem {
  final String id;
  final int dayOfYear;
  final String dsaTitle;
  final String dsaDifficulty;
  final String dsaTopic;
  final String? dsaExternalLink;
  final String? dsaHint;
  final List<EmbeddedAptitudeQuestion> aptitudeQuestions;

  const AptiDsaDailyItem({
    required this.id,
    required this.dayOfYear,
    required this.dsaTitle,
    required this.dsaDifficulty,
    required this.dsaTopic,
    this.dsaExternalLink,
    this.dsaHint,
    required this.aptitudeQuestions,
  });

  factory AptiDsaDailyItem.fromMap(Map<String, dynamic> data) {
    final rawQuestions = data['aptitude_questions'] as List;
    return AptiDsaDailyItem(
      id: data['id'] as String,
      dayOfYear: data['day_of_year'] as int,
      dsaTitle: data['dsa_title'] as String,
      dsaDifficulty: data['dsa_difficulty'] as String,
      dsaTopic: data['dsa_topic'] as String,
      dsaExternalLink: data['dsa_external_link'] as String?,
      dsaHint: data['dsa_hint'] as String?,
      aptitudeQuestions: rawQuestions
          .map((q) => EmbeddedAptitudeQuestion.fromMap(q as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A student's mark-as-done record for one day's content
/// (`daily_content_completions`). No streak — just completion tracking.
class DailyContentCompletion {
  final String userId;
  final String contentType; // 'project_task' | 'apti_dsa'
  final DateTime itemDate;
  final DateTime completedAt;
  final String? notes;

  const DailyContentCompletion({
    required this.userId,
    required this.contentType,
    required this.itemDate,
    required this.completedAt,
    this.notes,
  });

  factory DailyContentCompletion.fromMap(Map<String, dynamic> data) {
    return DailyContentCompletion(
      userId: data['user_id'] as String,
      contentType: data['content_type'] as String,
      itemDate: DateTime.parse(data['item_date'] as String),
      completedAt: DateTime.parse(data['completed_at'] as String),
      notes: data['notes'] as String?,
    );
  }
}
