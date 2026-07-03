import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_permission.dart';

/// Manages the dynamic per-user permission flag system.
///
/// Only users with [UserPermission.manageMembers] can grant/revoke flags
/// on others — this is enforced both here (service layer) and at the DB
/// via RLS policies on `user_permissions`.
class PermissionService {
  final SupabaseClient _supabase;

  PermissionService(this._supabase);

  // ── Fetch ──────────────────────────────────────────────────────────────────

  /// Returns the full set of permissions the given user currently holds.
  Future<Set<UserPermission>> fetchUserPermissions(String userId) async {
    try {
      final response = await _supabase
          .from('user_permissions')
          .select('permission_key')
          .eq('user_id', userId);

      final Set<UserPermission> result = {};
      for (final row in response as List) {
        final perm = UserPermissionExtension.fromDbKey(
            row['permission_key'] as String);
        if (perm != null) result.add(perm);
      }
      debugPrint('[PermissionService] Loaded ${result.length} permissions for $userId');
      return result;
    } catch (e) {
      debugPrint('[PermissionService] fetchUserPermissions error: $e');
      return {};
    }
  }

  /// Returns all users in a batch with their current permission flags.
  /// Requires [manageMembers] permission (enforced by RLS).
  Future<Map<String, Set<UserPermission>>> fetchBatchPermissions(
      String batchId) async {
    final response = await _supabase
        .from('user_permissions')
        .select('user_id, permission_key')
        .eq('users.batch_id', batchId);

    final result = <String, Set<UserPermission>>{};
    for (final row in response as List) {
      final uid = row['user_id'] as String;
      final perm =
          UserPermissionExtension.fromDbKey(row['permission_key'] as String);
      if (perm != null) {
        result.putIfAbsent(uid, () => {}).add(perm);
      }
    }
    return result;
  }

  // ── Grant / Revoke ─────────────────────────────────────────────────────────

  /// Grants a single [permission] to [targetUserId].
  ///
  /// [grantedBy] must hold [UserPermission.manageMembers] — this is validated
  /// both here and enforced by the DB RLS policy.
  Future<void> grantPermission({
    required String grantedBy,
    required String targetUserId,
    required UserPermission permission,
  }) async {
    await _supabase.from('user_permissions').upsert({
      'user_id': targetUserId,
      'permission_key': permission.dbKey,
      'granted_by': grantedBy,
    }, onConflict: 'user_id, permission_key');

    debugPrint(
        '[PermissionService] Granted ${permission.dbKey} to $targetUserId');

    // Write audit log
    await _supabase.from('audit_logs').insert({
      'actor_id': grantedBy,
      'action': 'GRANT_PERMISSION',
      'entity_type': 'user_permissions',
      'entity_id': null,
      'metadata': {
        'target_user_id': targetUserId,
        'permission': permission.dbKey,
      },
    });
  }

  /// Revokes a single [permission] from [targetUserId].
  Future<void> revokePermission({
    required String revokedBy,
    required String targetUserId,
    required UserPermission permission,
  }) async {
    await _supabase
        .from('user_permissions')
        .delete()
        .eq('user_id', targetUserId)
        .eq('permission_key', permission.dbKey);

    debugPrint(
        '[PermissionService] Revoked ${permission.dbKey} from $targetUserId');

    await _supabase.from('audit_logs').insert({
      'actor_id': revokedBy,
      'action': 'REVOKE_PERMISSION',
      'entity_type': 'user_permissions',
      'entity_id': null,
      'metadata': {
        'target_user_id': targetUserId,
        'permission': permission.dbKey,
      },
    });
  }

  /// Replaces the full permission set for [targetUserId] with [newPermissions].
  ///
  /// This is used by the admin UI's "Save changes" action — it deletes all
  /// existing permissions and inserts the new set atomically.
  Future<void> setPermissions({
    required String setBy,
    required String targetUserId,
    required Set<UserPermission> newPermissions,
  }) async {
    // Delete all existing permissions for the user
    await _supabase
        .from('user_permissions')
        .delete()
        .eq('user_id', targetUserId);

    // Insert new set
    if (newPermissions.isNotEmpty) {
      await _supabase.from('user_permissions').insert(
            newPermissions
                .map((p) => {
                      'user_id': targetUserId,
                      'permission_key': p.dbKey,
                      'granted_by': setBy,
                    })
                .toList(),
          );
    }

    await _supabase.from('audit_logs').insert({
      'actor_id': setBy,
      'action': 'SET_PERMISSIONS',
      'entity_type': 'user_permissions',
      'entity_id': null,
      'metadata': {
        'target_user_id': targetUserId,
        'permissions': newPermissions.map((p) => p.dbKey).toList(),
      },
    });
  }

  // ── Role Label ─────────────────────────────────────────────────────────────

  /// Updates the cosmetic role label for a user (Placement Rep, Coordinator,
  /// Team Leader, Student). Does NOT change any permission flags.
  Future<void> setRoleLabel({
    required String setBy,
    required String targetUserId,
    required String label,
  }) async {
    await _supabase
        .from('users')
        .update({'role_label': label}).eq('id', targetUserId);

    await _supabase.from('audit_logs').insert({
      'actor_id': setBy,
      'action': 'SET_ROLE_LABEL',
      'entity_type': 'users',
      'entity_id': null,
      'metadata': {
        'target_user_id': targetUserId,
        'role_label': label,
      },
    });
  }

  // ── Convenience Presets ────────────────────────────────────────────────────

  /// Applies the default Placement Rep permission set to [targetUserId].
  Future<void> applyPlacementRepPreset({
    required String grantedBy,
    required String targetUserId,
  }) async {
    await setPermissions(
      setBy: grantedBy,
      targetUserId: targetUserId,
      newPermissions: kPlacementRepPermissions,
    );
    await setRoleLabel(
      setBy: grantedBy,
      targetUserId: targetUserId,
      label: 'Placement Rep',
    );
  }

  /// Applies the default Team Leader permission set to [targetUserId].
  Future<void> applyTeamLeaderPreset({
    required String grantedBy,
    required String targetUserId,
  }) async {
    await setPermissions(
      setBy: grantedBy,
      targetUserId: targetUserId,
      newPermissions: kTeamLeaderPermissions,
    );
    await setRoleLabel(
      setBy: grantedBy,
      targetUserId: targetUserId,
      label: 'Team Leader',
    );
  }
}
