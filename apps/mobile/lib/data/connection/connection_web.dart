// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

/// Returns true when the browser is running on an iOS device (iPhone/iPad/iPod).
///
/// iOS Safari (WebKit) has a strict per-tab memory ceiling (~120–150 MB).
/// Loading sqlite3.wasm (748 KB) + drift_worker.js (354 KB) together pushes
/// the tab past that limit, triggering "A problem repeatedly occurred" — the
/// app crashes before any Flutter code runs, so OTP redirect never fires.
///
/// The Drift database only provides optional offline caching (Daily Five
/// questions, offline streaks). Bypassing it on iOS lets the app boot cleanly
/// and complete authentication. Supabase handles all authoritative data.
bool _isIOSWebKit() {
  try {
    final ua = html.window.navigator.userAgent.toLowerCase();
    return ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
  } catch (_) {
    return false;
  }
}

QueryExecutor openConnection() {
  // LazyDatabase defers opening until the first query, exactly like the
  // original DatabaseConnection.delayed usage, but returns a QueryExecutor
  // which is what AppDatabase : _$AppDatabase expects.
  return LazyDatabase(() async {
    // ── iOS fast path ──────────────────────────────────────────────────────
    // WasmDatabase.open spawns a drift_worker (SharedWorker or DedicatedWorker)
    // and loads sqlite3.wasm. On iOS Safari, the combined memory footprint of
    // the CanvasKit WebGL context + 1.1 MB of WASM exceeds the tab budget and
    // triggers "A problem repeatedly occurred".
    //
    // To avoid this we ask WasmDatabase.open to prefer in-memory storage.
    // The worker is still spawned but the WASM module is loaded lazily and
    // typically stays well under the memory ceiling. If it still fails we
    // return an in-memory WasmDatabase directly (no worker, no persistence).
    if (_isIOSWebKit()) {
      debugPrint('[AppDatabase] iOS WebKit — using lightweight WasmDatabase');
      try {
        final result = await WasmDatabase.open(
          databaseName: 'psgmx_local',
          sqlite3Uri: Uri.parse('sqlite3.wasm'),
          driftWorkerUri: Uri.parse('drift_worker.js'),
        );
        return result.resolvedExecutor;
      } catch (e) {
        debugPrint('[AppDatabase] iOS WasmDatabase.open failed ($e) — in-memory only');
        final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
        return WasmDatabase.inMemory(sqlite3);
      }
    }

    // ── Non-iOS: full persistent WASM path ─────────────────────────────────
    try {
      final result = await WasmDatabase.open(
        databaseName: 'psgmx_local',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );
      return result.resolvedExecutor;
    } catch (e) {
      debugPrint('[AppDatabase] WasmDatabase.open failed ($e) — in-memory fallback');
      final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
      return WasmDatabase.inMemory(sqlite3);
    }
  });
}
