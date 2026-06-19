/// All per-user capability flags used by the PSGMX dynamic permission model.
///
/// Role *labels* (Placement Rep, Coordinator, Team Leader, Student) are
/// cosmetic UI strings only. Actual access control is driven exclusively by
/// which of these flags a user holds in the `user_permissions` table.
enum UserPermission {
  /// Can grant/revoke permissions and set role labels for anyone in the batch.
  manageMembers,

  /// Can set team size, run auto-distribution, and move students between teams.
  configureTeams,

  /// Can schedule new placement sessions (classes, mock sessions, workshops).
  schedulePlacementSessions,

  /// Can mark placement-session attendance.
  /// For Team Leaders this is scoped to their own team by convention
  /// (enforced in the service layer, not in this enum).
  markPlacementAttendance,

  /// Can publish daily tasks (LeetCode + core subject) and manage question bank.
  publishTasks,

  /// Can create and edit company records in the Placement Log.
  manageCompanyRecords,

  /// Can moderate (edit/hide) experience entries written by students.
  moderatePlacementLog,

  /// Can read batch-wide analytics, leaderboards, and attendance summaries.
  viewBatchAnalytics,
}

extension UserPermissionExtension on UserPermission {
  /// The exact string stored in the `user_permissions.permission_key` column.
  String get dbKey {
    switch (this) {
      case UserPermission.manageMembers:
        return 'manage_members';
      case UserPermission.configureTeams:
        return 'configure_teams';
      case UserPermission.schedulePlacementSessions:
        return 'schedule_placement_sessions';
      case UserPermission.markPlacementAttendance:
        return 'mark_placement_attendance';
      case UserPermission.publishTasks:
        return 'publish_tasks';
      case UserPermission.manageCompanyRecords:
        return 'manage_company_records';
      case UserPermission.moderatePlacementLog:
        return 'moderate_placement_log';
      case UserPermission.viewBatchAnalytics:
        return 'view_batch_analytics';
    }
  }

  static UserPermission? fromDbKey(String key) {
    for (final p in UserPermission.values) {
      if (p.dbKey == key) return p;
    }
    return null;
  }

  /// Human-readable label for use in admin UI.
  String get displayName {
    switch (this) {
      case UserPermission.manageMembers:
        return 'Manage Members';
      case UserPermission.configureTeams:
        return 'Configure Teams';
      case UserPermission.schedulePlacementSessions:
        return 'Schedule Placement Sessions';
      case UserPermission.markPlacementAttendance:
        return 'Mark Placement Attendance';
      case UserPermission.publishTasks:
        return 'Publish Tasks';
      case UserPermission.manageCompanyRecords:
        return 'Manage Company Records';
      case UserPermission.moderatePlacementLog:
        return 'Moderate Placement Log';
      case UserPermission.viewBatchAnalytics:
        return 'View Batch Analytics';
    }
  }
}

/// The default permission set granted to a Placement Rep.
const Set<UserPermission> kPlacementRepPermissions = {
  UserPermission.manageMembers,
  UserPermission.configureTeams,
  UserPermission.schedulePlacementSessions,
  UserPermission.markPlacementAttendance,
  UserPermission.publishTasks,
  UserPermission.manageCompanyRecords,
  UserPermission.moderatePlacementLog,
  UserPermission.viewBatchAnalytics,
};

/// Default permissions for a Team Leader (only attendance marking by default).
const Set<UserPermission> kTeamLeaderPermissions = {
  UserPermission.markPlacementAttendance,
};
