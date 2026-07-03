import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/company.dart';
import '../services/placement_log_service.dart';

/// State management for the Placement Log feature.
///
/// Manages the company list and per-company entry cache so that the
/// [PlacementLogScreen] and [CompanyDetailScreen] share one data source
/// without duplicating network calls.
class PlacementLogProvider with ChangeNotifier {
  final PlacementLogService _service;

  PlacementLogProvider()
      : _service = PlacementLogService(Supabase.instance.client);

  // ── State ──────────────────────────────────────────────────────────────────

  List<Company> _companies = [];
  /// Per-company entry cache: companyId → entries list.
  final Map<String, List<PlacementLogEntry>> _entriesCache = {};

  bool _isLoadingCompanies = false;
  final Map<String, bool> _isLoadingEntries = {};
  String? _error;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<Company> get companies => _companies;
  bool get isLoadingCompanies => _isLoadingCompanies;
  String? get error => _error;

  List<PlacementLogEntry> entriesFor(String companyId) =>
      _entriesCache[companyId] ?? [];
  bool isLoadingEntriesFor(String companyId) =>
      _isLoadingEntries[companyId] ?? false;

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> loadCompanies({String? batchId}) async {
    _isLoadingCompanies = true;
    _error = null;
    notifyListeners();

    try {
      _companies = await _service.fetchCompanies(batchId: batchId);
    } catch (e) {
      _error = e.toString();
      debugPrint('[PlacementLogProvider] loadCompanies error: $e');
    } finally {
      _isLoadingCompanies = false;
      notifyListeners();
    }
  }

  Future<void> loadEntries(String companyId) async {
    _isLoadingEntries[companyId] = true;
    notifyListeners();

    try {
      _entriesCache[companyId] = await _service.fetchLogsForCompany(companyId);
    } catch (e) {
      _error = e.toString();
      debugPrint('[PlacementLogProvider] loadEntries error: $e');
    } finally {
      _isLoadingEntries[companyId] = false;
      notifyListeners();
    }
  }

  Future<void> addEntry({
    required String companyId,
    required String studentId,
    required String roleOffered,
    required DateTime interviewDate,
    required String outcome,
    required String experienceContent,
    required bool isAnonymous,
  }) async {
    await _service.submitLog(
      companyId: companyId,
      studentId: studentId,
      roleOffered: roleOffered,
      interviewDate: interviewDate,
      outcome: outcome,
      experienceContent: experienceContent,
      isAnonymous: isAnonymous,
    );
    // Refresh the entry list for this company
    await loadEntries(companyId);
  }

  Future<void> moderateEntry({
    required String logId,
    required String moderatedBy,
    required bool isApproved,
    required String companyId,
  }) async {
    await _service.moderateLog(
      logId: logId,
      moderatedBy: moderatedBy,
      isApproved: isApproved,
    );
    await loadEntries(companyId);
  }

  Future<Company> createCompany({
    required String name,
    required String batchId,
    String? industry,
    String? website,
    String? logoUrl,
    required String createdBy,
  }) async {
    final company = await _service.createCompany(
      name: name,
      batchId: batchId,
      industry: industry,
      website: website,
      logoUrl: logoUrl,
      createdBy: createdBy,
    );
    _companies = [..._companies, company];
    notifyListeners();
    return company;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
