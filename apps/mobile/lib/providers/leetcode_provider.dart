import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leetcode_stats.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../services/trusted_api_response.dart';
import '../models/notification.dart';
import '../core/safe_change_notifier.dart';
import '../core/supabase_config.dart';

class LeetCodeProvider extends ChangeNotifier with SafeChangeNotifier {
  final SupabaseService _supabaseService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final Map<String, LeetCodeStats> _statsCache = {};
  Map<String, LeetCodeStats> get statsCache => _statsCache;

  final Set<String> _pendingRequests = {}; // Request deduplication

  LeetCodeProvider(this._supabaseService);

  // Clean username helper
  String _cleanUsername(String username) {
    if (username.contains('/')) {
      final parts = username.split('/');
      return parts.lastWhere((element) => element.isNotEmpty);
    }
    return username.trim();
  }

  /// Returns a short, log-safe error summary.
  /// Truncates HTML error pages (e.g. Cloudflare 525 SSL pages) so they don't
  /// flood the log with hundreds of lines of markup.
  String _sanitizeError(Object e) {
    final s = e.toString();
    if (s.contains('<!DOCTYPE') ||
        s.contains('<html') ||
        s.contains('</html>')) {
      // Extract just the first meaningful line / code from the HTML
      final codeMatch = RegExp(r'Error code (\d+)').firstMatch(s);
      final code = codeMatch?.group(1);
      return code != null
          ? 'HTTP $code (SSL/network error – Supabase temporarily unreachable)'
          : 'HTML error page received (Supabase temporarily unreachable)';
    }
    return s.length > 300 ? '${s.substring(0, 300)}…' : s;
  }

  LeetCodeStats? getCachedStats(String username) {
    final clean = _cleanUsername(username);
    return _statsCache[clean];
  }

