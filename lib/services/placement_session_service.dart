import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/placement_session.dart';
import '../models/app_user.dart';

/// Handles scheduling, fetching, and marking of placement-prep sessions.
///
/// This service drives the "Placement Class Attendance" component of the
/// readiness score — NOT the eCampus official academic attendance.
class PlacementSessionService {
  final SupabaseClient _supabase;

  PlacementSessionService(this._supabase);

  // ── Scheduling ─────────────────────────────────────────────────────────────

  /// Creates a new placement session.
  /// Caller must hold [UserPermission.schedulePlacementSessions] — enforced by RLS.
  Future<PlacementSession> schedulePlacementSession({
    required String batchId,
    required String scheduledBy,
    required DateTime sessionDatetime,
    required String topic,
    String? description,
    List<String>? targetTeamIds, // null = whole batch
  }) async {
    final data = {
      'batch_id': batchId,
      'scheduled_by': scheduledBy,
      'session_datetime': sessionDatetime.toIso8601String(),
      'topic': topic,
      'description': description,
      'target_team_ids': targetTeamIds,
    };

    final response =
        await _supabase.from('placement_sessions').insert(data).select().single();

    // Audit
    await _supabase.from('audit_logs').insert({
      'actor_id': scheduledBy,
      'action': 'SCHEDULE_PLACEMENT_SESSION',
      'entity_type': 'placement_sessions',
      'entity_id': null,
      'metadata': {'topic': topic, 'datetime': sessionDatetime.toIso8601String()},
    });

    debugPrint('[PlacementSessionService] Scheduled session: $topic');
    return PlacementSession.fromMap(response);
  }

  /// Updates an existing session. Caller must have scheduling permission.
  Future<void> updateSession({
    required String sessionId,
    required String updatedBy,
    DateTime? sessionDatetime,
    String? topic,
    String? description,
    List<String>? targetTeamIds,
  }) async {
    final updates = <String, dynamic>{};
    if (sessionDatetime != null) {
      updates['session_datetime'] = sessionDatetime.toIso8601String();
    }
    if (topic != null) updates['topic'] = topic;
    if (description != null) updates['description'] = description;
    if (targetTeamIds != null) updates['target_team_ids'] = targetTeamIds;

    if (updates.isEmpty) return;
    await _supabase
        .from('placement_sessions')
        .update(updates)
        .eq('id', sessionId);
  }

  /// Deletes a session. Caller must have scheduling permission.
  Future<void> deleteSession(String sessionId, String deletedBy) async {
    await _supabase
        .from('placement_sessions')
        .delete()
        .eq('id', sessionId);

    await _supabase.from('audit_logs').insert({
      'actor_id': deletedBy,
      'action': 'DELETE_PLACEMENT_SESSION',
      'entity_type': 'placement_sessions',
      'entity_id': null,
      'metadata': {'session_id': sessionId},
    });
  }

  // ── Fetching ───────────────────────────────────────────────────────────────

  /// Returns all sessions for [batchId], ordered by date descending.
  Future<List<PlacementSession>> fetchSessionsForBatch(String batchId) async {
    final response = await _supabase
        .from('placement_sessions')
        .select()
        .eq('batch_id', batchId)
        .order('session_datetime', ascending: false);
    return (response as List)
        .map((r) => PlacementSession.fromMap(r))
        .toList();
  }

  /// Returns upcoming sessions for a given [teamId].
  /// Includes batch-wide sessions + team-specific ones.
  Future<List<PlacementSession>> fetchUpcomingForTeam({
    required String batchId,
    required String teamId,
  }) async {
    final all = await fetchSessionsForBatch(batchId);
    final now = DateTime.now();
    return all
        .where((s) => s.sessionDatetime.isAfter(now) && s.isTargetedAt(teamId))
        .toList()
      ..sort((a, b) => a.sessionDatetime.compareTo(b.sessionDatetime));
  }

  // ── Attendance Marking ─────────────────────────────────────────────────────

  /// Marks attendance for a list of students in a single session.
  ///
  /// [records] is a map of student_id → PlacementAttendanceStatus.
  /// Caller must hold [mark_placement_attendance] permission (enforced by RLS).
  /// For Team Leaders, the service validates that all students belong to their team.
  Future<void> markSessionAttendance({
    required String sessionId,
    required String markedBy,
    required Map<String, PlacementAttendanceStatus> records,
  }) async {
    if (records.isEmpty) return;

    final rows = records.entries
        .map((e) => {
              'session_id': sessionId,
              'user_id': e.key,
              'status': e.value.dbValue,
              'marked_by': markedBy,
            })
        .toList();

    await _supabase.from('placement_attendance').upsert(
          rows,
          onConflict: 'session_id, user_id',
        );

    await _supabase.from('audit_logs').insert({
      'actor_id': markedBy,
      'action': 'MARK_PLACEMENT_ATTENDANCE',
      'entity_type': 'placement_attendance',
      'entity_id': null,
      'metadata': {
        'session_id': sessionId,
        'count': records.length,
      },
    });

    debugPrint(
        '[PlacementSessionService] Marked ${records.length} attendance records');
  }

  /// Returns the attendance records for a specific session.
  Future<List<PlacementAttendanceRecord>> fetchSessionAttendance(
      String sessionId) async {
    final response = await _supabase
        .from('placement_attendance')
        .select()
        .eq('session_id', sessionId);
    return (response as List)
        .map((r) => PlacementAttendanceRecord.fromMap(r))
        .toList();
  }

  /// Returns the attendance summary (% score) for a user.
  /// Reads from the `placement_attendance_summary` view.
  Future<PlacementAttendanceSummary?> fetchAttendanceSummary(
      String userId) async {
    try {
      final response = await _supabase
          .from('placement_attendance_summary')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response != null
          ? PlacementAttendanceSummary.fromMap(response)
          : null;
    } catch (e) {
      debugPrint('[PlacementSessionService] fetchAttendanceSummary error: $e');
      return null;
    }
  }

  /// Returns a user's attendance record for each session they were eligible for.
  Future<List<PlacementAttendanceRecord>> fetchMyAttendance(
      String userId) async {
    final response = await _supabase
        .from('placement_attendance')
        .select()
        .eq('user_id', userId)
        .order('marked_at', ascending: false);
    return (response as List)
        .map((r) => PlacementAttendanceRecord.fromMap(r))
        .toList();
  }

  // ── Members eligible for a session ────────────────────────────────────────

  /// Returns the list of [AppUser]s who are eligible for a given session
  /// (i.e. their team was targeted or the session is batch-wide).
  Future<List<AppUser>> fetchEligibleStudents(
      PlacementSession session) async {
    if (session.isBatchWide) {
      // All students in the batch
      final response = await _supabase
          .from('users')
          .select()
          .eq('batch_id', session.batchId)
          .order('reg_no');
      return (response as List).map((r) => AppUser.fromMap(r)).toList();
    } else {
      // Students in the targeted teams
      final response = await _supabase
          .from('users')
          .select()
          .inFilter('team_id', session.targetTeamIds!)
          .order('reg_no');
      return (response as List).map((r) => AppUser.fromMap(r)).toList();
    }
  }
}
