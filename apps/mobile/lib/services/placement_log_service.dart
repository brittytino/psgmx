import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/company.dart';

/// Manages the Placement Log — company records and personal experience entries.
class PlacementLogService {
  final SupabaseClient _supabase;

  PlacementLogService(this._supabase);

  // ── Company Records ────────────────────────────────────────────────────────

  /// Returns all company records visible to the current user, sorted by visit
  /// date ascending so the placement season reads chronologically.
  /// Both active batches and graduated alumni can read all records.
  Future<List<Company>> fetchCompanies({String? batchId}) async {
    var query = _supabase.from('companies').select();
    if (batchId != null) {
      query = query.eq('batch_id', batchId);
    }
    final response = await query.order('visit_date', ascending: true);
    return (response as List).map((r) => Company.fromMap(r)).toList();
  }

  /// Creates a new company record.
  /// Requires [manage_company_records] permission (enforced by RLS).
  Future<Company> createCompanyRecord({
    required String batchId,
    required String createdBy,
    required String name,
    required DateTime visitDate,
    required List<String> rolesOffered,
    String? packageBand,
    String? eligibility,
    List<Map<String, dynamic>> rounds = const [],
  }) async {
    final response = await _supabase.from('companies').insert({
      'batch_id': batchId,
      'created_by': createdBy,
      'name': name,
      'visit_date': visitDate.toIso8601String().split('T')[0],
      'roles_offered': rolesOffered,
      'package_band': packageBand,
      'eligibility': eligibility,
      'rounds': rounds,
    }).select().single();

    await _supabase.from('audit_logs').insert({
      'actor_id': createdBy,
      'action': 'CREATE_COMPANY_RECORD',
      'entity_type': 'companies',
      'entity_id': null,
      'metadata': {'company_name': name, 'visit_date': visitDate.toIso8601String()},
    });

    debugPrint('[PlacementLogService] Company record created: $name');
    return Company.fromMap(response);
  }

  /// Updates an existing company record.
  Future<void> updateCompanyRecord({
    required String companyId,
    required String updatedBy,
    String? name,
    DateTime? visitDate,
    List<String>? rolesOffered,
    String? packageBand,
    String? eligibility,
    List<Map<String, dynamic>>? rounds,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (visitDate != null) {
      updates['visit_date'] = visitDate.toIso8601String().split('T')[0];
    }
    if (rolesOffered != null) updates['roles_offered'] = rolesOffered;
    if (packageBand != null) updates['package_band'] = packageBand;
    if (eligibility != null) updates['eligibility'] = eligibility;
    if (rounds != null) updates['rounds'] = rounds;
    if (updates.isEmpty) return;

    await _supabase.from('companies').update(updates).eq('id', companyId);
  }

  // ── Experience Log Entries ─────────────────────────────────────────────────

  /// Fetches all entries for a company, ordered newest first.
  Future<List<PlacementLogEntry>> fetchEntriesForCompany(
      String companyId) async {
    final response = await _supabase
        .from('placement_log_entries')
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((r) => PlacementLogEntry.fromMap(r))
        .toList();
  }

  /// Adds a new personal experience entry.
  /// Only active_senior batch students can add entries (enforced by RLS).
  Future<PlacementLogEntry> addLogEntry({
    required String companyId,
    required String userId,
    required String roundName,
    required String experienceText,
  }) async {
    final response = await _supabase.from('placement_log_entries').insert({
      'company_id': companyId,
      'user_id': userId,
      'round_name': roundName,
      'experience_text': experienceText,
    }).select().single();

    debugPrint('[PlacementLogService] Log entry added for company $companyId');
    return PlacementLogEntry.fromMap(response);
  }

  /// Updates an existing entry (by the author).
  Future<void> updateLogEntry({
    required String entryId,
    String? roundName,
    String? experienceText,
  }) async {
    final updates = <String, dynamic>{};
    if (roundName != null) updates['round_name'] = roundName;
    if (experienceText != null) updates['experience_text'] = experienceText;
    if (updates.isEmpty) return;

    await _supabase
        .from('placement_log_entries')
        .update(updates)
        .eq('id', entryId);
  }

  /// Moderates an entry (Rep/Coordinator with [moderate_placement_log]).
  /// Sets the is_moderated flag which hides/freezes the entry.
  Future<void> moderateEntry({
    required String entryId,
    required String moderatedBy,
    required bool moderate,
  }) async {
    await _supabase.from('placement_log_entries').update({
      'is_moderated': moderate,
      'moderated_by': moderate ? moderatedBy : null,
    }).eq('id', entryId);

    await _supabase.from('audit_logs').insert({
      'actor_id': moderatedBy,
      'action': moderate ? 'MODERATE_LOG_ENTRY' : 'UNMODERATE_LOG_ENTRY',
      'entity_type': 'placement_log_entries',
      'entity_id': null,
      'metadata': {'entry_id': entryId},
    });
  }

  // ── Convenience aliases (used by UI screens) ───────────────────────────────

  /// Creates a lightweight company record used by [PlacementLogScreen].
  /// Wraps [createCompanyRecord] with a minimal required-field set.
  Future<Company> createCompany({
    required String name,
    required String batchId,
    String? industry,
    String? website,
    String? logoUrl,
    required String createdBy,
  }) async {
    // Use visitDate = today as a sensible default when scheduling is not yet known.
    final response = await _supabase.from('companies').insert({
      'batch_id': batchId,
      'created_by': createdBy,
      'name': name,
      'visit_date': DateTime.now().toIso8601String().split('T')[0],
      'roles_offered': <String>[],
      if (industry != null) 'industry': industry,
      if (website != null) 'website': website,
      if (logoUrl != null) 'logo_url': logoUrl,
    }).select().single();

    await _supabase.from('audit_logs').insert({
      'actor_id': createdBy,
      'action': 'CREATE_COMPANY',
      'entity_type': 'companies',
      'entity_id': null,
      'metadata': {'company_name': name},
    });

    return Company.fromMap(response);
  }

  /// Alias for [fetchEntriesForCompany] — called by [CompanyDetailScreen].
  Future<List<PlacementLogEntry>> fetchLogsForCompany(String companyId) =>
      fetchEntriesForCompany(companyId);

  /// Simplified entry submission used by [CompanyDetailScreen].
  Future<void> submitLog({
    required String companyId,
    required String studentId,
    required String roleOffered,
    required DateTime interviewDate,
    required String outcome,
    required String experienceContent,
    required bool isAnonymous,
  }) async {
    await _supabase.from('placement_log_entries').insert({
      'company_id': companyId,
      'user_id': studentId,
      'round_name': roleOffered,
      'experience_text': experienceContent,
      'outcome': outcome,
      'interview_date': interviewDate.toIso8601String().split('T')[0],
      'is_anonymous': isAnonymous,
    });

    await _supabase.from('audit_logs').insert({
      'actor_id': studentId,
      'action': 'SUBMIT_PLACEMENT_LOG',
      'entity_type': 'placement_log_entries',
      'entity_id': null,
      'metadata': {'company_id': companyId, 'outcome': outcome},
    });
  }

  /// Alias for [moderateEntry] with the approval-oriented signature used by
  /// [CompanyDetailScreen].
  Future<void> moderateLog({
    required String logId,
    required String moderatedBy,
    required bool isApproved,
  }) =>
      moderateEntry(
        entryId: logId,
        moderatedBy: moderatedBy,
        moderate: !isApproved, // isApproved=true means un-moderate
      );
}
