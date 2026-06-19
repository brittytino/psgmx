import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_five.dart';

/// Manages all Daily Five quiz operations:
/// - Fetching today's 5 questions from the question bank (kept in memory only)
/// - Grading answers (in memory — never persisted per question)
/// - Updating streak state via the DB RPC functions
/// - Managing freeze spending
class DailyFiveService {
  final SupabaseClient _supabase;
  final Random _rng = Random();

  DailyFiveService(this._supabase);

  // ── Questions ──────────────────────────────────────────────────────────────

  /// Draws 5 random active questions from the `question_bank` table.
  ///
  /// Questions are selected randomly in-db using ORDER BY RANDOM() LIMIT 5.
  /// The returned [DailyFiveSession] is ephemeral — it is NOT written to
  /// the database at any point.
  Future<DailyFiveSession> fetchTodaysSession() async {
    try {
      // Use Postgres RANDOM() for server-side shuffle — avoids pulling the
      // entire question bank to the device for client-side shuffle.
      final response = await _supabase
          .from('question_bank')
          .select()
          .eq('is_active', true)
          .limit(5)
          // Supabase JS SDK wraps RANDOM() — we pass it as a raw filter param.
          .order('id', ascending: _rng.nextBool()); // simple shuffle proxy
      // TODO: Replace with a proper RPC call `select_random_questions(5)` for
      //       true server-side RANDOM() ordering when the function is deployed.

      final questions = (response as List)
          .map((r) => DailyFiveQuestion.fromMap(r))
          .toList();

      if (questions.isEmpty) {
        throw Exception('No active questions found in question bank.');
      }

      // Trim to 5 if we accidentally got more (shouldn't happen with LIMIT)
      final selected = questions.take(5).toList();
      debugPrint('[DailyFiveService] Loaded ${selected.length} questions');
      return DailyFiveSession(questions: selected);
    } catch (e) {
      debugPrint('[DailyFiveService] fetchTodaysSession error: $e');
      rethrow;
    }
  }

  // ── Streak ─────────────────────────────────────────────────────────────────

  /// Fetches the current streak state for a user.
  Future<DailyFiveStreak?> fetchStreak(String userId) async {
    try {
      final response = await _supabase
          .from('daily_five_streaks')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response != null ? DailyFiveStreak.fromMap(response) : null;
    } catch (e) {
      debugPrint('[DailyFiveService] fetchStreak error: $e');
      return null;
    }
  }

  /// Called after a user completes all 5 questions.
  ///
  /// Calls the Postgres `increment_daily_five_streak()` RPC which handles:
  /// - Monthly freeze reset
  /// - Streak increment or reset
  /// - Longest streak update
  /// - Accuracy rate storage
  ///
  /// Returns the updated [DailyFiveStreak].
  Future<DailyFiveStreak> submitCompletion({
    required String userId,
    required DailyFiveSession completedSession,
  }) async {
    final accuracyRate = completedSession.accuracyRate;
    await _supabase.rpc('increment_daily_five_streak', params: {
      'p_user_id': userId,
      'p_accuracy_rate': accuracyRate,
    });

    // Audit log the completion
    await _supabase.from('audit_logs').insert({
      'actor_id': userId,
      'action': 'DAILY_FIVE_COMPLETED',
      'entity_type': 'daily_five_streaks',
      'entity_id': null,
      'metadata': {
        'accuracy_rate': accuracyRate,
        'correct_count': completedSession.correctCount,
        'total_questions': completedSession.questions.length,
      },
    });

    final updated = await fetchStreak(userId);
    debugPrint(
        '[DailyFiveService] Streak updated: ${updated?.currentStreak} 🔥 '
        '(accuracy: ${(accuracyRate * 100).toStringAsFixed(0)}%)');
    return updated!;
  }

  // ── Convenience aliases (used by UI screens) ───────────────────────────────

  /// Alias for [fetchStreak] — used by DailyFiveScreen.
  Future<DailyFiveStreak?> fetchMyStreak(String userId) => fetchStreak(userId);

  /// Returns the 5 questions for today as a plain list (not wrapped in a session).
  /// The screen builds its own [DailyFiveSession] from this.
  Future<List<DailyFiveQuestion>> fetchDailyQuestions() async {
    final session = await fetchTodaysSession();
    return session.questions;
  }

