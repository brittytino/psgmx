import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_five.dart';
import '../services/daily_five_service.dart';


/// State management for the Daily Five quiz engine.
///
/// Lifecycle:
///   1. On mount → [loadState] checks streak (completedToday?)
///   2. If not completed → [startSession] fetches 5 questions
///   3. As user answers → [submitAnswer] updates [session]
///   4. When all answered → [finalizeSession] calls the RPC + updates streak
class DailyFiveProvider with ChangeNotifier {
  final DailyFiveService _service;

  DailyFiveProvider() : _service = DailyFiveService(Supabase.instance.client);

  // ── State ──────────────────────────────────────────────────────────────────

  DailyFiveStreak? _streak;
  DailyFiveSession? _session;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  // ── Getters ────────────────────────────────────────────────────────────────

  DailyFiveStreak? get streak => _streak;
  DailyFiveSession? get session => _session;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  bool get completedToday => _streak?.completedToday ?? false;
  bool get sessionActive => _session != null && !(_session!.allAnswered);
  bool get sessionFinished => _session != null && _session!.allAnswered;

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Loads the streak for [userId] and (if not completed today) starts
  /// fetching questions so the quiz is ready to display.
  Future<void> loadState(String userId) async {
    _setLoading(true);
    _error = null;
    try {
      _streak = await _service.fetchStreak(userId);

      if (_streak == null || !_streak!.completedToday) {
        final questions = await _service.fetchDailyQuestions(userId);
        _session = questions.isNotEmpty ? DailyFiveSession(questions: questions) : null;
        if (questions.isEmpty) _error = 'No questions available today.';
      } else {
        _session = null; // Already done
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('[DailyFiveProvider] loadState error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Records the user's answer for the current question and advances the
  /// session state. If it was the last question, finalizes automatically.
  Future<void> submitAnswer({
    required String userId,
    required int optionIndex,
  }) async {
    if (_session == null) return;

    final updated = _session!.withAnswer(_session!.currentIndex, optionIndex);

    if (updated.isLastQuestion) {
      // Record the answer, mark complete
      _session = updated.copyWith(isComplete: true);
      notifyListeners();
      await finalizeSession(userId: userId);
    } else {
      // Advance to next question
      _session = updated.copyWith(currentIndex: updated.currentIndex + 1);
      notifyListeners();
    }
  }

  /// Terminates the exam due to proctoring violation.
  /// Calls the service to reset the streak and mark as completed.
  Future<void> handleTermination(String userId) async {
    if (_session == null || sessionFinished) return;
    _isSubmitting = true;
    notifyListeners();

    try {
      _streak = await _service.terminateExam(userId);
      _session = _session!.copyWith(isComplete: true);
    } catch (e) {
      _error = 'Failed to terminate: $e';
      debugPrint('[DailyFiveProvider] handleTermination error: $e');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Calls the RPC to update streak, then refreshes local streak state.
  /// NOTE: The readiness score is automatically recomputed by a Supabase
  /// database trigger that fires on daily_five_streaks UPDATE.
  /// Do NOT call the Edge Function or RPC from here — the trigger handles it.
  Future<void> finalizeSession({required String userId}) async {
    if (_session == null) return;
    _isSubmitting = true;
    notifyListeners();

    try {
      final updatedStreak = await _service.submitSession(
        userId: userId,
        accuracyRate: _session!.accuracyRate,
      );
      _streak = updatedStreak;
      // The readiness score is updated automatically by:
      //   trigger: trig_daily_five_streaks_readiness on daily_five_streaks
      // No action needed here.
    } catch (e) {
      _error = 'Failed to submit: $e';
      debugPrint('[DailyFiveProvider] finalizeSession error: $e');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Spends a freeze token for [userId].
  Future<String> applyFreeze(String userId) async {
    final result = await _service.applyFreeze(userId);
    if (result == 'ok') {
      _streak = await _service.fetchStreak(userId);
      notifyListeners();
    }
    return result;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
