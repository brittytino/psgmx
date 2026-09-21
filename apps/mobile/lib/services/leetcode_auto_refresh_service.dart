import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/leetcode_provider.dart';
import '../services/supabase_service.dart';

/// Daily Auto-Refresh Service for LeetCode Stats
/// This runs in the background and automatically refreshes stats once per day
class LeetCodeAutoRefreshService {
  final LeetCodeProvider _leetCodeProvider;
  final SupabaseService _supabaseService;
  Timer? _dailyTimer;

  static const String _lastRefreshKeyPrefix = 'leetcode_last_refresh_timestamp';

  LeetCodeAutoRefreshService(this._leetCodeProvider, this._supabaseService);

  /// Start the daily auto-refresh timer
  void start() {
    // Cancel existing timer if any
    _dailyTimer?.cancel();

    // Check immediately if refresh is needed
    _checkAndRefreshIfNeeded();

    // Set up periodic check every 6 hours (will only refresh if 24h passed)
    _dailyTimer = Timer.periodic(const Duration(hours: 6), (_) {
      _checkAndRefreshIfNeeded();
    });

    debugPrint('[AutoRefresh] Daily LeetCode refresh service started');
  }

  /// Stop the auto-refresh timer
  void stop() {
    _dailyTimer?.cancel();
    _dailyTimer = null;
    debugPrint('[AutoRefresh] Daily refresh service stopped');
  }

  /// Check if refresh is needed and execute
  Future<void> _checkAndRefreshIfNeeded() async {
    try {
      // Check if user is logged in first — the cooldown key is namespaced
      // per user, so we need the uid before we can even look it up.
      final currentUser = _supabaseService.client.auth.currentUser;
      if (currentUser == null) {
        debugPrint('[AutoRefresh] No user logged in, skipping auto-refresh');
        return;
      }

      // Get last refresh timestamp from local storage (per-user key — a
      // second student on the same device must not inherit the first
      // student's cooldown, mirroring the `calibrated_${uid}` pattern used
      // elsewhere in the codebase).
      final lastRefresh = await _getLastRefreshTimestamp(currentUser.id);

      final now = DateTime.now();
      if (lastRefresh == null || now.difference(lastRefresh).inHours >= 24) {
        debugPrint('[AutoRefresh] 24 hours passed, starting auto-refresh...');
        await _performAutoRefresh();
      } else {
        final hoursRemaining = 24 - now.difference(lastRefresh).inHours;
        debugPrint(
            '[AutoRefresh] Refresh not needed yet. Next refresh in ~$hoursRemaining hours');
      }
    } catch (e) {
      debugPrint('[AutoRefresh] Error checking refresh: $e');
    }
  }

  /// Perform the actual refresh
  Future<void> _performAutoRefresh() async {
    try {
      debugPrint('[AutoRefresh] Starting private LeetCode refresh...');

      // Check if user is logged in first
      final currentUser = _supabaseService.client.auth.currentUser;
      if (currentUser == null) {
        debugPrint('[AutoRefresh] No user logged in, skipping auto-refresh');
        return;
      }

      final profileRows = await _supabaseService.client.rpc('get_my_profile');
      final profile = profileRows is List
          ? (profileRows.isEmpty ? null : profileRows.first)
          : profileRows;
      final username = profile is Map
          ? profile['leetcode_username']?.toString().trim()
          : null;
      if (username == null || username.isEmpty) {
        debugPrint('[AutoRefresh] No LeetCode username configured, skipping');
        return;
      }

      await _leetCodeProvider.fetchStats(username);

      // Save the refresh timestamp (namespaced to this user)
      await _saveLastRefreshTimestamp(currentUser.id, DateTime.now());

      debugPrint('[AutoRefresh] ✅ Auto-refresh completed successfully');
    } catch (e) {
      debugPrint('[AutoRefresh] Error during auto-refresh: $e');
    }
  }

  String _lastRefreshKeyFor(String userId) => '${_lastRefreshKeyPrefix}_$userId';

  /// Get last refresh timestamp from SharedPreferences
  Future<DateTime?> _getLastRefreshTimestamp(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastRefreshKeyFor(userId));

      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
    } catch (e) {
      debugPrint('[AutoRefresh] Could not get last refresh timestamp: $e');
    }
    return null;
  }

  /// Save last refresh timestamp to SharedPreferences
  Future<void> _saveLastRefreshTimestamp(
      String userId, DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _lastRefreshKeyFor(userId), timestamp.toIso8601String());
      debugPrint(
          '[AutoRefresh] Saved refresh timestamp: ${timestamp.toIso8601String()}');
    } catch (e) {
      debugPrint('[AutoRefresh] Could not save last refresh timestamp: $e');
    }
  }

  /// Force refresh (for manual trigger)
  Future<void> forceRefresh() async {
    debugPrint('[AutoRefresh] Force refresh triggered');
    await _performAutoRefresh();
  }

  /// Dispose resources
  void dispose() {
    stop();
  }
}
