import 'user_permission.dart';

enum UserRole { student, teamLeader, coordinator, placementRep }

class UserRoles {
  final bool isStudent;
  final bool isTeamLeader;
  final bool isCoordinator;
  final bool isPlacementRep;

  const UserRoles({
    this.isStudent = true,
    this.isTeamLeader = false,
    this.isCoordinator = false,
    this.isPlacementRep = false,
  });

  factory UserRoles.fromJson(Map<String, dynamic> json) {
    return UserRoles(
      isStudent: json['isStudent'] as bool? ?? true,
      isTeamLeader: json['isTeamLeader'] as bool? ?? false,
      isCoordinator: json['isCoordinator'] as bool? ?? false,
      isPlacementRep: json['isPlacementRep'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isStudent': isStudent,
      'isTeamLeader': isTeamLeader,
      'isCoordinator': isCoordinator,
      'isPlacementRep': isPlacementRep,
    };
  }

  UserRoles copyWith({
    bool? isStudent,
    bool? isTeamLeader,
    bool? isCoordinator,
    bool? isPlacementRep,
  }) {
    return UserRoles(
      isStudent: isStudent ?? this.isStudent,
      isTeamLeader: isTeamLeader ?? this.isTeamLeader,
      isCoordinator: isCoordinator ?? this.isCoordinator,
      isPlacementRep: isPlacementRep ?? this.isPlacementRep,
    );
  }

  bool hasAnyAdminRole() {
    return isPlacementRep || isCoordinator || isTeamLeader;
  }
}

class AppUser {
  final String uid;
  final String email;
  final String regNo;
  final String name;
  final String? avatarUrl;
  final String? gender;
  final String? teamId;
  final String batch;
  final UserRoles roles;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── v4: Batch system + dynamic permissions ────────────────────────────────
  /// UUID FK to the `batches` table row this student belongs to.
  final String? batchId;

  /// UI-facing role label (e.g. "Placement Rep", "Coordinator", "Team Leader",
  /// "Student"). Cosmetic only — actual access is controlled by [permissionFlags].
  final String roleLabel;

  /// Set of capability flags fetched from `user_permissions`.
  /// Use [hasPermission] for clean guard checks in the UI.
  final Set<UserPermission> permissionFlags;
  
  /// Base database role ('student', 'alumni', 'faculty', 'hod')
  final String baseRole;
  
  /// Whether the user's batch has graduated
  final bool isGraduatedBatch;

  // ── Existing fields ───────────────────────────────────────────────────────
  final String? leetcodeUsername;
  final DateTime? dob;
  final bool birthdayNotificationsEnabled;
  final bool leetcodeNotificationsEnabled;

  // A2: Additional notification preferences (persisted to DB)
  final bool taskRemindersEnabled;
  final bool attendanceAlertsEnabled;
  final bool announcementsEnabled;

  /// True when the student has saved a custom eCampus portal password.
  /// The actual password is NEVER stored in this model – only this flag
  /// is read from the DB so the UI can show the correct status.
  final bool ecampusPasswordSet;

  /// True when the student has completed the 3-question calibration flow.
  final bool onboardingComplete;

