import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Enterprise domain model for Placement Team Member.
/// Populated 100% dynamically from Supabase database.
class PlacementTeamMember {
  final int sNo;
  final String id;
  final String rollNo;
  final String name;
  final bool isLeader;

  const PlacementTeamMember({
    required this.sNo,
    required this.id,
    required this.rollNo,
    required this.name,
    this.isLeader = false,
  });

  factory PlacementTeamMember.fromJson(Map<String, dynamic> json, {int index = 1}) {
    return PlacementTeamMember(
      sNo: (json['s_no'] as num?)?.toInt() ?? index,
      id: json['id']?.toString() ?? '',
      rollNo: json['roll_no']?.toString() ?? json['reg_no']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isLeader: json['is_leader'] == true || (json['roles'] is Map && json['roles']['isTeamLeader'] == true),
    );
  }
}

/// Enterprise domain model for Placement Team.
/// Populated 100% dynamically from Supabase database.
class PlacementTeam {
  final String id;
  final int teamNumber;
  final String teamCode;
  final String teamName;
  final String? objective;
  final int targetSize;
  final List<PlacementTeamMember> members;

  const PlacementTeam({
    required this.id,
    required this.teamNumber,
    required this.teamCode,
    required this.teamName,
    this.objective,
    required this.targetSize,
    required this.members,
  });

  PlacementTeamMember? get leader =>
      members.firstWhere((m) => m.isLeader, orElse: () => members.isNotEmpty ? members.first : const PlacementTeamMember(sNo: 1, id: '', rollNo: '', name: ''));

  factory PlacementTeam.fromJson(Map<String, dynamic> json) {
    final code = json['team_code']?.toString() ?? '';
    final numDigits = code.replaceAll(RegExp(r'[^0-9]'), '');
    final teamNum = int.tryParse(numDigits) ?? 1;

    final rawMembers = (json['members'] as List? ?? const [])
        .whereType<Map>()
        .toList();

    final members = <PlacementTeamMember>[];
    for (int i = 0; i < rawMembers.length; i++) {
      members.add(PlacementTeamMember.fromJson(Map<String, dynamic>.from(rawMembers[i]), index: i + 1));
    }

    return PlacementTeam(
      id: json['id']?.toString() ?? '',
      teamNumber: teamNum,
      teamCode: code.isNotEmpty ? code : 'T${teamNum.toString().padLeft(2, '0')}',
      teamName: json['team_name']?.toString() ?? 'Team $teamNum',
      objective: json['objective']?.toString(),
      targetSize: (json['target_size'] as num?)?.toInt() ?? members.length,
      members: members,
    );
  }
}

/// Repository responsible for fetching placement squads dynamically from Supabase.
/// Never stores or ships hardcoded student records in application code.
class PlacementTeamsRepository {
  static final PlacementTeamsRepository _instance = PlacementTeamsRepository._internal();
  factory PlacementTeamsRepository() => _instance;
  PlacementTeamsRepository._internal();

  List<PlacementTeam>? _cachedTeams;
  DateTime? _lastFetched;

  /// Fetches all placement teams for the batch dynamically from Supabase database
  Future<List<PlacementTeam>> getTeams({String batchCode = '26MX', bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedTeams != null && _lastFetched != null &&
        DateTime.now().difference(_lastFetched!) < const Duration(minutes: 5)) {
      return _cachedTeams!;
    }

    try {
      // 1. Primary path: Call get_batch_placement_teams RPC
      final response = await Supabase.instance.client.rpc(
        'get_batch_placement_teams',
        params: {'p_batch_code': batchCode},
      );

      if (response is List && response.isNotEmpty) {
        final teams = response
            .map((row) => PlacementTeam.fromJson(Map<String, dynamic>.from(row as Map)))
            .toList();
        _cachedTeams = teams;
        _lastFetched = DateTime.now();
        return teams;
      }
    } catch (e) {
      debugPrint('[PlacementTeamsRepo] RPC error: $e');
    }

    // 2. Direct database query fallback
    try {
      final batchRow = await Supabase.instance.client
          .from('batches')
          .select('id')
          .eq('batch_code', batchCode)
          .maybeSingle();

      if (batchRow != null) {
        final batchId = batchRow['id'] as String;
        final teamsData = await Supabase.instance.client
            .from('teams')
            .select('id, team_code, team_name, objective, target_size, team_leader_id')
            .eq('batch_id', batchId)
            .order('team_code');

        if (teamsData is List && teamsData.isNotEmpty) {
          final usersData = await Supabase.instance.client
              .from('users')
              .select('id, name, reg_no, team_uuid, roles');

          final membersByTeamUuid = <String, List<PlacementTeamMember>>{};
          if (usersData is List) {
            for (final u in usersData) {
              final teamUuid = u['team_uuid']?.toString();
              if (teamUuid != null) {
                final roles = u['roles'] as Map?;
                membersByTeamUuid.putIfAbsent(teamUuid, () => []).add(
                  PlacementTeamMember(
                    sNo: (membersByTeamUuid[teamUuid]?.length ?? 0) + 1,
                    id: u['id']?.toString() ?? '',
                    rollNo: u['reg_no']?.toString() ?? '',
                    name: u['name']?.toString() ?? '',
                    isLeader: roles?['isTeamLeader'] == true,
                  ),
                );
              }
            }
          }

          final teams = teamsData.map((t) {
            final teamId = t['id'] as String;
            final members = membersByTeamUuid[teamId] ?? const [];
            return PlacementTeam(
              id: teamId,
              teamNumber: int.tryParse((t['team_code']?.toString() ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ?? 1,
              teamCode: t['team_code']?.toString() ?? '',
              teamName: t['team_name']?.toString() ?? '',
              objective: t['objective']?.toString(),
              targetSize: (t['target_size'] as num?)?.toInt() ?? members.length,
              members: members,
            );
          }).toList();

          if (teams.isNotEmpty) {
            _cachedTeams = teams;
            _lastFetched = DateTime.now();
            return teams;
          }
        }
      }
    } catch (e) {
      debugPrint('[PlacementTeamsRepo] Direct table error: $e');
    }

    return _cachedTeams ?? const [];
  }

  /// Finds the squad for a given student roll number dynamically
  Future<PlacementTeam?> findTeamForRollNo(String rollNo, {String batchCode = '26MX'}) async {
    final clean = rollNo.trim().toUpperCase();
    final teams = await getTeams(batchCode: batchCode);
    for (final team in teams) {
      if (team.members.any((m) => m.rollNo.toUpperCase() == clean)) {
        return team;
      }
    }
    return null;
  }

  void clearCache() {
    _cachedTeams = null;
    _lastFetched = null;
  }
}
