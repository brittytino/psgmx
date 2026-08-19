import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_five.dart';
import 'readiness_score_service.dart';
import 'dart:convert';
import '../data/local_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' as drift;

/// Manages all Daily Five quiz operations:
/// - Fetching today's 5 server-picked questions (answer key withheld
///   until after submission — see get_daily_five_questions RPC)
/// - Server-side grading (submit_daily_five_answers RPC — this client no
///   longer computes or self-reports a score)
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
  Future<DailyFiveSession> fetchTodaysSession(String userId) async {
    try {
      // Determine network status
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOffline = connectivityResult.contains(ConnectivityResult.none);

      if (isOffline) {
        debugPrint('[DailyFiveService] Offline mode: loading from Drift cache');
        final cached = await localDb.select(localDb.dailyFiveCache).get();
        if (cached.isEmpty) {
          throw Exception('No offline questions available. Please connect to internet.');
        }
        
        final questions = cached.map((c) {
          final optsList = (jsonDecode(c.optionsJson) as List).map((e) => e.toString()).toList();
          return DailyFiveQuestion(
            id: c.id,
            questionText: c.questionText,
            options: optsList,
            // -1 is the cache sentinel for "server didn't send the answer"
            // (see _cacheQuestionsInDrift) — translate back to null so
            // offline grading code treats it the same as the online path.
            correctOption: c.correctOption == -1 ? null : c.correctOption,
            topic: c.topic,
            difficulty: c.difficulty,
            isActive: c.isActive,
          );
        }).toList();
        
        questions.shuffle(_rng);
        final selected = questions.take(5).toList();
        return DailyFiveSession(questions: selected);
      }

      // Server-picked, seeded per (user_id, today) — returns exactly 5
      // questions with correct_option stripped server-side (Section 4.2:
      // "answer key never shipped to client pre-submission"). Previously
      // this fetched the ENTIRE topic pool via a bare select() including
      // correct_option, then shuffled/trimmed client-side — the full
      // answer key was visible in the response before the student
      // answered a single question.
      final response = await _supabase.rpc('get_daily_five_questions', params: {
        'p_user_id': userId,
      });

      final selected = (response as List)
          .map((r) => DailyFiveQuestion.fromMap(r as Map<String, dynamic>))
          .toList();

      if (selected.isEmpty) {
        throw Exception('No active questions found in question bank for your batch.');
      }

      // Cache for offline READ availability only — correct_option is not
      // present in this response (by design), so offline mode can display
      // these same 5 questions but cannot self-grade them; submission
      // while offline is queued and graded server-side once reconnected
      // (see submitSession's offline branch).
      _cacheQuestionsInDrift(selected);

      debugPrint('[DailyFiveService] Loaded ${selected.length} questions via get_daily_five_questions RPC');
      return DailyFiveSession(questions: selected);
    } catch (e) {
      debugPrint('[DailyFiveService] fetchTodaysSession error: $e');
      rethrow;
    }
  }

  Future<void> _cacheQuestionsInDrift(List<DailyFiveQuestion> questions) async {
    try {
      await localDb.delete(localDb.dailyFiveCache).go(); // Clear old cache
      await localDb.batch((batch) {
        batch.insertAll(
          localDb.dailyFiveCache,
          questions.map((q) => DailyFiveCacheCompanion.insert(
                id: q.id,
                questionText: q.questionText,
                optionsJson: jsonEncode(q.options),
                // -1 sentinel: the Drift column is non-nullable and
                // q.correctOption is null here by design (server strips it
                // pre-submission) — see the read-side translation above.
                correctOption: q.correctOption ?? -1,
                topic: q.topic,
                difficulty: q.difficulty,
                isActive: drift.Value(q.isActive),
              )),
        );
      });
      debugPrint('[DailyFiveService] Successfully cached ${questions.length} questions to Drift');
    } catch (e) {
      debugPrint('[DailyFiveService] Failed to cache to Drift: $e');
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

  // ── Convenience aliases (used by UI screens) ───────────────────────────────

  /// Alias for [fetchStreak] — used by DailyFiveScreen.
  Future<DailyFiveStreak?> fetchMyStreak(String userId) => fetchStreak(userId);

  /// Returns the 5 questions for today as a plain list (not wrapped in a session).
  /// The screen builds its own [DailyFiveSession] from this.
  Future<List<DailyFiveQuestion>> fetchDailyQuestions(String userId) async {
    final session = await fetchTodaysSession(userId);
    return session.questions;
  }

  /// Submits the student's answers for grading.
  ///
  /// CHANGED: previously took a pre-computed `accuracyRate` (graded
  /// client-side, self-reported straight into increment_daily_five_streak
  /// — a student could call that RPC directly with accuracyRate: 1.0
  /// regardless of what they actually answered). Now takes the raw
  /// answers and grades server-side via submit_daily_five_answers(),
  /// which reads correct_option as the function owner (bypassing the
  /// column-level REVOKE that blocks students from reading it directly)
  /// and only then calls increment_daily_five_streak with a verified rate.
  Future<DailyFiveStreak> submitSession({
    required String userId,
    required Map<String, int> answersByQuestionId,
  }) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOffline = connectivityResult.contains(ConnectivityResult.none);

    if (isOffline) {
      debugPrint('[DailyFiveService] Offline mode: queueing answers for server-side grading on reconnect');
      await localDb.into(localDb.syncQueue).insert(SyncQueueCompanion.insert(
        actionType: 'submit_daily_five',
        payloadJson: jsonEncode({
          'user_id': userId,
          'answers': answersByQuestionId,
        }),
      ));

      // Optimistic UI: bump the locally-cached streak count, but the real
      // accuracy is unknown until this syncs and is server-graded — no
      // client-side score to show here anymore (there's no answer key on
      // this device to compute one from).
      final cachedStreak = await localDb.select(localDb.offlineStreaks).get();
      if (cachedStreak.isNotEmpty) {
        final st = cachedStreak.first;
        return DailyFiveStreak(
          userId: st.userId,
          currentStreak: st.currentStreak + 1, // optimistic UI increment
          longestStreak: st.longestStreak,
          freezesRemaining: st.freezesRemaining,
          freezesResetMonth: st.freezesResetMonth,
          lastCompletedDate: DateTime.now(),
          lastAccuracyRate: null, // pending server grading
          updatedAt: DateTime.now(),
        );
      } else {
        return DailyFiveStreak(
          userId: userId,
          currentStreak: 1,
          longestStreak: 1,
          freezesRemaining: 2,
          freezesResetMonth: 'offline',
          lastCompletedDate: DateTime.now(),
          lastAccuracyRate: null,
          updatedAt: DateTime.now(),
        );
      }
    }

    // Server-side grading — see submit_daily_five_answers() in
    // supabase/migrations/10_sprint2_anticheat.sql. It grades, updates
    // daily_five_attempts, flags impossibly-fast completions, calls
    // increment_daily_five_streak() internally, and writes the audit log
    // itself, so none of that is duplicated here anymore.
    await _supabase.rpc('submit_daily_five_answers', params: {
      'p_user_id': userId,
      'p_answers': answersByQuestionId,
    });

    // Dynamically update readiness score
    try {
      await ReadinessScoreService(_supabase).computeAndStore(userId);
    } catch (e) {
      debugPrint('[DailyFiveService] Could not dynamically update readiness score: $e');
    }

    final updated = await fetchStreak(userId);

    // Cache the updated streak for next offline run
    if (updated != null) {
      try {
        await localDb.into(localDb.offlineStreaks).insertOnConflictUpdate(OfflineStreaksCompanion.insert(
          userId: updated.userId,
          currentStreak: updated.currentStreak,
          longestStreak: updated.longestStreak,
          freezesRemaining: updated.freezesRemaining,
          freezesResetMonth: updated.freezesResetMonth,
          lastCompletedDate: drift.Value(updated.lastCompletedDate?.toIso8601String()),
          lastAccuracyRate: drift.Value(updated.lastAccuracyRate),
          updatedAt: updated.updatedAt,
        ));
      } catch (e) {
         debugPrint('[DailyFiveService] Could not cache streak: $e');
      }
    }

    return updated!;
  }

  /// Reveals correct_option for today's already-submitted attempt only —
  /// powers the post-submission "why was I wrong" AI explanation. Returns
  /// a map of question id → correct option index.
  Future<Map<String, int>> fetchTodaysResults(String userId) async {
    final response = await _supabase.rpc('get_daily_five_results', params: {'p_user_id': userId});
    return {for (final row in (response as List)) row['id'] as String: row['correct_option'] as int};
  }

  /// Terminates the exam due to a proctoring violation.
  /// Marks the user as participated (0% accuracy) so they can't re-take it today,
  /// but forcefully resets their current streak to 0 as a penalty.
  Future<DailyFiveStreak> terminateExam(String userId) async {
    // 1. Log participation so they can't retake it
    await _supabase.rpc('increment_daily_five_streak', params: {
      'p_user_id': userId,
      'p_accuracy_rate': 0.0,
    });
    
    // 2. Punish by resetting streak to 0 — via RPC, not a direct table
    // write (Section 4.5: no client role should have direct UPDATE on
    // daily_five_streaks; see 10_sprint2_anticheat.sql).
    await _supabase.rpc('reset_daily_five_streak_violation', params: {'p_user_id': userId});
    
    // 3. Log violation
    await _supabase.from('audit_logs').insert({
      'actor_id': userId,
      'action': 'EXAM_TERMINATED_VIOLATION',
      'entity_type': 'daily_five_streaks',
      'entity_id': null,
    });
    
    // 4. Update readiness score
    try {
      await ReadinessScoreService(_supabase).computeAndStore(userId);
    } catch (e) {
      debugPrint('[DailyFiveService] Could not dynamically update readiness score: $e');
    }

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

  /// Returns all questions, including correct_option (for question bank
  /// admin screen). Requires the `publish_tasks` permission or
  /// Faculty/HOD role — enforced inside get_question_bank_full() itself,
  /// since correct_option is column-REVOKEd for `authenticated` and a
  /// raw select() can no longer read it at all (a bare select() here
  /// would error the whole request for every caller, not just students).
  Future<List<DailyFiveQuestion>> fetchAllQuestions() async {
    final response = await _supabase.rpc('get_question_bank_full');
    return (response as List).map((r) => DailyFiveQuestion.fromMap(r as Map<String, dynamic>)).toList();
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

    // Explicit column list on the returning select — never select()/select('*')
    // on question_bank; correct_option is column-REVOKEd for `authenticated`
    // (S1-style fix, Section 4.2), so a wildcard select would error even for
    // the coordinator who just wrote it. The caller already knows
    // correctOption locally (they just typed it in), so it's filled in below
    // rather than re-fetched.
    final response = await _supabase.from('question_bank').insert({
      'question_text': questionText,
      'options': options,
      'correct_option': correctOption,
      'topic': topic,
      'difficulty': difficulty,
      'created_by': createdBy,
    }).select('id, question_text, options, topic, difficulty, is_active').single();

    await _supabase.from('audit_logs').insert({
      'actor_id': createdBy,
      'action': 'CREATE_QUESTION',
      'entity_type': 'question_bank',
      'entity_id': null,
      'metadata': {'topic': topic, 'difficulty': difficulty},
    });

    return DailyFiveQuestion.fromMap({...response, 'correct_option': correctOption});
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
