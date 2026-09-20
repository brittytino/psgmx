import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leetcode_stats.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../models/notification.dart';
import '../core/safe_change_notifier.dart';

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

      // 4. Fetch from LeetCode API (Network) - it will save to DB internally
      final stats = await _fetchFromLeetCodeApi(username);

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

  Future<LeetCodeStats?> _fetchFromLeetCodeApi(String username) async {
    // Try official LeetCode GraphQL API first (even on Web, trying to use CORS bypass or proxy if available)
    // Users requested to prioritize this over Alpha API to avoid rate limits
    final stats = await _fetchFromOfficialApi(username);
    if (stats != null) return stats;

    // Fallback to Alpha API if official fails
    return await _fetchFromAlphaApi(username);
  }

  Future<LeetCodeStats?> _fetchFromOfficialApi(String username) async {
    try {
      // Use official LeetCode GraphQL API with User's requested query
      const url = 'https://leetcode.com/graphql';

      const query = '''
        query getUserProfile(\$username: String!) {
          matchedUser(username: \$username) {
            username
            profile {
              realName
              aboutMe
              userAvatar
              ranking
            }
            submitStatsGlobal {
              acSubmissionNum {
                difficulty
                count
              }
            }
            languageProblemCount {
              languageName
              problemsSolved
            }
            userCalendar {
              submissionCalendar
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
            body: jsonEncode({
              'query': query,
              'variables': {'username': username}
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body['errors'] != null) {
          debugPrint(
              '[LeetCode] ⚠️  GraphQL Error for $username: ${body['errors'][0]['message']}');
          return null;
        }

        final matchedUser = body['data']?['matchedUser'];
        if (matchedUser == null) {
          debugPrint(
              '[LeetCode] ⚠️  User not found in official API: $username');
          return null;
        }

        // Parse stats
        final submitStats =
            matchedUser['submitStatsGlobal']['acSubmissionNum'] as List;
        int totalSolved = 0;
        int easySolved = 0;
        int mediumSolved = 0;
        int hardSolved = 0;

        for (var stat in submitStats) {
          final difficulty = stat['difficulty'] as String;
          final count = stat['count'] as int;

          switch (difficulty) {
            case 'All':
              totalSolved = count;
              break;
            case 'Easy':
              easySolved = count;
              break;
            case 'Medium':
              mediumSolved = count;
              break;
            case 'Hard':
              hardSolved = count;
              break;
          }
        }

        final ranking = matchedUser['profile']['ranking'] as int? ?? 0;
        final profilePicture = matchedUser['profile']['userAvatar'] as String?;

        // Calculate weekly score
        int weeklyScore = 0;
        // User query structure has submissionCalendar inside userCalendar
        final submissionCalendarStr =
            matchedUser['userCalendar']?['submissionCalendar'] as String?;

        if (submissionCalendarStr != null && submissionCalendarStr.isNotEmpty) {
          try {
            final submissionCalendar =
                jsonDecode(submissionCalendarStr) as Map<String, dynamic>;
            final now = DateTime.now();
            final sevenDaysAgo = now.subtract(const Duration(days: 7));

            submissionCalendar.forEach((timestampStr, count) {
              try {
                final timestamp = int.tryParse(timestampStr);
                if (timestamp != null) {
                  final date =
                      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
                  if (date.isAfter(sevenDaysAgo)) {
                    weeklyScore += (count as int? ?? 0);
                  }
                }
              } catch (e) {
                // Skip
              }
            });
          } catch (e) {
            debugPrint('[LeetCode] ⚠️  Calendar parse error for $username');
          }
        }

        debugPrint(
            '[LeetCode] ✅ [Official API] $username: $totalSolved problems (E:$easySolved M:$mediumSolved H:$hardSolved)');

        final stats = LeetCodeStats(
          username: username,
          profilePicture: profilePicture,
          totalSolved: totalSolved,
          easySolved: easySolved,
          mediumSolved: mediumSolved,
          hardSolved: hardSolved,
          ranking: ranking,
          weeklyScore: weeklyScore,
          lastUpdated: DateTime.now(),
        );

        await _saveToDatabase(stats);
        return stats;
      } else {
        debugPrint(
            '[LeetCode] ⚠️  Official API returned ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('[LeetCode] ⚠️  Official API Exception: $e');
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

  Future<LeetCodeStats?> _fetchFromAlphaApi(String username) async {
    try {
      // Fallback to Alpha API
      final alphaUrl =
          'https://alfa-leetcode-api.onrender.com/userProfile/$username';

      final response = await http.get(
        Uri.parse(alphaUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['errors'] != null || data['status'] == 'error') {
          debugPrint('[LeetCode] ❌ User not found: $username');
          return null;
        }

        final totalSolved = data['totalSolved'] as int? ?? 0;
        final easySolved = data['easySolved'] as int? ?? 0;
        final mediumSolved = data['mediumSolved'] as int? ?? 0;
        final hardSolved = data['hardSolved'] as int? ?? 0;
        final ranking = data['ranking'] as int? ?? 0;

        // Calculate weekly score
        int weeklyScore = 0;
        final submissionCalendar = data['submissionCalendar'];
        if (submissionCalendar != null && submissionCalendar is Map) {
          final now = DateTime.now();
          final sevenDaysAgo = now.subtract(const Duration(days: 7));

          submissionCalendar.forEach((timestampStr, count) {
            try {
              final timestamp = int.tryParse(timestampStr.toString());
              if (timestamp != null) {
                final date =
                    DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
                if (date.isAfter(sevenDaysAgo)) {
                  weeklyScore += (count as int? ?? 0);
                }
              }
            } catch (e) {
              // Skip
            }
          });
        }

        debugPrint('[LeetCode] ✅ [Alpha API] $username: $totalSolved problems');

        final stats = LeetCodeStats(
          username: username,
          totalSolved: totalSolved,
          easySolved: easySolved,
          mediumSolved: mediumSolved,
          hardSolved: hardSolved,
          ranking: ranking,
          weeklyScore: weeklyScore,
          lastUpdated: DateTime.now(),
        );

        // Save to database
        await _saveToDatabase(stats);
        return stats;
      } else if (response.statusCode == 429) {
        debugPrint('[LeetCode] ⏳ Alpha API Rate Limit 429 for $username');
        // If specific 429, we should propagate this signal ideally, but returning null
        // with the error log allows the background loop to catch failures and backoff.
        return null;
      } else {
        debugPrint('[LeetCode] ❌ Alpha API returned ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('[LeetCode] ❌ Alpha API Exception: $e');
      return null;
    }
  }

  Future<void> _saveToDatabase(LeetCodeStats stats) async {
    try {
      await _supabaseService.client
          .from('leetcode_stats')
          .upsert(stats.toMap());
      debugPrint('[LeetCode] 💾 Saved ${stats.username} to database');
    } catch (e) {
      debugPrint('[LeetCode] ❌ Failed to save ${stats.username} to DB: $e');
      rethrow; // Let caller handle
    }
  }
}