  AppUser({
    required this.uid,
    required this.email,
    required this.regNo,
    required this.name,
    this.avatarUrl,
    this.gender,
    this.teamId,
    required this.batch,
    required this.roles,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.batchId,
    this.roleLabel = 'Student',
    Set<UserPermission>? permissionFlags,
    this.leetcodeUsername,
    this.dob,
    this.birthdayNotificationsEnabled = true,
    this.leetcodeNotificationsEnabled = true,
    this.taskRemindersEnabled = true,
    this.attendanceAlertsEnabled = true,
    this.announcementsEnabled = true,
    this.ecampusPasswordSet = false,
    this.onboardingComplete = false,
    this.baseRole = 'student',
    this.isGraduatedBatch = false,
  })  : permissionFlags = permissionFlags ?? const {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Returns true if this user holds the given permission flag.
  bool hasPermission(UserPermission permission) =>
      permissionFlags.contains(permission);

  // Convenience getters
  bool get isStudent => roles.isStudent;
  bool get isTeamLeader => roles.isTeamLeader;
  bool get isCoordinator => roles.isCoordinator;
  bool get isPlacementRep => roles.isPlacementRep;
  bool get hasAdminAccess => roles.hasAnyAdminRole();
  bool get isAlumni => baseRole == 'alumni';

  factory AppUser.fromMap(Map<String, dynamic> data) {
    var rolesData = data['roles'];
    rolesData ??= const UserRoles().toJson();

    final roles = rolesData is Map<String, dynamic>
        ? UserRoles.fromJson(rolesData)
        : const UserRoles();

    // Parse permission flags if they were joined into the response
    final Set<UserPermission> permissions = {};
    final rawPerms = data['permissions'];
    if (rawPerms is List) {
      for (final p in rawPerms) {
        final key = p is Map ? p['permission_key'] as String? : p as String?;
        if (key != null) {
          final perm = UserPermissionExtension.fromDbKey(key);
          if (perm != null) permissions.add(perm);
        }
      }
    }

    return AppUser(
      uid: data['id'] ?? '',
      email: data['email'] ?? '',
      regNo: data['roll_no'] ?? data['reg_no'] ?? '',
      name: data['full_name'] ?? data['name'] as String? ?? 'Unknown',
      avatarUrl: data['avatar_url'] as String?,
      gender: data['gender'] as String?,
      teamId: data['team_id'] as String?,
      batch: data['batch'] as String? ?? 'G1',
      roles: roles,
      batchId: data['batch_id'] as String?,
      roleLabel: data['role_label'] as String? ?? 'Student',
      baseRole: data['role'] as String? ?? 'student',
      permissionFlags: permissions,
      isGraduatedBatch: data['batches']?['status'] == 'graduated',
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : null,
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
          : null,
      leetcodeUsername: data['leetcode_username'],
      dob: data['dob'] != null
          ? DateTime.tryParse(data['dob'].toString())
          : null,
      birthdayNotificationsEnabled:
          data['birthday_notifications_enabled'] ?? true,
      leetcodeNotificationsEnabled:
          data['leetcode_notifications_enabled'] ?? true,
      taskRemindersEnabled: data['task_reminders_enabled'] ?? true,
      attendanceAlertsEnabled: data['attendance_alerts_enabled'] ?? true,
      announcementsEnabled: data['announcements_enabled'] ?? true,
      ecampusPasswordSet: data['ecampus_password_set'] ?? false,
      onboardingComplete: data['onboarding_complete'] ?? false,
    );
  }

  // Alias for fromMap
  factory AppUser.fromJson(Map<String, dynamic> data) => AppUser.fromMap(data);

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'email': email,
      'roll_no': regNo,
      'full_name': name,
      'avatar_url': avatarUrl,
      'gender': gender,
      'team_id': teamId,
      'batch': batch,
      'roles': roles.toJson(),
      'batch_id': batchId,
      'role_label': roleLabel,
      'role': baseRole,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'leetcode_username': leetcodeUsername,
      'dob': dob?.toIso8601String().split('T')[0],
      'birthday_notifications_enabled': birthdayNotificationsEnabled,
      'leetcode_notifications_enabled': leetcodeNotificationsEnabled,
      'task_reminders_enabled': taskRemindersEnabled,
      'attendance_alerts_enabled': attendanceAlertsEnabled,
      'announcements_enabled': announcementsEnabled,
      'ecampus_password_set': ecampusPasswordSet,
      'onboarding_complete': onboardingComplete,
    };
  }

  AppUser copyWith({
    String? name,
    String? avatarUrl,
    String? gender,
    UserRoles? roles,
    String? batchId,
    String? roleLabel,
    Set<UserPermission>? permissionFlags,
    String? leetcodeUsername,
    DateTime? dob,
    bool? birthdayNotificationsEnabled,
    bool? leetcodeNotificationsEnabled,
    bool? taskRemindersEnabled,
    bool? attendanceAlertsEnabled,
    bool? announcementsEnabled,
    bool? ecampusPasswordSet,
    bool? onboardingComplete,
    String? teamId,
    String? baseRole,
    bool? isGraduatedBatch,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      regNo: regNo,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      teamId: teamId ?? this.teamId,
      batch: batch,
      roles: roles ?? this.roles,
      batchId: batchId ?? this.batchId,
      roleLabel: roleLabel ?? this.roleLabel,
      baseRole: baseRole ?? this.baseRole,
      isGraduatedBatch: isGraduatedBatch ?? this.isGraduatedBatch,
      permissionFlags: permissionFlags ?? this.permissionFlags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      leetcodeUsername: leetcodeUsername ?? this.leetcodeUsername,
      dob: dob ?? this.dob,
      birthdayNotificationsEnabled:
          birthdayNotificationsEnabled ?? this.birthdayNotificationsEnabled,
      leetcodeNotificationsEnabled:
          leetcodeNotificationsEnabled ?? this.leetcodeNotificationsEnabled,
      taskRemindersEnabled: taskRemindersEnabled ?? this.taskRemindersEnabled,
      attendanceAlertsEnabled:
          attendanceAlertsEnabled ?? this.attendanceAlertsEnabled,
      announcementsEnabled: announcementsEnabled ?? this.announcementsEnabled,
      ecampusPasswordSet: ecampusPasswordSet ?? this.ecampusPasswordSet,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }
}
