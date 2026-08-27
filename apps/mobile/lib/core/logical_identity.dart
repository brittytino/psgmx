import 'package:supabase_flutter/supabase_flutter.dart';

/// Resolves the current Supabase authentication identity to the one logical
/// PSGMX profile shared by personal and college email logins.
class LogicalIdentity {
  static String? _authId;
  static String? _profileId;

  static Future<String?> currentUserId(SupabaseClient client) async {
    final authId = client.auth.currentUser?.id;
    if (authId == null) return null;
    if (_authId == authId && _profileId != null) return _profileId;
    try {
      final value = await client.rpc('current_user_id');
      _authId = authId;
      _profileId = value?.toString() ?? authId;
    } catch (_) {
      _authId = authId;
      _profileId = authId;
    }
    return _profileId;
  }

  static void clear() {
    _authId = null;
    _profileId = null;
  }
}
