import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/scheduled_date.dart';

class AttendanceScheduleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ========================================
  // SCHEDULED DATES MANAGEMENT
  // ========================================

  /// Check if a date is scheduled for attendance
  Future<bool> isDateScheduled(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final response = await _supabase
          .from('placement_sessions')
          .select('id')
          .gte('session_datetime', '${dateString}T00:00:00Z')
          .lte('session_datetime', '${dateString}T23:59:59Z')
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Failed to check scheduled date: ${e.toString()}');
    }
  }

  /// Get all scheduled dates
  Future<List<ScheduledDate>> getScheduledDates() async {
    try {
      final response = await _supabase
          .from('placement_sessions')
          .select()
          .order('session_datetime', ascending: true);

      return (response as List).map((data) {
        data['date'] = data['session_datetime'];
        data['notes'] = data['topic'];
        return ScheduledDate.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get scheduled dates: ${e.toString()}');
    }
  }

  /// Get scheduled dates in a range
  Future<List<ScheduledDate>> getScheduledDatesInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startString = startDate.toIso8601String().split('T')[0];
      final endString = endDate.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('placement_sessions')
          .select()
          .gte('session_datetime', '${startString}T00:00:00Z')
          .lte('session_datetime', '${endString}T23:59:59Z')
          .order('session_datetime', ascending: true);

      return (response as List).map((data) {
        data['date'] = data['session_datetime'];
        data['notes'] = data['topic'];
        return ScheduledDate.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception(
          'Failed to get scheduled dates in range: ${e.toString()}');
    }
  }

  /// Add a scheduled date (Placement Rep only)
  Future<ScheduledDate> addScheduledDate({
    required DateTime date,
    required String scheduledBy,
    String? notes,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
//      final now = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('placement_sessions')
          .insert({
            'session_datetime': '${dateString}T00:00:00Z',
            'scheduled_by': scheduledBy,
            'topic': notes ?? 'Scheduled Session',
            'batch_id': '00000000-0000-0000-0000-000000000000', // Need proper batch resolution here, but UI doesn't provide it
          })
          .select()
          .single();

      response['date'] = response['session_datetime'];
      response['notes'] = response['topic'];
      return ScheduledDate.fromMap(response);
    } catch (e) {
      throw Exception('Failed to add scheduled date: ${e.toString()}');
    }
  }

  /// Update a scheduled date
  Future<ScheduledDate> updateScheduledDate({
    required String id,
    DateTime? date,
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (date != null) {
        updates['session_datetime'] = '${date.toIso8601String().split('T')[0]}T00:00:00Z';
      }
      if (notes != null) {
        updates['topic'] = notes;
      }

      final response = await _supabase
          .from('placement_sessions')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      response['date'] = response['session_datetime'];
      response['notes'] = response['topic'];
      return ScheduledDate.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update scheduled date: ${e.toString()}');
    }
  }

  /// Delete a scheduled date
  Future<void> deleteScheduledDate(String id) async {
    try {
      await _supabase.from('placement_sessions').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete scheduled date: ${e.toString()}');
    }
  }

  /// Get upcoming scheduled dates (next 30 days)
  Future<List<ScheduledDate>> getUpcomingScheduledDates() async {
    try {
      final now = DateTime.now();
      final thirtyDaysLater = now.add(const Duration(days: 30));

      return await getScheduledDatesInRange(
        startDate: now,
        endDate: thirtyDaysLater,
      );
    } catch (e) {
      throw Exception('Failed to get upcoming scheduled dates: ${e.toString()}');
    }
  }

  /// Check if today is scheduled
  Future<bool> isTodayScheduled() async {
    return await isDateScheduled(DateTime.now());
  }
}
