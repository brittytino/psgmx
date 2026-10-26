// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/wasm.dart';

import '../../core/utils/platform_utils.dart';

/// Returns true when the browser is running on an iOS device (iPhone/iPad/iPod).
bool _isIOSWebKit() {
  return PlatformUtils.isIOS || defaultTargetPlatform == TargetPlatform.iOS;
}

QueryExecutor openConnection() {
  // LazyDatabase defers opening until the first query, exactly like the
  // original DatabaseConnection.delayed usage, but returns a QueryExecutor
  // which is what AppDatabase : _$AppDatabase expects.
  return LazyDatabase(() async {
    // ── iOS fast path ──────────────────────────────────────────────────────
    // On iOS Safari, the combined memory footprint of the CanvasKit WebGL
    // context + WASM + SharedWorker/DedicatedWorker exceeds the strict
    // per-tab memory ceiling (~120-150 MB) and triggers "A problem repeatedly occurred".
    //
    // To avoid this, we completely bypass the worker and persistent storage on iOS.
    // We return an in-memory WasmDatabase directly (no worker, no persistence).
    if (_isIOSWebKit()) {
      debugPrint('[AppDatabase] iOS WebKit — using in-memory WasmDatabase to prevent OOM crash');
      try {
        final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
        return WasmDatabase.inMemory(sqlite3);
      } catch (e) {
        debugPrint('[AppDatabase] iOS WasmDatabase.inMemory failed ($e)');
        rethrow;
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
