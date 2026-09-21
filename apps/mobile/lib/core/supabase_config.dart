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
  static String get appApiUrl => normalizeAppApiUrl(_envAppApiUrl);

  /// Normalises the public API origin used by mobile builds.
  ///
  /// `app.psgmx.tech` and the Firebase hosting domain serve the Flutter web
  /// shell. Requests such as `/api/communication/evaluate` therefore return
  /// `index.html`, which used to surface as an "Unexpected character" JSON
  /// error. Privileged API routes live on the trusted Next.js origin.
  static String normalizeAppApiUrl(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) return 'https://www.psgmx.tech';

    final uri = Uri.tryParse(value);
    final host = uri?.host.toLowerCase();
    const frontendOnlyHosts = {
      'app.psgmx.tech',
      'psgmxians.web.app',
      'psgmxians.firebaseapp.com',
    };
    if (host == 'psgmx.tech' || frontendOnlyHosts.contains(host)) {
      return 'https://www.psgmx.tech';
    }

    return value.replaceAll(RegExp(r'/+$'), '');
  }

  /// Returns true if the minimum required config for app startup is present.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
