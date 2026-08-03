/// Supabase configuration loaded from compile-time environment variables,
/// with fallback values from `.env.flutter` for out-of-the-box local execution.
class SupabaseConfig {
  static const String _envSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envSupabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String _envEcampusApiUrl =
      String.fromEnvironment('ECAMPUS_API_URL');
  static const String _envEcampusApiSecret =
      String.fromEnvironment('ECAMPUS_API_SECRET');
  static const String _envExternalPlatformApiKey =
      String.fromEnvironment('EXTERNAL_PLATFORM_API_KEY');
  static const String _envOpenRouterApiKey =
      String.fromEnvironment('OPENROUTER_API_KEY');

  static String get supabaseUrl => _envSupabaseUrl.isNotEmpty
      ? _envSupabaseUrl
      : 'https://ucmskbgdpnolnyrmkotz.supabase.co';

  static String get supabaseAnonKey => _envSupabaseAnonKey.isNotEmpty
      ? _envSupabaseAnonKey
      : 'sb_publishable_FYSPL2NrQ7uby010u8hTmg_26v9e2MI';

  static String get ecampusApiUrl => _envEcampusApiUrl.isNotEmpty
      ? _envEcampusApiUrl
      : 'https://psgmx-ecampus-api.onrender.com';

  static String get ecampusApiSecret => _envEcampusApiSecret.isNotEmpty
      ? _envEcampusApiSecret
      : 'flutter-client-secret-1234';

  static String get externalPlatformApiKey => _envExternalPlatformApiKey;

  static String get openRouterApiKey => _envOpenRouterApiKey;

  /// Returns true if the minimum required config for app startup is present.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

