/// Supabase configuration loaded exclusively from compile-time environment
/// variables injected via `--dart-define-from-file=.env.flutter`.
///
/// Build commands:
///   flutter run --dart-define-from-file=.env.flutter
///   flutter build apk --dart-define-from-file=.env.flutter
///
/// NEVER add hardcoded fallback values here. Missing values cause a loud
/// failure at startup rather than silently using a leaked key.
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// URL of the eCampus FastAPI scraper (Python service).
  static const String ecampusApiUrl =
      String.fromEnvironment('ECAMPUS_API_URL');

  /// Shared secret between the Flutter app and the eCampus API.
  static const String ecampusApiSecret =
      String.fromEnvironment('ECAMPUS_API_SECRET');

  /// API key for the external desktop exam platform (readiness score push).
  static const String externalPlatformApiKey =
      String.fromEnvironment('EXTERNAL_PLATFORM_API_KEY');

  /// OpenRouter API key for the AI Mentor feature.
  static const String openRouterApiKey =
      String.fromEnvironment('OPENROUTER_API_KEY');

  /// Returns true if the minimum required config for app startup is present.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
