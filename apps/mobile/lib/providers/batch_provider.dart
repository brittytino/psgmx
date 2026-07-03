import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/batch.dart';
import '../models/team.dart';
import '../models/app_user.dart';
import '../services/batch_service.dart';

/// State management for batch and team data.
///
/// Consumed by [TeamManagementScreen] and any widget that needs to display
/// the current batch status (e.g., the admin dashboard).
class BatchProvider with ChangeNotifier {
  final BatchService _service;

  BatchProvider() : _service = BatchService(Supabase.instance.client);

  // ── State ──────────────────────────────────────────────────────────────────

  List<Batch> _activeBatches = [];
  List<Team> _teamsForBatch = [];
  /// Members loaded for a specific team (for the detail view).
  List<AppUser> _teamMembers = [];

  bool _isLoadingBatches = false;
  bool _isLoadingTeams = false;
  bool _isRunningDistribution = false;
  String? _error;

  String? _selectedBatchId;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<Batch> get activeBatches => _activeBatches;
  List<Team> get teamsForBatch => _teamsForBatch;
  List<AppUser> get teamMembers => _teamMembers;

  bool get isLoadingBatches => _isLoadingBatches;
  bool get isLoadingTeams => _isLoadingTeams;
  bool get isRunningDistribution => _isRunningDistribution;
  String? get error => _error;
  String? get selectedBatchId => _selectedBatchId;

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> loadActiveBatches() async {
    _isLoadingBatches = true;
    _error = null;
    notifyListeners();

    try {
      _activeBatches = await _service.fetchActiveBatches();
      if (_activeBatches.isNotEmpty && _selectedBatchId == null) {
        _selectedBatchId = _activeBatches.first.id;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('[BatchProvider] loadActiveBatches error: $e');
    } finally {
      _isLoadingBatches = false;
      notifyListeners();
    }
  }

  Future<void> loadTeamsForBatch(String batchId) async {
    _selectedBatchId = batchId;
    _isLoadingTeams = true;
    notifyListeners();

    try {
      _teamsForBatch = await _service.fetchTeamsForBatch(batchId);
    } catch (e) {
      _error = e.toString();
      debugPrint('[BatchProvider] loadTeamsForBatch error: $e');
    } finally {
      _isLoadingTeams = false;
      notifyListeners();
    }
  }

  Future<void> loadTeamMembers(String teamId) async {
    try {
      final team = await _service.fetchTeamWithMembers(teamId);
      _teamMembers = team.members;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('[BatchProvider] loadTeamMembers error: $e');
    }
  }

  Future<void> autoDistribute({
    required String batchId,
    required int targetSize,
  }) async {
    _isRunningDistribution = true;
    notifyListeners();

    try {
      await _service.autoDistributeTeams(
        batchId: batchId,
        targetSize: targetSize,
      );
      // Refresh teams list
      await loadTeamsForBatch(batchId);
    } catch (e) {
      _error = e.toString();
      debugPrint('[BatchProvider] autoDistribute error: $e');
    } finally {
      _isRunningDistribution = false;
      notifyListeners();
    }
  }

  Future<void> moveStudent({
    required String studentId,
    required String targetTeamId,
    String? movedBy,
  }) async {
    try {
      await _service.moveStudentToTeam(
        studentId: studentId,
        targetTeamId: targetTeamId,
        movedBy: movedBy,
      );
      // Refresh current batch teams
      if (_selectedBatchId != null) {
        await loadTeamsForBatch(_selectedBatchId!);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('[BatchProvider] moveStudent error: $e');
      notifyListeners();
    }
  }

  Future<void> assignTeamLeader({
    required String teamId,
    required String leaderId,
    String? assignedBy,
  }) async {
    try {
      await _service.assignTeamLeader(
        teamId: teamId,
        leaderId: leaderId,
        assignedBy: assignedBy,
      );
      if (_selectedBatchId != null) {
        await loadTeamsForBatch(_selectedBatchId!);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('[BatchProvider] assignTeamLeader error: $e');
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
