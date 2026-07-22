import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/local_database.dart';

class SyncService {
  final SupabaseClient _supabase;
  final AppDatabase _db;
  bool _isSyncing = false;

  SyncService(this._supabase, this._db) {
    _init();
  }

  void _init() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        _syncPendingActions();
      }
    });
  }

  Future<void> _syncPendingActions() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pendingActions = await _db.select(_db.syncQueue).get();
      if (pendingActions.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint('[SyncService] Processing ${pendingActions.length} offline actions');

      for (final action in pendingActions) {
        try {
          final payload = jsonDecode(action.payloadJson) as Map<String, dynamic>;
          
          if (action.actionType == 'submit_daily_five') {
            await _supabase.rpc('submit_daily_five', params: {
              'p_user_id': payload['user_id'],
              'p_accuracy_rate': payload['accuracy_rate'],
            });
            await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(action.id))).go();
          } else if (action.actionType == 'mark_attendance') {
            // Future implementation for attendance
            await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(action.id))).go();
          } else {
            // Unknown action type, delete to prevent infinite loops
            await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(action.id))).go();
          }
        } catch (e) {
          debugPrint('[SyncService] Failed to sync action ${action.id}: $e');
          // Leave it in the queue for next time
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Manually trigger a sync
  Future<void> triggerSync() => _syncPendingActions();
}
