import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/readiness_score.dart';
import '../core/supabase_config.dart';

/// Computes, stores, and retrieves the student readiness score.
///
/// Computation is done server-side via a Postgres RPC function
/// (`compute_readiness_score`) which reads from all component tables.
/// The score is then optionally pushed to the external desktop exam platform.
class ReadinessScoreService {
  final SupabaseClient _supabase;

  ReadinessScoreService(this._supabase);

  // ── Compute ────────────────────────────────────────────────────────────────

  /// Triggers server-side score computation and returns the stored snapshot.
  ///
  /// The computation happens inside the Postgres `compute_readiness_score()`
  /// function which writes to `readiness_scores`. We then fetch the latest
  /// row back to display the result.
  Future<ReadinessScore> computeAndStore(String userId) async {
    try {
      await _supabase.rpc('compute_readiness_score', params: {
        'p_user_id': userId,
      });
      debugPrint('[ReadinessScoreService] Score computed for $userId');
      return (await fetchLatestScore(userId))!;
    } catch (e) {
      debugPrint('[ReadinessScoreService] computeAndStore error: $e');
      rethrow;
    }
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────

  /// Returns the most recently computed score for a user, or null if none.
  Future<ReadinessScore?> fetchLatestScore(String userId) async {
    final response = await _supabase
        .from('readiness_scores')
        .select()
        .eq('user_id', userId)
        .order('computed_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return response != null ? ReadinessScore.fromMap(response) : null;
  }

  /// Returns the score history for a user (for the trend-line chart).
  /// Returns up to [limit] snapshots, newest first.
  Future<List<ReadinessScore>> fetchScoreHistory(
    String userId, {
    int limit = 30,
  }) async {
    final response = await _supabase
        .from('readiness_scores')
        .select()
        .eq('user_id', userId)
        .order('computed_at', ascending: false)
        .limit(limit);
    return (response as List)
        .map((r) => ReadinessScore.fromMap(r))
        .toList()
        .reversed
        .toList(); // Oldest first for chart rendering
  }

  /// Returns scores for all users in a batch (for admin analytics).
  Future<List<ReadinessScore>> fetchBatchLatestScores(String batchId) async {
    final response = await _supabase
        .from('readiness_scores')
        .select('*, users!inner(batch_id, name, gender)')
        .eq('users.batch_id', batchId)
        .order('computed_at', ascending: false);

    // Deduplicate — keep only the latest score per user
    final seen = <String>{};
    final result = <ReadinessScore>[];
    for (final row in response as List) {
      final userId = row['user_id'] as String;
      if (seen.add(userId)) {
        result.add(ReadinessScore.fromMap(row));
      }
    }
    return result..sort((a, b) => b.score.compareTo(a.score));
  }

  // ── External Platform Push ─────────────────────────────────────────────────

  /// Pushes the latest readiness score for [userId] to the external desktop
  /// exam platform via an authenticated POST request.
  ///
  /// The external platform uses this number (alongside its own major-test
  /// scores) to compute the combined faculty-facing score. PSGMX only ever
  /// sends this one value — it never receives anything back.
  Future<bool> pushScoreToExternalPlatform({
    required String userId,
    required double score,
    String? rollNo,
  }) async {
    const apiKey = SupabaseConfig.externalPlatformApiKey;
    if (apiKey.isEmpty) {
      debugPrint('[ReadinessScoreService] No external platform API key — skip push');
      return false;
    }

    try {
      final response = await http
          .post(
            Uri.parse('https://exam-platform.example.com/api/readiness'), // TODO: real URL
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: '{"student_id":"$userId","roll_no":"${rollNo ?? ''}","readiness_score":$score}',
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(
            '[ReadinessScoreService] ✅ Score pushed to external platform');
        return true;
      } else {
        debugPrint(
            '[ReadinessScoreService] External platform returned ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('[ReadinessScoreService] pushScoreToExternalPlatform error: $e');
      return false;
    }
  }
}
