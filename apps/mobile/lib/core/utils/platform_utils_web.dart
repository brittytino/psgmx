// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html show window;
import 'dart:js' as js;

/// Utility class for detecting platform-specific features (Web implementation)
class PlatformUtils {
  /// Check if the app is running on iOS Safari (not Chrome, Firefox, or Edge on iOS)
  static bool get isIOSSafari {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    final isAppleDevice = isIOS;
    final isSafari = userAgent.contains('safari') &&
        !userAgent.contains('chrome') &&
        !userAgent.contains('crios') &&
        !userAgent.contains('fxios') &&
        !userAgent.contains('edgios');

    return isAppleDevice && isSafari;
  }

  /// Check if the app is running in standalone mode (already installed as PWA)
  static bool get isStandalone {
    // 1. Call window.isAppStandalone helper from index.html
    try {
      if (js.context.hasProperty('isAppStandalone')) {
        final result = js.context.callMethod('isAppStandalone', const []);
        if (result == true) return true;
      }
    } catch (_) {}

    // 2. Direct property lookup on raw JS navigator (iOS Safari standalone mode)
    try {
      final nav = js.context['navigator'];
      if (nav != null && nav['standalone'] == true) return true;
    } catch (_) {}

    // 3. CSS display-mode media queries
    try {
      if (html.window.matchMedia('(display-mode: standalone)').matches == true) return true;
      if (html.window.matchMedia('(display-mode: fullscreen)').matches == true) return true;
      if (html.window.matchMedia('(display-mode: minimal-ui)').matches == true) return true;
    } catch (_) {}

    // 4. URL query checks (e.g. ?source=pwa or ?mode=standalone)
    try {
      final href = html.window.location.href.toLowerCase();
      if (href.contains('source=pwa') || href.contains('mode=standalone')) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Check if the device is running iOS (iPhone, iPad, iPod)
  static bool get isIOS {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    final isAppleDevice = userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('ipod');
    // Modern iPadOS (iOS 13+) identifies as Macintosh with touch points
    final isTouchMac = userAgent.contains('macintosh') &&
        (html.window.navigator.maxTouchPoints != null &&
            (html.window.navigator.maxTouchPoints! > 1));

    return isAppleDevice || isTouchMac;
  }

  /// Check if we should show the iOS installation guide
  static bool get shouldShowIOSInstallGuide {
    return isIOS && !isStandalone;
  }
}