  Future<LeetCodeStats?> fetchStats(String rawUsername) async {
    final username = _cleanUsername(rawUsername);
    if (username.isEmpty) return null;

    // 1. Return memory cache immediately if available
    if (_statsCache.containsKey(username)) {
      final stats = _statsCache[username]!;
      // If data is fresh (< 12 hour), don't refetch
      if (DateTime.now().difference(stats.lastUpdated).inHours < 12) {
        return stats;
      }
    }

    // 2. Prevent duplicate in-flight requests
    if (_pendingRequests.contains(username)) {
      return _statsCache[username]; // Return what we have, or null
    }
    _pendingRequests.add(username);

    // Only set loading if we don't have cache to show
    if (!_statsCache.containsKey(username)) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // 3. Try to fetch from Supabase (Offline Support)
      if (!_statsCache.containsKey(username)) {
        final dbData = await _supabaseService.client
            .from('leetcode_stats')
            .select()
            .eq('username', username)
            .maybeSingle();

        if (dbData != null) {
          final stats = LeetCodeStats.fromMap(dbData);
          _statsCache[username] = stats;

          // If Supabase data is fresh (<12 hours), stop here
          if (DateTime.now().difference(stats.lastUpdated).inHours < 12) {
            _pendingRequests.remove(username);
            _isLoading = false;
            notifyListeners();
            return stats;
          }
          // We got stale data from DB, show it while we fetch fresh
          notifyListeners();
        }
      }

      // 4. Sync fresh stats via the trusted server endpoint (Network) - it
      // re-derives the caller's own leetcode_username, fetches from LeetCode
      // itself, and writes to `leetcode_stats` with a privileged server key.
      // The client never talks to leetcode.com/alfa-leetcode-api directly and
      // never writes to `leetcode_stats` itself (RLS blocks that write now).
      final stats = await _syncViaTrustedApi(username);

      // 5. Update Cache
      if (stats != null) {
        _statsCache[username] = stats;
      }

      _pendingRequests.remove(username);
      _isLoading = false;
      notifyListeners();
      return stats ?? _statsCache[username];
    } catch (e) {
      debugPrint('Error fetching LeetCode stats: ${_sanitizeError(e)}');
      _pendingRequests.remove(username);
      _isLoading = false;
      notifyListeners();
      return _statsCache[username]; // Return stale/offline data
    }
  }

  /// Syncs the caller's own LeetCode stats via the trusted server endpoint.
  ///
  /// SECURITY: the client used to fetch straight from leetcode.com/graphql
  /// and alfa-leetcode-api.onrender.com and then upsert the result into
  /// `leetcode_stats` using the student's own anon-key session — a modified
  /// client could write fabricated numbers to inflate its own readiness
  /// score. `POST /api/user/leetcode-sync` re-derives the caller's own
  /// `leetcode_username` server-side, fetches LeetCode stats itself, and
  /// writes with a privileged server key; direct client INSERT/UPDATE on
  /// `leetcode_stats` is now revoked at the RLS level (see
  /// supabase/migrations/58_lock_down_leetcode_writes.sql), so this is the
  /// only way stats can be refreshed.
  Future<LeetCodeStats?> _syncViaTrustedApi(String username) async {
    try {
      final token = _supabaseService.client.auth.currentSession?.accessToken;
      if (token == null) {
        debugPrint('[LeetCode] ⚠️  No session, skipping sync for $username');
        return null;
      }

      final response = await http.post(
        Uri.parse('${SupabaseConfig.appApiUrl}/api/user/leetcode-sync'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      final decoded = decodeTrustedJson(
        response,
        fallbackMessage: 'LeetCode stats could not be refreshed.',
      );

      final rawStats = decoded['stats'];
      if (rawStats is! Map) {
        debugPrint('[LeetCode] ⚠️  Sync response missing stats for $username');
        return null;
      }

      final statsMap = Map<String, dynamic>.from(rawStats);
      statsMap['username'] = username;
      final stats = LeetCodeStats.fromMap(statsMap);

      debugPrint(
          '[LeetCode] ✅ [Trusted sync] $username: ${stats.totalSolved} problems (E:${stats.easySolved} M:${stats.mediumSolved} H:${stats.hardSolved})');

      return stats;
    } on TrustedApiException catch (e) {
      debugPrint('[LeetCode] ⚠️  Trusted sync failed for $username: $e');
      return null;
    } catch (e) {
      debugPrint('[LeetCode] ⚠️  Trusted sync exception for $username: $e');
      return null;
    }
  }

  /// Fetch Problem of the Day
  Future<Map<String, dynamic>?> fetchPOTD() async {
    try {
      const url = 'https://leetcode.com/graphql';
      const query = '''
        query questionOfToday {
          activeDailyCodingChallengeQuestion {
            date
            link
            question {
              title
              titleSlug
              difficulty
              acRate
            }
          }
        }
      ''';

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Referer': 'https://leetcode.com',
              'Origin': 'https://leetcode.com',
            },
            body: jsonEncode({'query': query}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final question = data['data']?['activeDailyCodingChallengeQuestion'];
        if (question != null) {
          final q = question['question'];
          return {
            'title': q['title'],
            'link': question['link'],
            'difficulty': q['difficulty'],
            'acRate':
                '${double.parse(q['acRate'].toString()).toStringAsFixed(1)}%'
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('[LeetCode] Error fetching POTD: $e');
      return null;
    }
  }

  /// Check for POTD and send notification if enabled
  Future<void> checkAndNotifyPOTD() async {
    try {
      // Check if already notified/checked today
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month}-${now.day}';
      const lastCheckKey = 'leetcode_potd_last_check_date';

      if (prefs.getString(lastCheckKey) == todayStr) {
        debugPrint('[LeetCode] Already checked POTD for today ($todayStr)');
        return;
      }

      // Check user preference using the centralized service
      final shouldSend =
          await NotificationService().shouldSendNotification('leetcode');
      if (!shouldSend) {
        return; // Notifications disabled
      }

      final potd = await fetchPOTD();
      if (potd != null) {
        await NotificationService().showNotification(
          id: 9999, // Fixed ID for daily updates
          title: 'LeetCode POTD: ${potd['title']}',
          body: '${potd['difficulty']} • AR: ${potd['acRate']}',
          type: NotificationType.leetcode,
          payload: 'https://leetcode.com${potd['link']}',
          uniqueKey: 'potd_$todayStr', // Deduplicate by date
        );

        // Mark as done for today
        await prefs.setString(lastCheckKey, todayStr);
        debugPrint('[LeetCode] POTD Notification Sent: ${potd['title']}');
      }
    } catch (e) {
      debugPrint('[LeetCode] Failed to notify POTD: $e');
    }
  }

  /// Resets all cached LeetCode state. Called on sign-out so a second
  /// student on the same device never sees the previous student's cached
  /// stats before their own sync completes.
  void resetForSignOut() {
    _statsCache.clear();
    _pendingRequests.clear();
    _isLoading = false;
    notifyListeners();
  }
}
