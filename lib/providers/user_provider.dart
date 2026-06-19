import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../models/user_permission.dart';
import '../services/auth_service.dart';
import '../services/batch_service.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService;
  late final BatchService _batchService;
  late final PermissionService _permissionService;
  AppUser? _currentUser;
  bool _isLoading = true;
  bool _initComplete = false;

  // Simulation Mode
  UserRole? _simulatedRole;

  UserProvider({required AuthService authService})
      : _authService = authService {
    _batchService = BatchService(Supabase.instance.client);
    _permissionService = PermissionService(Supabase.instance.client);
    _init();
  }

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get initComplete => _initComplete;

  bool get isSimulating => _simulatedRole != null;
  UserRole? get simulatedRole => _simulatedRole;

  /// Returns true if the current user holds [permission].
  bool hasPermission(UserPermission permission) =>
      _currentUser?.hasPermission(permission) ?? false;

  AuthService get authService => _authService;

  bool get isStudent => _simulatedRole != null
      ? _simulatedRole == UserRole.student
      : (_currentUser?.isStudent ?? false);

  bool get isTeamLeader => _simulatedRole != null
      ? _simulatedRole == UserRole.teamLeader
      : (_currentUser?.isTeamLeader ?? false);

  bool get isCoordinator => _simulatedRole != null
      ? _simulatedRole == UserRole.coordinator
      : (_currentUser?.isCoordinator ?? false);

  bool get isPlacementRep => _simulatedRole != null
      ? _simulatedRole == UserRole.placementRep
      : (_currentUser?.isPlacementRep ?? false);

  bool get hasActualAdminAccess => _currentUser?.hasAdminAccess ?? false;
  bool get isActualPlacementRep => _currentUser?.isPlacementRep ?? false;

  void setSimulationRole(UserRole? role) {
    if (!isActualPlacementRep) return;
    _simulatedRole = role;
    notifyListeners();
  }

  void retryInit() {
    _init();
  }

  void _init() {
    debugPrint('[UserProvider] Initializing...');
    _checkAuthStateOnce();
  }

  Future<void> _checkAuthStateOnce() async {
    try {
      final supabaseUser = _authService.currentUser;
      if (supabaseUser != null) {
        _currentUser = await _loadFullProfile(supabaseUser.id);
        if (_currentUser != null) {
          _scheduleBirthdayNotificationIfNeeded();
        }
      } else {
        _currentUser = null;
      }
    } catch (e) {
      _currentUser = null;
    } finally {
      _isLoading = false;
      _initComplete = true;
      notifyListeners();
      _listenToAuthStateChanges();
    }
  }

  void _listenToAuthStateChanges() {
    _authService.authStateChanges.listen(
      (AuthState authState) async {
        debugPrint('[UserProvider] Auth state changed: ${authState.event}');
        final supabaseUser = authState.session?.user;

        if (supabaseUser != null) {
          debugPrint('[UserProvider] User logged in: ${supabaseUser.email}');
          try {
            _currentUser = await _loadFullProfile(supabaseUser.id);
            if (_currentUser != null) {
              debugPrint('[UserProvider] ✅ Profile loaded: ${_currentUser!.name}');
              _scheduleBirthdayNotificationIfNeeded();
            } else {
              debugPrint('[UserProvider] ⚠️ Profile is null after fetch');
            }
          } catch (e) {
            debugPrint('[UserProvider] ❌ Error fetching profile: $e');
            _currentUser = null;
          }
        } else {
          debugPrint('[UserProvider] User logged out');
          _currentUser = null;
        }
        notifyListeners();
        debugPrint('[UserProvider] notifyListeners() called, currentUser: ${_currentUser?.email}');
      },
      onError: (e) {
        debugPrint('[UserProvider] Auth stream error: $e');
      },
    );
  }

  /// Loads the full user profile including batch assignment and permission flags.
  ///
  /// If the user has no [batchId] yet (first login), parses the batch from
  /// their roll number and assigns it automatically.
  Future<AppUser?> _loadFullProfile(String userId) async {
    AppUser? user = await _authService.getUserProfile(userId);
    if (user == null) return null;

    // Auto-assign batch on first login (batchId is null)
    if (user.batchId == null && user.regNo.isNotEmpty) {
      try {
        final batch = await _batchService.batchFromRollNumber(user.regNo);
        if (batch != null) {
          await _batchService.assignUserToBatch(userId, batch.id);
          user = user.copyWith(batchId: batch.id);
          debugPrint('[UserProvider] Auto-assigned to batch ${batch.batchCode}');
        }
      } catch (e) {
        debugPrint('[UserProvider] Batch auto-assign error: $e');
      }
    }

    // Load permission flags
    try {
      final permissions = await _permissionService.fetchUserPermissions(userId);
      user = user?.copyWith(permissionFlags: permissions);
    } catch (e) {
      debugPrint('[UserProvider] Permission load error: $e');
    }

    return user;
  }

  /// Request OTP
  Future<bool> requestOtp({required String email}) async {
    try {
      final success = await _authService.sendOtpToEmail(email);
      return success;
    } catch (e) {
      rethrow;
    }
  }

  /// Verify OTP
  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      await _authService.verifyOtp(email: email, otp: otp);
      // Auth state listener will pick up the new session and load profile
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDob(DateTime newDob) async {
    if (_currentUser == null) return;
    try {
      final dobStr = newDob.toIso8601String().split('T')[0];
      await Supabase.instance.client
          .from('users')
          .update({'dob': dobStr}).eq('id', _currentUser!.uid);

      _currentUser = _currentUser!.copyWith(dob: newDob);
      notifyListeners();
      _scheduleBirthdayNotificationIfNeeded();
    } catch (e) {
      rethrow;
    }
  }

  /// Saves or clears the custom eCampus portal password for the current user.
  ///
  /// Pass a non-empty [password] to store it.  Pass `null` or an empty string
  /// to clear it (the backend will then fall back to the DOB-derived password).
  ///
  /// The password is stored server-side only and is NEVER read back to the app.
  /// Only [ecampusPasswordSet] (a boolean flag) is updated in the local model.
  Future<void> updateEcampusPassword(String? password) async {
    if (_currentUser == null) return;
    final isSet = password != null && password.trim().isNotEmpty;
    await Supabase.instance.client.from('users').update({
      'ecampus_password': isSet ? password.trim() : null,
      'ecampus_password_set': isSet,
    }).eq('id', _currentUser!.uid);
    _currentUser = _currentUser!.copyWith(ecampusPasswordSet: isSet);
    notifyListeners();
  }

  Future<void> updateBirthdayNotification(bool enabled) async {
    if (_currentUser == null) return;
    try {
      await Supabase.instance.client
          .from('users')
          .update({'birthday_notifications_enabled': enabled}).eq(
              'id', _currentUser!.uid);

      _currentUser =
          _currentUser!.copyWith(birthdayNotificationsEnabled: enabled);
      notifyListeners();
      _scheduleBirthdayNotificationIfNeeded();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateLeetCodeUsername(String username) async {
    if (_currentUser == null) return;
    try {
      // Use RPC to ensure atomic update across users, whitelist, and stats tables
      await Supabase.instance.client.rpc(
        'update_leetcode_username_unified',
        params: {
          'p_user_id': _currentUser!.uid,
          'p_new_username': username,
        },
      );

      _currentUser = _currentUser!.copyWith(leetcodeUsername: username);
      notifyListeners();
      
      // Force refresh stats for the new username
      // We can notify LeetCodeProvider if needed, but the periodic fetcher will catch it
    } catch (e) {
      debugPrint('[UserProvider] Error updating LeetCode username: $e');
      rethrow;
    }
  }

  Future<void> updateLeetCodeNotification(bool enabled) async {
    if (_currentUser == null) return;
    try {
      await Supabase.instance.client
          .from('users')
          .update({'leetcode_notifications_enabled': enabled}).eq(
              'id', _currentUser!.uid);

      _currentUser =
          _currentUser!.copyWith(leetcodeNotificationsEnabled: enabled);
      notifyListeners();

      if (enabled) {
        await NotificationService().scheduleLeetCodeReminders();
      } else {
        await NotificationService().cancelLeetCodeReminders();
      }
    } catch (e) {
      rethrow;
    }
  }

  void _scheduleBirthdayNotificationIfNeeded() {
    if (_currentUser == null) return;
    try {
      if (_currentUser!.dob != null) {
        NotificationService().scheduleBirthdayNotification(
          dob: _currentUser!.dob!,
          userName: _currentUser!.name,
          enabled: _currentUser!.birthdayNotificationsEnabled,
        );
      }
    } catch (e) {
      debugPrint('[UserProvider] Error scheduling birthday notification: $e');
    }
  }

  // ========================================
  // A2: NOTIFICATION PREFERENCES PERSISTENCE
  // ========================================

  /// Update task reminders preference (persisted to DB)
  Future<void> updateTaskRemindersEnabled(bool enabled) async {
    if (_currentUser == null) return;
    try {
      await Supabase.instance.client.from('users').update(
          {'task_reminders_enabled': enabled}).eq('id', _currentUser!.uid);

      _currentUser = _currentUser!.copyWith(taskRemindersEnabled: enabled);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Update attendance alerts preference (persisted to DB)
  Future<void> updateAttendanceAlertsEnabled(bool enabled) async {
    if (_currentUser == null) return;
    try {
      await Supabase.instance.client.from('users').update(
          {'attendance_alerts_enabled': enabled}).eq('id', _currentUser!.uid);

      _currentUser = _currentUser!.copyWith(attendanceAlertsEnabled: enabled);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Update announcements preference (persisted to DB)
  Future<void> updateAnnouncementsEnabled(bool enabled) async {
    if (_currentUser == null) return;
    try {
      await Supabase.instance.client.from('users').update(
          {'announcements_enabled': enabled}).eq('id', _currentUser!.uid);

      _currentUser = _currentUser!.copyWith(announcementsEnabled: enabled);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Update all notification preferences at once
  Future<void> updateAllNotificationPreferences({
    bool? taskReminders,
    bool? attendanceAlerts,
    bool? announcements,
    bool? leetcodeNotifications,
    bool? birthdayNotifications,
  }) async {
    if (_currentUser == null) return;
    try {
      final updates = <String, dynamic>{};

      if (taskReminders != null) {
        updates['task_reminders_enabled'] = taskReminders;
      }
      if (attendanceAlerts != null) {
        updates['attendance_alerts_enabled'] = attendanceAlerts;
      }
      if (announcements != null) {
        updates['announcements_enabled'] = announcements;
      }
      if (leetcodeNotifications != null) {
        updates['leetcode_notifications_enabled'] = leetcodeNotifications;
      }
      if (birthdayNotifications != null) {
        updates['birthday_notifications_enabled'] = birthdayNotifications;
      }

      if (updates.isEmpty) return;

      await Supabase.instance.client
          .from('users')
          .update(updates)
          .eq('id', _currentUser!.uid);

      _currentUser = _currentUser!.copyWith(
        taskRemindersEnabled:
            taskReminders ?? _currentUser!.taskRemindersEnabled,
        attendanceAlertsEnabled:
            attendanceAlerts ?? _currentUser!.attendanceAlertsEnabled,
        announcementsEnabled:
            announcements ?? _currentUser!.announcementsEnabled,
        leetcodeNotificationsEnabled:
            leetcodeNotifications ?? _currentUser!.leetcodeNotificationsEnabled,
        birthdayNotificationsEnabled:
            birthdayNotifications ?? _currentUser!.birthdayNotificationsEnabled,
      );
      notifyListeners();

      // Handle notification service updates
      if (leetcodeNotifications != null) {
        if (leetcodeNotifications) {
          await NotificationService().scheduleLeetCodeReminders();
        } else {
          await NotificationService().cancelLeetCodeReminders();
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
