import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/batch.dart';
import '../models/team.dart';
import '../models/app_user.dart';

/// Handles all batch-level data operations:
/// - Fetching active batches
/// - Auto-assigning a new user to their batch from their roll number
/// - Team CRUD and auto-distribution
class BatchService {
  final SupabaseClient _supabase;

  BatchService(this._supabase);

  // ── Batches ────────────────────────────────────────────────────────────────

  /// Returns the two currently active batches (senior + junior).
  Future<List<Batch>> fetchActiveBatches() async {
    try {
      final response = await _supabase
          .from('batches')
          .select()
          .inFilter('status', ['active_senior', 'active_junior'])
          .order('start_year');
      return (response as List).map((r) => Batch.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[BatchService] fetchActiveBatches error: $e');
      rethrow;
    }
  }

  /// Returns all batches (including graduated) for display in analytics/history.
  Future<List<Batch>> fetchAllBatches() async {
    final response =
        await _supabase.from('batches').select().order('start_year');
    return (response as List).map((r) => Batch.fromMap(r)).toList();
  }

  /// Looks up the [Batch] matching the batch code embedded in [rollNo].
  /// Returns null if the batch code cannot be parsed or no matching batch exists.
  Future<Batch?> batchFromRollNumber(String rollNo) async {
    final code = Batch.parseBatchCodeFromRollNo(rollNo);
    if (code == null) {
      debugPrint('[BatchService] Could not parse batch code from roll: $rollNo');
      return null;
    }
    try {
      final row = await _supabase
          .from('batches')
          .select()
          .eq('batch_code', code)
          .maybeSingle();
      return row != null ? Batch.fromMap(row) : null;
    } catch (e) {
      debugPrint('[BatchService] batchFromRollNumber error: $e');
      return null;
    }
  }

  /// Assigns [userId] to the batch identified by [batchId].
  /// Called on first sign-in after OTP verification.
  Future<void> assignUserToBatch(String userId, String batchId) async {
    await _supabase
        .from('users')
        .update({'batch_id': batchId}).eq('id', userId);
    debugPrint('[BatchService] Assigned user $userId to batch $batchId');
  }

  // ── Teams ──────────────────────────────────────────────────────────────────

  /// Fetches all teams for a batch, ordered by name.
  Future<List<Team>> fetchTeamsForBatch(String batchId) async {
    final response = await _supabase
        .from('teams')
        .select()
        .eq('batch_id', batchId)
        .order('team_name');
    return (response as List).map((r) => Team.fromMap(r)).toList();
  }

  /// Fetches a single team with its members populated.
  Future<Team> fetchTeamWithMembers(String teamId) async {
    final teamRow =
        await _supabase.from('teams').select().eq('id', teamId).single();
    final team = Team.fromMap(teamRow);

    final membersResponse = await _supabase
        .from('users')
        .select()
        .eq('team_id', teamId)
        .order('reg_no');
    final members =
        (membersResponse as List).map((r) => AppUser.fromMap(r)).toList();

    return team.copyWith(members: members);
  }

  /// Auto-distributes all students in [batchId] into teams of [targetSize].
  /// Creates ⌈student_count / targetSize⌉ teams and assigns students evenly.
  /// Requires [configureTeams] permission (enforced by RLS).
  Future<void> autoDistributeTeams({
    required String batchId,
    required int targetSize,
  }) async {
    assert(targetSize >= 3 && targetSize <= 20, 'Invalid team size');

    // Fetch all students in the batch (no team filter — full redistribution)
    final students = await _supabase
        .from('users')
        .select('id, reg_no')
        .eq('batch_id', batchId)
        .order('reg_no');

    final studentList = students as List;
    if (studentList.isEmpty) return;

    final teamCount = (studentList.length / targetSize).ceil();
    debugPrint('[BatchService] Creating $teamCount teams of ~$targetSize students');

    // Delete existing teams for a clean redistribution
    await _supabase.from('teams').delete().eq('batch_id', batchId);

    // Create new teams
    final teamInserts = List.generate(teamCount, (i) => {
          'batch_id': batchId,
          'team_name': 'Team ${i + 1}',
          'target_size': targetSize,
        });

    final createdTeams =
        await _supabase.from('teams').insert(teamInserts).select();

    // Assign students round-robin across teams
    final updates = <Future>[];
    for (var i = 0; i < studentList.length; i++) {
      final team = (createdTeams as List)[i % teamCount];
      updates.add(
        _supabase
            .from('users')
            .update({'team_id': team['id']})
            .eq('id', studentList[i]['id']),
      );
    }
    await Future.wait(updates);
    debugPrint('[BatchService] Auto-distribution complete');

    await _supabase.from('audit_logs').insert({
      'actor_id': null, // system action — no actor
      'action': 'AUTO_DISTRIBUTE_TEAMS',
      'entity_type': 'teams',
      'entity_id': null,
      'metadata': {
        'batch_id': batchId,
        'team_count': teamCount,
        'target_size': targetSize,
        'student_count': studentList.length,
      },
    });
  }

  /// Moves a single student to a different team.
  /// Requires [configureTeams] permission (enforced by RLS).
  Future<void> moveStudentToTeam({
    required String studentId,
    required String targetTeamId,
    String? movedBy,
  }) async {
    await _supabase
        .from('users')
        .update({'team_id': targetTeamId}).eq('id', studentId);

    if (movedBy != null) {
      await _supabase.from('audit_logs').insert({
        'actor_id': movedBy,
        'action': 'MOVE_STUDENT_TO_TEAM',
        'entity_type': 'users',
        'entity_id': null,
        'metadata': {'student_id': studentId, 'target_team_id': targetTeamId},
      });
    }
  }

  /// Assigns a Team Leader to a team.
  /// Requires [configureTeams] permission.
  Future<void> assignTeamLeader({
    required String teamId,
    required String leaderId,
    String? assignedBy,
  }) async {
    await _supabase
        .from('teams')
        .update({'team_leader_id': leaderId}).eq('id', teamId);

    if (assignedBy != null) {
      await _supabase.from('audit_logs').insert({
        'actor_id': assignedBy,
        'action': 'ASSIGN_TEAM_LEADER',
        'entity_type': 'teams',
        'entity_id': null,
        'metadata': {'team_id': teamId, 'leader_id': leaderId},
      });
    }
  }
}
