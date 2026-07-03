import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../services/supabase_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;
  final Map<String, String> _emailToUid = {};

  List<AppUser> _teamMembers = [];
  List<AppUser> get teamMembers => _teamMembers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasSubmittedToday = false;
  bool get hasSubmittedToday => _hasSubmittedToday;

  final Map<String, String> _statusMap = {};
  Map<String, String> get statusMap => _statusMap;

  AttendanceProvider(this._supabaseService);

  Future<void> _preloadStatuses(String? teamId, String dateStr) async {
    try {
      // Find the session ID for this date
      final sessionResponse = await _supabaseService.client
          .from('placement_sessions')
          .select('id')
          .gte('session_datetime', '${dateStr}T00:00:00Z')
          .lte('session_datetime', '${dateStr}T23:59:59Z')
          .maybeSingle();
          
      if (sessionResponse == null) return;
      final sessionId = sessionResponse['id'];

      var query = _supabaseService.client
          .from('placement_attendance')
          .select('student_id, status')
          .eq('session_id', sessionId);

      final response = await query;

      _statusMap.clear();
      for (var record in response as List) {
        final key = record['student_id'];
        if (key != null) {
          _statusMap[key] = (record['status'] as String).toUpperCase();
        }
      }
    } catch (e) {
      debugPrint('Error preloading status: $e');
    }
  }

  Future<void> loadTeamMembers(String teamId, {DateTime? forDate}) async {
    _isLoading = true;
    notifyListeners();

    final dateStr = (forDate ?? DateTime.now()).toIso8601String().split('T')[0];

    try {
      // 1. Fetch from users
      final whiteListResponse = await _supabaseService.client
          .from('users')
          .select()
          .eq('team_id', teamId)
          .eq('role', 'student')
          .order('roll_no');

      final List<dynamic> whitelistStudents = whiteListResponse as List;
      final List<String> emails =
          whitelistStudents.map((e) => e['email'] as String).toList();

      // 2. Fetch actual user IDs from users table (who have signed up)
      final usersResponse = await _supabaseService.client
          .from('users')
          .select('id, email')
          .inFilter('email', emails);

      final Map<String, String> emailToUid = {
        for (var u in usersResponse as List)
          u['email'] as String: u['id'] as String
      };
      _emailToUid
        ..clear()
        ..addAll(emailToUid);

      // 3. Merge
      _teamMembers = whitelistStudents.map((e) {
        final email = e['email'] as String;
        return AppUser(
          uid: emailToUid[email] ?? email, // Real UID or fallback to email
          email: email,
          regNo: e['roll_no'] ?? e['reg_no'],
          name: e['full_name'] ?? e['name'],
          teamId: e['team_id'],
          batch: e['batch'],
          roles: e['roles'] != null
              ? UserRoles.fromJson(Map<String, dynamic>.from(e['roles']))
              : const UserRoles(),
          leetcodeUsername: e['leetcode_username'],
          dob: e['dob'] != null ? DateTime.parse(e['dob']) : null,
        );
      }).toList();

      // Check if already submitted for the selected date
      await _checkSubmissionStatus(teamId, dateStr);

      // Always preload existing statuses for the selected date so the UI
      // pre-fills any previously-saved records (whether or not fully submitted).
      await _preloadStatuses(teamId, dateStr);
    } catch (e) {
      debugPrint('Error loading team: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllUsers({DateTime? forDate}) async {
    _isLoading = true;
    notifyListeners();

    final dateStr = (forDate ?? DateTime.now()).toIso8601String().split('T')[0];

    try {
      // 1. Fetch from users
      final whiteListResponse = await _supabaseService.client
          .from('users')
          .select()
          .eq('role', 'student')
          .order('roll_no');

      final List<dynamic> whitelistStudents = whiteListResponse as List;
      final List<String> emails =
          whitelistStudents.map((e) => e['email'] as String).toList();

      // 2. Fetch actual user IDs from users table
      final usersResponse = await _supabaseService.client
          .from('users')
          .select('id, email')
          .inFilter('email', emails);

      final Map<String, String> emailToUid = {
        for (var u in usersResponse as List)
          u['email'] as String: u['id'] as String
      };
      _emailToUid
        ..clear()
        ..addAll(emailToUid);

      // 3. Merge
      _teamMembers = whitelistStudents.map((e) {
        final email = e['email'] as String;
        return AppUser(
          uid: emailToUid[email] ?? email,
          email: email,
          regNo: e['roll_no'] ?? e['reg_no'],
          name: e['full_name'] ?? e['name'],
          teamId: e['team_id'],
          batch: e['batch'],
          roles: e['roles'] != null
              ? UserRoles.fromJson(Map<String, dynamic>.from(e['roles']))
              : const UserRoles(),
          leetcodeUsername: e['leetcode_username'],
          dob: e['dob'] != null ? DateTime.parse(e['dob']) : null,
        );
      }).toList();

      // Always preload existing records for the selected date (Reps can always edit)
      await _preloadStatuses(null, dateStr);

      _hasSubmittedToday = false; // Reps can always edit/submit in this mode
    } catch (e) {
      debugPrint('Error loading all users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkSubmissionStatus(String teamId, String dateStr) async {
    try {
      final sessionResponse = await _supabaseService.client
          .from('placement_sessions')
          .select('id')
          .gte('session_datetime', '${dateStr}T00:00:00Z')
          .lte('session_datetime', '${dateStr}T23:59:59Z')
          .maybeSingle();
      
      if (sessionResponse == null) {
        _hasSubmittedToday = false;
        return;
      }
      final sessionId = sessionResponse['id'];

      // Note: placement_attendance does not have team_id, but the UI considers it submitted if any records exist for these students. 
      // For now, if the session has any attendance, we just say submitted (or we could check for specific student, but the UI is mostly 'has anyone marked it').
      final count = await _supabaseService.client
          .from('placement_attendance')
          .count()
          .eq('session_id', sessionId);
          
      _hasSubmittedToday = count > 0;
    } catch (e) {
      debugPrint('Error checking submission status: $e');
      _hasSubmittedToday = false;
    }
  }

  Future<void> submitAttendance(
    String? teamId,
    Map<String, String> statusMap, {
    DateTime? forDate,
    bool isRep = false,
  }) async {
    final selectedDate = forDate ?? DateTime.now();
    final normalizedSelected =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (normalizedSelected.isAfter(today)) {
      throw Exception('Attendance cannot be marked for future dates.');
    }

    final dateStr = normalizedSelected.toIso8601String().split('T')[0];
    final user = _supabaseService.client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final List<Map<String, dynamic>> rows = [];
    final List<String> skippedUnregistered = [];

    // UUID regex pattern
    final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

    for (var entry in statusMap.entries) {
      final studentIdOrEmail = entry.key;
      final status = entry.value;

      // Find student in team members (works for both registered and unregistered)
      final student = _teamMembers.firstWhere(
        (m) => m.uid == studentIdOrEmail,
        orElse: () => AppUser(
          uid: studentIdOrEmail,
          email: studentIdOrEmail,
          regNo: '',
          name: '',
          teamId: teamId,
          batch: '',
          roles: const UserRoles(),
        ),
      );
      final studentTeamId = student.teamId ?? teamId ?? 'ALL';

      String? resolvedUserId;
      if (uuidRegex.hasMatch(studentIdOrEmail)) {
        resolvedUserId = studentIdOrEmail;
      } else {
        resolvedUserId = _emailToUid[student.email];
      }

      // Skip whitelist-only members who have not completed registration yet.
      if (resolvedUserId == null) {
        skippedUnregistered.add(
          student.name.isNotEmpty ? student.name : student.email,
        );
        continue;
      }

      rows.add({
        'session_id': 'TO_BE_REPLACED', // Will be filled below
        'student_id': resolvedUserId,
        'status': status.toLowerCase(),
        'marked_by': user.id,
      });
    }

    if (rows.isEmpty) {
      if (skippedUnregistered.isNotEmpty) {
        throw Exception(
          'No registered students available to mark attendance. ${skippedUnregistered.length} selected students are not registered yet.',
        );
      }
      throw Exception('No valid students to mark attendance for.');
    }

    // Find or create session ID
    var sessionResponse = await _supabaseService.client
        .from('placement_sessions')
        .select('id')
        .gte('session_datetime', '${dateStr}T00:00:00Z')
        .lte('session_datetime', '${dateStr}T23:59:59Z')
        .maybeSingle();

    String sessionId;
    if (sessionResponse == null) {
      // If no session exists for this date, create one automatically
      final newSession = await _supabaseService.client.from('placement_sessions').insert({
        'session_datetime': '${dateStr}T00:00:00Z',
        'topic': 'Scheduled Session',
        'scheduled_by': user.id,
        'batch_id': '00000000-0000-0000-0000-000000000000',
      }).select().single();
      sessionId = newSession['id'];
    } else {
      sessionId = sessionResponse['id'];
    }

    for (var row in rows) {
      row['session_id'] = sessionId;
    }

    // Upsert on (session_id, student_id) conflict
    await _supabaseService.client
        .from('placement_attendance')
        .upsert(rows, onConflict: 'session_id,student_id');

    if (!isRep && teamId != null) {
      _hasSubmittedToday = true;
    }
    notifyListeners();

    debugPrint(
        '[Attendance] Successfully marked attendance for ${rows.length} students');
    if (skippedUnregistered.isNotEmpty) {
      debugPrint(
        '[Attendance] Skipped ${skippedUnregistered.length} unregistered students during submission',
      );
    }
  }
}
