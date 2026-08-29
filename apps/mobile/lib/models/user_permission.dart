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

  /// Can schedule preparation sessions (clinics, mocks, workshops).
  schedulePreparationSessions,

  /// Can mark preparation-session participation.
  /// For Team Leaders this is scoped to their own team by convention
  /// (enforced in the service layer, not in this enum).
  markPreparationParticipation,

  /// Can publish preparation quests and manage the question bank.
  publishQuests,

  /// Can publish general announcements.
  publishAnnouncements,

  /// Can create and edit preparation tracks.
  managePreparationTracks,

  /// Can triage interview-pattern submissions before faculty review.
  moderateInterviewPatterns,

  /// Can read batch-wide analytics, leaderboards, and attendance summaries.
  viewBatchAnalytics,

  /// Can view and interact with the AI mentor.
  viewAiMentor,
}

extension UserPermissionExtension on UserPermission {
  /// The exact string stored in the `user_permissions.permission_key` column.
  String get dbKey {
    switch (this) {
      case UserPermission.manageMembers:
        return 'manage_members';
      case UserPermission.configureTeams:
        return 'configure_teams';
      case UserPermission.schedulePreparationSessions:
        return 'schedule_preparation_sessions';
      case UserPermission.markPreparationParticipation:
        return 'mark_preparation_participation';
      case UserPermission.publishQuests:
        return 'publish_quests';
      case UserPermission.publishAnnouncements:
        return 'publish_announcements';
      case UserPermission.managePreparationTracks:
        return 'manage_preparation_tracks';
      case UserPermission.moderateInterviewPatterns:
        return 'moderate_interview_patterns';
      case UserPermission.viewBatchAnalytics:
        return 'view_batch_analytics';
      case UserPermission.viewAiMentor:
        return 'view_ai_mentor';
    }
  }

  static UserPermission? fromDbKey(String key) {
    const legacyAliases = {
      'schedule_placement_sessions': UserPermission.schedulePreparationSessions,
      'mark_placement_attendance': UserPermission.markPreparationParticipation,
      'publish_tasks': UserPermission.publishQuests,
      'manage_company_records': UserPermission.managePreparationTracks,
      'moderate_placement_log': UserPermission.moderateInterviewPatterns,
    };
    if (legacyAliases.containsKey(key)) return legacyAliases[key];
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
      case UserPermission.schedulePreparationSessions:
        return 'Schedule Preparation Sessions';
      case UserPermission.markPreparationParticipation:
        return 'Mark Preparation Participation';
      case UserPermission.publishQuests:
        return 'Publish Quests';
      case UserPermission.publishAnnouncements:
        return 'Publish Announcements';
      case UserPermission.managePreparationTracks:
        return 'Manage Preparation Tracks';
      case UserPermission.moderateInterviewPatterns:
        return 'Moderate Interview Patterns';
      case UserPermission.viewBatchAnalytics:
        return 'View Batch Analytics';
      case UserPermission.viewAiMentor:
        return 'View AI Mentor';
    }
  }
}

/// The default permission set granted to a Placement Rep.
const Set<UserPermission> kPlacementRepPermissions = {
  UserPermission.manageMembers,
  UserPermission.configureTeams,
  UserPermission.schedulePreparationSessions,
  UserPermission.markPreparationParticipation,
  UserPermission.publishQuests,
  UserPermission.managePreparationTracks,
  UserPermission.moderateInterviewPatterns,
  UserPermission.viewBatchAnalytics,
  UserPermission.publishAnnouncements,
  UserPermission.viewAiMentor,
};

/// Default permissions for a Team Leader (only attendance marking by default).
const Set<UserPermission> kTeamLeaderPermissions = {
  UserPermission.markPreparationParticipation,
  UserPermission.viewAiMentor,
};
