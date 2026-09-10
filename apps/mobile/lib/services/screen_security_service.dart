import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Small first-party bridge for Android's FLAG_SECURE.
///
/// Keeping this bridge in the app removes a full third-party Gradle plugin and
/// makes the proctored Daily Five screen compatible with Flutter's current
/// built-in Kotlin toolchain.
class ScreenSecurityService {
  static const MethodChannel _channel = MethodChannel('psgmx/screen_security');

  static Future<void> setSecure(bool enabled) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await _channel.invokeMethod<void>('setSecure', {'enabled': enabled});
  }
}
