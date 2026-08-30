/// Supabase configuration loaded from compile-time environment variables,
/// with fallback values from `.env.flutter` for out-of-the-box local execution.
class SupabaseConfig {
  static const String _envSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envSupabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String _envAppApiUrl = String.fromEnvironment('APP_API_URL');

  static String get supabaseUrl => _envSupabaseUrl.isNotEmpty
      ? _envSupabaseUrl
      : 'https://ucmskbgdpnolnyrmkotz.supabase.co';

  static String get supabaseAnonKey => _envSupabaseAnonKey.isNotEmpty
      ? _envSupabaseAnonKey
      : 'sb_publishable_FYSPL2NrQ7uby010u8hTmg_26v9e2MI';

  /// All privileged integrations are brokered by the trusted web backend.
  /// No shared eCampus or AI secret is ever compiled into the mobile app.
  static String get appApiUrl => _envAppApiUrl.isNotEmpty
      ? _envAppApiUrl.replaceAll(RegExp(r'/$'), '')
      : 'https://www.psgmx.tech';

  /// Returns true if the minimum required config for app startup is present.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
