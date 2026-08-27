import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// A [ChangeNotifier] mixin that defers [notifyListeners] calls if Flutter
/// is currently in the middle of building a frame (persistentCallbacks phase).
/// This prevents "setState() or markNeedsBuild() called during build" exceptions.
///
/// Ensures safe UI updates across all mobile providers during build lifecycle phases.
mixin SafeChangeNotifier on ChangeNotifier {
  @override
  void notifyListeners() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) {
          super.notifyListeners();
        }
      });
    } else {
      super.notifyListeners();
    }
  }
}
