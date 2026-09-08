/// Supabase configuration loaded from compile-time environment variables
/// (`flutter run/build --dart-define-from-file=.env.flutter`, or the
/// equivalent generated in CI from GitHub Secrets — see
/// .github/workflows/firebase-hosting-merge.yml and release.yml).
///
/// There is deliberately no hardcoded fallback here. A previous version of
/// this file fell back to this project's real production Supabase URL and
/// anon key when the env vars were absent, which meant `main.dart`'s
/// "missing configuration" startup check could never actually trigger, and
/// baked live production credentials into source control. If the env vars
/// are missing, `isConfigured` is false and main.dart fails loudly with
/// instructions instead of silently connecting to production.
class SupabaseConfig {
  static const String _envSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envSupabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String _envAppApiUrl = String.fromEnvironment('APP_API_URL');

  static String get supabaseUrl => _envSupabaseUrl;

  static String get supabaseAnonKey => _envSupabaseAnonKey;

  /// All privileged integrations are brokered by the trusted web backend.
  /// No shared eCampus or AI secret is ever compiled into the mobile app.
  static String get appApiUrl => _envAppApiUrl.isNotEmpty
      ? _envAppApiUrl.replaceAll(RegExp(r'/$'), '')
      : 'https://www.psgmx.tech';

  /// Returns true if the minimum required config for app startup is present.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
