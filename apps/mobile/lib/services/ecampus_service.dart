import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/ecampus_attendance.dart';

/// Attendance-only eCampus access. The mobile build contains no integration
/// secret; refresh requests are authenticated with the student's Supabase
/// session and brokered by the trusted PSGMX web API.
class EcampusService {
  static final EcampusService _instance = EcampusService._internal();
  factory EcampusService() => _instance;
  EcampusService._internal();

  final _supabase = Supabase.instance.client;

  Future<void> syncUser(String rollno) async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) throw Exception('Please sign in again.');
    final response = await http.post(
      Uri.parse('${SupabaseConfig.appApiUrl}/api/ecampus/sync'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 95));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['error'] ?? 'Attendance could not be refreshed.');
      } on FormatException {
        throw Exception('Attendance could not be refreshed.');
      }
    }
  }

  Future<EcampusAttendance?> getAttendance(String rollno) async {
    try {
      final result = await _supabase
          .from('ecampus_attendance')
          .select('reg_no, data, synced_at')
          .eq('reg_no', rollno)
          .maybeSingle();
      return result == null ? null : EcampusAttendance.fromSupabase(result);
    } catch (error) {
      debugPrint('[EcampusService] attendance read failed: $error');
      rethrow;
    }
  }

  Stream<EcampusAttendance?> attendanceStream(String rollno) {
    return _supabase
        .from('ecampus_attendance')
        .stream(primaryKey: ['id'])
        .eq('reg_no', rollno)
        .map((rows) =>
            rows.isEmpty ? null : EcampusAttendance.fromSupabase(rows.first));
  }
}