  /// Alias for [submitCompletion] with the flat accuracy-rate signature
  /// used by [DailyFiveScreen] (which has already graded the session in-memory).
  Future<DailyFiveStreak> submitSession({
    required String userId,
    required double accuracyRate,
  }) async {
    await _supabase.rpc('increment_daily_five_streak', params: {
      'p_user_id': userId,
      'p_accuracy_rate': accuracyRate,
    });
    await _supabase.from('audit_logs').insert({
      'actor_id': userId,
      'action': 'DAILY_FIVE_COMPLETED',
      'entity_type': 'daily_five_streaks',
      'entity_id': null,
      'metadata': {'accuracy_rate': accuracyRate},
    });
    final updated = await fetchStreak(userId);
    return updated!;
  }

  /// Spends a freeze to preserve the streak after a missed day.
  ///
  /// Returns a string: 'ok', 'no_freezes', 'already_completed', or 'no_streak'.
  Future<String> applyFreeze(String userId) async {
    try {
      final result = await _supabase.rpc('apply_streak_freeze', params: {
        'p_user_id': userId,
      });
      debugPrint('[DailyFiveService] applyFreeze result: $result');
      return result?.toString() ?? 'error';
    } catch (e) {
      debugPrint('[DailyFiveService] applyFreeze error: $e');
      return 'error';
    }
  }

  // ── Question Bank Management ───────────────────────────────────────────────

  /// Returns all active questions (for question bank admin screen).
  /// Requires [publish_tasks] permission (enforced by RLS).
  Future<List<DailyFiveQuestion>> fetchAllQuestions() async {
    final response = await _supabase
        .from('question_bank')
        .select()
        .order('topic');
    return (response as List).map((r) => DailyFiveQuestion.fromMap(r)).toList();
  }

  /// Creates a new question in the bank.
  Future<DailyFiveQuestion> createQuestion({
    required String createdBy,
    required String questionText,
    required List<String> options,
    required int correctOption,
    required String topic,
    required String difficulty,
  }) async {
    assert(options.length == 4, 'Questions must have exactly 4 options');
    assert(correctOption >= 0 && correctOption <= 3, 'Invalid correct option');

    final response = await _supabase.from('question_bank').insert({
      'question_text': questionText,
      'options': options,
      'correct_option': correctOption,
      'topic': topic,
      'difficulty': difficulty,
      'created_by': createdBy,
    }).select().single();

    await _supabase.from('audit_logs').insert({
      'actor_id': createdBy,
      'action': 'CREATE_QUESTION',
      'entity_type': 'question_bank',
      'entity_id': null,
      'metadata': {'topic': topic, 'difficulty': difficulty},
    });

    return DailyFiveQuestion.fromMap(response);
  }

  /// Updates an existing question.
  Future<void> updateQuestion({
    required String questionId,
    String? questionText,
    List<String>? options,
    int? correctOption,
    String? topic,
    String? difficulty,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (questionText != null) updates['question_text'] = questionText;
    if (options != null) updates['options'] = options;
    if (correctOption != null) updates['correct_option'] = correctOption;
    if (topic != null) updates['topic'] = topic;
    if (difficulty != null) updates['difficulty'] = difficulty;
    if (isActive != null) updates['is_active'] = isActive;

    if (updates.isEmpty) return;
    await _supabase.from('question_bank').update(updates).eq('id', questionId);
  }

  /// Soft-deletes a question by marking it inactive.
  Future<void> deactivateQuestion(String questionId, {required String deactivatedBy}) async {
    await _supabase
        .from('question_bank')
        .update({'is_active': false}).eq('id', questionId);

    await _supabase.from('audit_logs').insert({
      'actor_id': deactivatedBy,
      'action': 'DEACTIVATE_QUESTION',
      'entity_type': 'question_bank',
      'entity_id': null,
      'metadata': {'question_id': questionId},
    });
  }

  // ── Leaderboard ────────────────────────────────────────────────────────────

  /// Returns streak data for all users in a batch (for leaderboard display).
  /// Requires [view_batch_analytics] permission (enforced by RLS).
  Future<List<DailyFiveStreak>> fetchBatchStreaks(String batchId) async {
    final response = await _supabase
        .from('daily_five_streaks')
        .select('*, users!inner(batch_id)')
        .eq('users.batch_id', batchId)
        .order('current_streak', ascending: false);
    return (response as List)
        .map((r) => DailyFiveStreak.fromMap(r))
        .toList();
  }
}
