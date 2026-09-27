import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/version_comparator.dart';
import '../../services/update_service.dart';
import 'emergency_block_screen.dart';
import 'force_update_screen.dart';
import 'optional_update_sheet.dart';
import 'whats_new_screen.dart';

/// Update Gate Widget
///
/// Wraps the main app content and enforces all update policies in priority order:
///
///   1. [EmergencyBlockScreen]  – emergency_block = true in DB (cannot be dismissed)
///   2. [ForceUpdateScreen]     – current version < min_required_version
///   3. [WhatsNewScreen]        – app was just updated (shown once per new version)
///   4. [OptionalUpdateSheet]   – newer version available, shown as bottom sheet
///   5. Normal app content      – everything is fine
///
/// Place this in the widget tree immediately inside MaterialApp.builder so it
/// applies globally before any route resolves.
class UpdateGate extends StatefulWidget {
  final Widget child;

  /// Optional callback invoked once the initial update check completes.
  final VoidCallback? onUpdateCheckComplete;

  const UpdateGate({
    super.key,
    required this.child,
    this.onUpdateCheckComplete,
  });

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> with WidgetsBindingObserver {
  bool _hasShownOptionalUpdate = false;
  bool _initialCheckDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _performInitialCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-check when the app resumes from background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _recheckOnResume();
    }
  }

  Future<void> _performInitialCheck() async {
    final svc = context.read<UpdateService>();
    if (!svc.isInitialized) {
      await svc.initialize();
    }

    if (mounted) {
      setState(() => _initialCheckDone = true);
      widget.onUpdateCheckComplete?.call();
      _maybeShowOptionalUpdate();
    }
  }

  Future<void> _recheckOnResume() async {
    final svc = context.read<UpdateService>();
    await svc.checkForUpdates();
    if (mounted) setState(() {});
  }

  void _maybeShowOptionalUpdate() {
    if (_hasShownOptionalUpdate) return;
    final svc = context.read<UpdateService>();
    if (!svc.shouldShowOptionalUpdate) return;

    _hasShownOptionalUpdate = true;
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && svc.shouldShowOptionalUpdate) {
        if (Navigator.maybeOf(context) != null) {
          OptionalUpdateSheet.show(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Still initialising – pass through to avoid blocking splash
    if (!_initialCheckDone) return widget.child;

    return Consumer<UpdateService>(
      builder: (context, svc, _) {
        final status = svc.updateStatus;

        // ── Priority 1: Emergency block ─────────────────────────────────────
        if (status == UpdateStatus.emergencyBlocked) {
          return const EmergencyBlockScreen();
        }

        // ── Priority 2: Force update required ──────────────────────────────
        if (status == UpdateStatus.forceUpdateRequired) {
          return const ForceUpdateScreen();
        }

        // ── Priority 3: What's New (show once after update) ────────────────
        if (svc.shouldShowWhatsNew) {
          return WhatsNewScreen(
            onDismiss: () {
              // After dismissing What's New, check if optional update sheet
              // should also appear
              setState(() {});
              _maybeShowOptionalUpdate();
            },
          );
        }

        // ── Priority 4 & 5: Normal app (optional update via bottom sheet) ───
        return widget.child;
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility mixin & helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Mixin for screens that should trigger an update check on first display.
/// Useful on landing / home screens that are entry points after deep links.
mixin UpdateCheckMixin<T extends StatefulWidget> on State<T> {
  bool _hasCheckedForUpdate = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    if (_hasCheckedForUpdate) return;
    _hasCheckedForUpdate = true;

    if (!mounted) return;
    final svc = context.read<UpdateService>();
    await svc.checkForUpdates();

    if (mounted && svc.shouldShowOptionalUpdate) {
      OptionalUpdateSheet.show(context);
    }
  }
}

/// Standalone helper: force-check for update and navigate/show accordingly.
/// Can be called from Settings → "Check for Updates".
Future<void> checkAndShowUpdate(BuildContext context,
    {bool forceCheck = false}) async {
  if (!context.mounted) return;

  final svc = context.read<UpdateService>();
  await svc.checkForUpdates(forceCheck: forceCheck);

  if (!context.mounted) return;

  final status = svc.updateStatus;

  if (status == UpdateStatus.emergencyBlocked) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const EmergencyBlockScreen()),
      (_) => false,
    );
  } else if (status == UpdateStatus.forceUpdateRequired) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ForceUpdateScreen()),
      (_) => false,
    );
  } else if (status == UpdateStatus.optionalUpdateAvailable) {
    OptionalUpdateSheet.show(context);
  } else {
    // Already up to date
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'You\'re on the latest version (v${svc.currentVersion})! 🎉',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
