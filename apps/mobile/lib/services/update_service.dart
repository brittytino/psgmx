import 'dart:io' show Platform;

import 'package:flutter/foundation.dart'
    show ChangeNotifier, debugPrint, kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_config.dart';
import '../models/release_note.dart';
import '../core/utils/version_comparator.dart';

/// Update Service for PSGMX App
///
/// Responsibilities:
/// - Fetch [AppConfig] from `app_config` Supabase table
/// - Fetch [ReleaseNote] entries from `app_release_notes` table
/// - Determine update status (up-to-date / optional / force / emergency)
/// - Persist "last seen version" so What's New screen shows once per version
/// - Open platform download URLs
class UpdateService extends ChangeNotifier {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ─────────────────────────────────────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────────────────────────────────────

  AppConfig? _config;
  String? _currentVersion;
  UpdateStatus? _updateStatus;
  bool _hasCheckedThisSession = false;
  bool _hasShownOptionalUpdateThisSession = false;
  bool _isInitialized = false;
  DateTime? _lastCheckTime;

  /// Release notes fetched for the current version (shown in What's New)
  List<ReleaseNote> _pendingReleaseNotes = [];

  /// Whether What's New screen should appear (new version installed)
  bool _shouldShowWhatsNew = false;

  // SharedPreferences keys
  static const String _emergencyBlockCacheKey = 'psgmx_emergency_block_cached';
  static const String _lastSeenVersionKey = 'psgmx_last_seen_version';

  // ─────────────────────────────────────────────────────────────────────────
  // GETTERS
  // ─────────────────────────────────────────────────────────────────────────

  AppConfig? get config => _config;
  String? get currentVersion => _currentVersion;
  UpdateStatus? get updateStatus => _updateStatus;
  bool get isInitialized => _isInitialized;
  List<ReleaseNote> get pendingReleaseNotes => List.unmodifiable(_pendingReleaseNotes);

  /// True when the app has been updated and the user hasn't seen the new release notes yet.
  bool get shouldShowWhatsNew => _shouldShowWhatsNew;

  /// Whether we should show the optional update dialog (once per session)
  bool get shouldShowOptionalUpdate =>
      _updateStatus == UpdateStatus.optionalUpdateAvailable &&
      !_hasShownOptionalUpdateThisSession;

  /// Whether we should show force update screen
  bool get shouldShowForceUpdate =>
      _updateStatus == UpdateStatus.forceUpdateRequired;

  /// Whether we should show emergency block screen
  bool get shouldShowEmergencyBlock =>
      _updateStatus == UpdateStatus.emergencyBlocked;

  /// Check if app needs any blocking update intervention
  bool get needsUpdateIntervention =>
      shouldShowEmergencyBlock || shouldShowForceUpdate;

  /// Feature rollout eligibility. Empty targeting lists fail-open so a
  /// freshly migrated production app is never accidentally locked out.
  bool isRolloutEnabledFor({required String userId, String? batchId}) {
    final value = _config;
    if (value == null || value.rolloutStage == 'full') return true;
    if (value.pilotUserIds.contains(userId)) return true;
    if (value.rolloutStage == 'batch' &&
        batchId != null &&
        value.enabledBatchIds.contains(batchId)) {
      return true;
    }
    return value.pilotUserIds.isEmpty && value.enabledBatchIds.isEmpty;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ─────────────────────────────────────────────────────────────────────────

  /// Initialise the update service.
  /// Call once early in app startup, after Supabase is ready.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
      debugPrint('📱 [UpdateService] Current version: $_currentVersion');

      await Future.wait([
        checkForUpdates(),
        _checkAndLoadReleaseNotes(),
      ]);

      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ [UpdateService] Initialization error: $e');
      _updateStatus = UpdateStatus.upToDate;
      _isInitialized = true;
    }

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPDATE CHECK
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetch [AppConfig] from Supabase and resolve [UpdateStatus].
  /// Respects a 5-minute minimum interval between checks (unless [forceCheck]).
  Future<UpdateStatus> checkForUpdates({bool forceCheck = false}) async {
    if (!forceCheck &&
        _hasCheckedThisSession &&
        _lastCheckTime != null &&
        DateTime.now().difference(_lastCheckTime!) < const Duration(minutes: 5)) {
      return _updateStatus ?? UpdateStatus.upToDate;
    }

    try {
      debugPrint('🔍 [UpdateService] Checking for updates...');

      final response =
          await _supabase.from('app_config').select().limit(1).maybeSingle();

      if (response != null) {
        _config = AppConfig.fromMap(response);
        debugPrint('📦 [UpdateService] Config: $_config');
        if (_config!.emergencyBlock) {
          await _cacheEmergencyBlockState(true);
        }
      } else {
        _config = AppConfig.defaultConfig();
        debugPrint('⚠️ [UpdateService] No config in DB, using defaults');
      }

      _updateStatus = _determineUpdateStatus();
      _hasCheckedThisSession = true;
      _lastCheckTime = DateTime.now();

      debugPrint('📊 [UpdateService] Status: $_updateStatus');
    } catch (e) {
      debugPrint('❌ [UpdateService] Error fetching config: $e');

      final cachedEmergency = await _getCachedEmergencyBlockState();
      if (cachedEmergency) {
        _updateStatus = UpdateStatus.emergencyBlocked;
        _config = AppConfig.defaultConfig();
      } else {
        _updateStatus = UpdateStatus.upToDate;
        _config = AppConfig.defaultConfig();
      }
    }

    notifyListeners();
    return _updateStatus ?? UpdateStatus.upToDate;
  }

