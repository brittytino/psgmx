// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html show window;

/// Utility class for detecting platform-specific features (Web implementation)
class PlatformUtils {
  /// Check if the app is running on iOS Safari
  static bool get isIOSSafari {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    final isIOS = userAgent.contains('iphone') || 
                  userAgent.contains('ipad') || 
                  userAgent.contains('ipod');
    final isSafari = userAgent.contains('safari') && 
                     !userAgent.contains('chrome') && 
                     !userAgent.contains('crios') && 
                     !userAgent.contains('fxios');
    
    return isIOS && isSafari;
  }

  /// Check if the app is running in standalone mode (already installed as PWA)
  static bool get isStandalone {
    try {
      final display = html.window.matchMedia('(display-mode: standalone)');
      return display.matches;
    } catch (e) {
      return false;
    }
  }

  /// Check if we should show the iOS installation guide
  static bool get shouldShowIOSInstallGuide {
    return isIOSSafari && !isStandalone;
  }
}
