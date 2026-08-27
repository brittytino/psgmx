import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/ecampus_attendance.dart';
import '../services/ecampus_service.dart';

enum EcampusStatus { initial, loading, syncing, loaded, error }

class EcampusProvider extends ChangeNotifier {
  final EcampusService _service = EcampusService();
  EcampusStatus _status = EcampusStatus.initial;
  EcampusAttendance? _attendance;
  String? _errorMessage;
  String? _currentRollno;
  DateTime? _lastSyncedAt;
  bool _isLoginFailed = false;
  StreamSubscription<EcampusAttendance?>? _subscription;

  EcampusStatus get status => _status;
  EcampusAttendance? get attendance => _attendance;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  bool get isLoading => _status == EcampusStatus.loading;
  bool get isSyncing => _status == EcampusStatus.syncing;
  bool get isLoginFailed => _isLoginFailed;
  bool get hasData => _attendance != null;

  Future<void> init(String rollno) async {
    if (_currentRollno == rollno && _status == EcampusStatus.loaded) return;
    _currentRollno = rollno;
    _setStatus(EcampusStatus.loading);
    try {
      _attendance = await _service.getAttendance(rollno);
      _lastSyncedAt = _attendance?.syncedAt;
      _setStatus(EcampusStatus.loaded);
      await _subscription?.cancel();
      _subscription = _service.attendanceStream(rollno).listen((attendance) {
        _attendance = attendance;
        _lastSyncedAt = attendance?.syncedAt;
        notifyListeners();
      });
    } catch (error) {
      _setError(error.toString());
    }
  }

  Future<void> sync() async {
    if (_currentRollno == null) return;
    _setStatus(EcampusStatus.syncing);
    try {
      await _service.syncUser(_currentRollno!);
      _attendance = await _service.getAttendance(_currentRollno!);
      _lastSyncedAt = _attendance?.syncedAt;
      _setStatus(EcampusStatus.loaded);
    } catch (error) {
      _setError(error.toString());
    }
  }

  Future<void> syncAfterCredentialUpdate(String rollno) async {
    _currentRollno = rollno;
    await sync();
  }

  void _setStatus(EcampusStatus value) {
    _status = value;
    if (value == EcampusStatus.loading || value == EcampusStatus.syncing) {
      _errorMessage = null;
      _isLoginFailed = false;
    }
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message.replaceFirst('Exception: ', '');
    _isLoginFailed = message.toLowerCase().contains('login failed') ||
        message.toLowerCase().contains('password');
    _status = EcampusStatus.error;
    notifyListeners();
  }

  void reset() {
    _subscription?.cancel();
    _subscription = null;
    _status = EcampusStatus.initial;
    _attendance = null;
    _errorMessage = null;
    _currentRollno = null;
    _lastSyncedAt = null;
    _isLoginFailed = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