  UpdateStatus _determineUpdateStatus() {
    if (_config == null || _currentVersion == null) {
      return UpdateStatus.upToDate;
    }
    return VersionComparator.getUpdateStatus(
      currentVersion: _currentVersion!,
      minRequiredVersion: _config!.minRequiredVersion,
      latestVersion: _config!.latestVersion,
      forceUpdate: _config!.forceUpdate,
      emergencyBlock: _config!.emergencyBlock,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WHAT'S NEW / RELEASE NOTES
  // ─────────────────────────────────────────────────────────────────────────

  /// Compares current version with last-seen version stored in prefs.
  /// If the app has been updated, loads release notes and sets [shouldShowWhatsNew].
  Future<void> _checkAndLoadReleaseNotes() async {
    if (_currentVersion == null) return;

    try {
      final lastSeen = await _getLastSeenVersion();

      // First install — nothing to show; just persist current version
      if (lastSeen == null) {
        await _persistCurrentVersion();
        return;
      }

      // Same version — nothing new
      if (lastSeen == _currentVersion) return;

      // Version changed — fetch release notes between lastSeen and current
      final notes = await _fetchReleaseNotes(
        sinceVersion: lastSeen,
        upToVersion: _currentVersion!,
      );

      if (notes.isNotEmpty) {
        _pendingReleaseNotes = notes;
        _shouldShowWhatsNew = true;
        debugPrint(
            '🎉 [UpdateService] ${notes.length} release note(s) to show for $_currentVersion');
      }
    } catch (e) {
      debugPrint('⚠️ [UpdateService] Could not load release notes: $e');
      // Fail silently — don't block the app
    }
  }

  /// Fetch release notes from Supabase newer than [sinceVersion].
  Future<List<ReleaseNote>> _fetchReleaseNotes({
    required String sinceVersion,
    required String upToVersion,
  }) async {
    final response = await _supabase
        .from('app_release_notes')
        .select()
        .eq('is_published', true)
        .inFilter('platform', ['all', _currentPlatform()])
        .order('release_date', ascending: false);

    final allNotes = (response as List)
        .map((r) => ReleaseNote.fromMap(r as Map<String, dynamic>))
        .toList();

    // Show notes for versions newer than what user last saw, up to current
    final since = SemanticVersion.tryParse(sinceVersion);
    final current = SemanticVersion.tryParse(upToVersion);

    if (since == null || current == null) return allNotes.take(3).toList();

    return allNotes.where((note) {
      final v = SemanticVersion.tryParse(note.version);
      if (v == null) return false;
      return v > since && v <= current;
    }).toList();
  }

  String _currentPlatform() {
    if (kIsWeb) return 'all';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'all';
  }

  /// Dismiss the What's New screen and persist current version.
  Future<void> dismissWhatsNew() async {
    _shouldShowWhatsNew = false;
    _pendingReleaseNotes = [];
    await _persistCurrentVersion();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // USER ACTIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Mark optional update as dismissed for this session
  void dismissOptionalUpdate() {
    _hasShownOptionalUpdateThisSession = true;
    notifyListeners();
  }

  /// Open the download/store URL for the current platform
  Future<bool> openUpdateUrl() async {
    if (_config == null) return false;

    String? url;

    if (!kIsWeb) {
      if (Platform.isAndroid && _config!.androidDownloadUrl != null) {
        url = _config!.androidDownloadUrl;
      } else if (Platform.isIOS && _config!.iosDownloadUrl != null) {
        url = _config!.iosDownloadUrl;
      }
    }

    if (url == null || url.isEmpty) {
      url = _config!.githubReleaseUrl;
    }

    if (url.isEmpty) {
      url = 'https://github.com/brittytino/psgmx/releases/latest';
    }

    try {
      final uri = Uri.parse(url);
      bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) launched = await launchUrl(uri);
      return launched;
    } catch (e) {
      debugPrint('❌ [UpdateService] Error opening URL: $e');
      try {
        return await launchUrl(Uri.parse(url));
      } catch (_) {
        return false;
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PERSISTENCE
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _cacheEmergencyBlockState(bool blocked) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_emergencyBlockCacheKey, blocked);
    } catch (e) {
      debugPrint('⚠️ [UpdateService] Error caching emergency state: $e');
    }
  }

  Future<bool> _getCachedEmergencyBlockState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_emergencyBlockCacheKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Clear emergency block cache (call when block is lifted in DB)
  Future<void> clearEmergencyBlockCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_emergencyBlockCacheKey);
    } catch (e) {
      debugPrint('⚠️ [UpdateService] Error clearing emergency cache: $e');
    }
  }

  Future<String?> _getLastSeenVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastSeenVersionKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistCurrentVersion() async {
    try {
      if (_currentVersion == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSeenVersionKey, _currentVersion!);
    } catch (e) {
      debugPrint('⚠️ [UpdateService] Error persisting version: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RESET (testing / development)
  // ─────────────────────────────────────────────────────────────────────────

  void resetSession() {
    _hasCheckedThisSession = false;
    _hasShownOptionalUpdateThisSession = false;
    _lastCheckTime = null;
    notifyListeners();
  }

  Future<void> forceRefresh() async {
    _hasCheckedThisSession = false;
    await checkForUpdates(forceCheck: true);
  }

  /// Debug helper: clear last-seen version so What's New triggers next launch
  Future<void> debugResetWhatsNew() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSeenVersionKey);
    _shouldShowWhatsNew = false;
    _pendingReleaseNotes = [];
    notifyListeners();
  }
}
