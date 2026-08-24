import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_content.dart';

/// Fetches and tracks completion of the day's "Project Task" and
/// "Apti & DSA" content (apps/mobile/lib/ui/tasks/tasks_screen.dart).
/// Content is static and shared cohort-wide — selected deterministically
/// by day-of-year, not per-user.
class DailyContentService {
  final SupabaseClient _supabase;

  DailyContentService(this._supabase);

  int get _todayDayOfYear {
    final now = DateTime.now();
    return int.parse(DateFormatDoy.format(now));
  }

  /// Returns today's project task, or null if no content is seeded for
  /// today's day-of-year.
  Future<ProjectTask?> fetchTodaysProjectTask() async {
    final response = await _supabase
        .from('project_task_bank')
        .select()
        .eq('day_of_year', _todayDayOfYear)
        .eq('is_active', true)
        .maybeSingle();
    return response != null ? ProjectTask.fromMap(response) : null;
  }

  /// Returns today's DSA + aptitude practice set, or null if no content is
  /// seeded for today's day-of-year.
  Future<AptiDsaDailyItem?> fetchTodaysAptiDsa() async {
    final response = await _supabase
        .from('apti_dsa_daily_bank')
        .select()
        .eq('day_of_year', _todayDayOfYear)
        .eq('is_active', true)
        .maybeSingle();
    return response != null ? AptiDsaDailyItem.fromMap(response) : null;
  }

  /// Marks today's item of [contentType] ('project_task' | 'apti_dsa') as
  /// complete for the current user. Idempotent — re-marking the same day
  /// just updates the timestamp.
  Future<void> markComplete(String userId, String contentType, {String? notes}) async {
    try {
      await _supabase.from('daily_content_completions').upsert({
        'user_id': userId,
        'content_type': contentType,
        'item_date': DateTime.now().toIso8601String().split('T')[0],
        'completed_at': DateTime.now().toIso8601String(),
        'notes': notes,
      });
    } catch (e) {
      debugPrint('[DailyContentService] markComplete error: $e');
      rethrow;
    }
  }

  /// Whether the current user has already completed today's item of
  /// [contentType].
  Future<bool> isCompletedToday(String userId, String contentType) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final response = await _supabase
        .from('daily_content_completions')
        .select('item_date')
        .eq('user_id', userId)
        .eq('content_type', contentType)
        .eq('item_date', today)
        .maybeSingle();
    return response != null;
  }

  /// Returns how many days of [contentType] this user has completed in
  /// total (for a simple "X / 365 completed" progress indicator).
  Future<int> fetchCompletionCount(String userId, String contentType) async {
    final response = await _supabase
        .from('daily_content_completions')
        .select('item_date')
        .eq('user_id', userId)
        .eq('content_type', contentType);
    return (response as List).length;
  }
}

/// Formats a [DateTime] as its 1-366 day-of-year ordinal.
class DateFormatDoy {
  static String format(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final doy = date.difference(startOfYear).inDays + 1;
    return doy.toString();
  }
}
