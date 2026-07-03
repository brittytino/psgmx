/// Platform utilities stub for non-web platforms
class PlatformUtils {
  /// Check if the app is running on iOS Safari (always false on mobile)
  static bool get isIOSSafari => false;

  /// Check if the app is running in standalone mode (always false on mobile)
  static bool get isStandalone => false;

  /// Check if we should show the iOS installation guide (always false on mobile)
  static bool get shouldShowIOSInstallGuide => false;
}
