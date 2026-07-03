/// A single placement-prep session scheduled by the Rep or a Coordinator.
/// Sessions can target the whole batch ([targetTeamIds] is null) or a
/// specific subset of teams.
class PlacementSession {
  final String id;
  final String batchId;
  final String scheduledBy;
  final DateTime sessionDatetime;
  final String topic;
  final String? description;
  final String sessionType;
  final String sessionMode;
  final int durationMinutes;
  final String location;
  final bool isLocked;
  /// Null means all teams in the batch are eligible for this session.
  final List<String>? targetTeamIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlacementSession({
    required this.id,
    required this.batchId,
    required this.scheduledBy,
    required this.sessionDatetime,
    required this.topic,
    this.description,
    this.sessionType = 'Other',
    this.sessionMode = 'Offline',
    this.durationMinutes = 60,
    this.location = 'TBA',
    this.isLocked = false,
    this.targetTeamIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlacementSession.fromMap(Map<String, dynamic> data) {
    List<String>? teamIds;
    final raw = data['target_team_ids'];
    if (raw is List && raw.isNotEmpty) {
      teamIds = raw.map((e) => e.toString()).toList();
    }

    return PlacementSession(
      id: data['id'] as String,
      batchId: data['batch_id'] as String,
      scheduledBy: data['scheduled_by'] as String,
      sessionDatetime: DateTime.parse(data['session_datetime'] as String),
      topic: data['topic'] as String,
      description: data['description'] as String?,
      sessionType: data['session_type'] as String? ?? 'Other',
      sessionMode: data['session_mode'] as String? ?? 'Offline',
      durationMinutes: data['duration_minutes'] as int? ?? 60,
      location: data['location'] as String? ?? 'TBA',
      isLocked: data['is_locked'] as bool? ?? false,
      targetTeamIds: teamIds,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'batch_id': batchId,
        'scheduled_by': scheduledBy,
        'session_datetime': sessionDatetime.toIso8601String(),
        'topic': topic,
        'description': description,
        'session_type': sessionType,
        'session_mode': sessionMode,
        'duration_minutes': durationMinutes,
        'location': location,
        'is_locked': isLocked,
        'target_team_ids': targetTeamIds,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// True if this session targets the entire batch.
  bool get isBatchWide => targetTeamIds == null || targetTeamIds!.isEmpty;

  /// Whether this session targets the given team.
  bool isTargetedAt(String teamId) =>
      isBatchWide || (targetTeamIds?.contains(teamId) ?? false);

  bool get isUpcoming => sessionDatetime.isAfter(DateTime.now());
  bool get isPast => sessionDatetime.isBefore(DateTime.now());
}

/// Attendance status for one student in one placement session.
enum PlacementAttendanceStatus { present, absent, excused }

extension PlacementAttendanceStatusExt on PlacementAttendanceStatus {
  String get dbValue {
    switch (this) {
      case PlacementAttendanceStatus.present:
        return 'present';
      case PlacementAttendanceStatus.absent:
        return 'absent';
      case PlacementAttendanceStatus.excused:
        return 'excused';
    }
  }

  static PlacementAttendanceStatus fromDb(String v) {
    switch (v) {
      case 'present':
        return PlacementAttendanceStatus.present;
      case 'excused':
        return PlacementAttendanceStatus.excused;
      default:
        return PlacementAttendanceStatus.absent;
    }
  }
}

/// One row from the `placement_attendance` table.
class PlacementAttendanceRecord {
  final String sessionId;
  final String userId;
  final PlacementAttendanceStatus status;
  final String markedBy;
  final DateTime markedAt;
  final String? notes;

  const PlacementAttendanceRecord({
    required this.sessionId,
    required this.userId,
    required this.status,
    required this.markedBy,
    required this.markedAt,
    this.notes,
  });

  factory PlacementAttendanceRecord.fromMap(Map<String, dynamic> data) {
    return PlacementAttendanceRecord(
      sessionId: data['session_id'] as String,
      userId: data['user_id'] as String,
      status: PlacementAttendanceStatusExt.fromDb(data['status'] as String),
      markedBy: data['marked_by'] as String,
      markedAt: DateTime.parse(data['marked_at'] as String),
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'session_id': sessionId,
        'user_id': userId,
        'status': status.dbValue,
        'marked_by': markedBy,
        'marked_at': markedAt.toIso8601String(),
        'notes': notes,
      };
}

/// Summary of a user's overall placement attendance.
class PlacementAttendanceSummary {
  final String userId;
  final int eligibleSessions;
  final int attendedSessions;
  final double attendancePct;

  const PlacementAttendanceSummary({
    required this.userId,
    required this.eligibleSessions,
    required this.attendedSessions,
    required this.attendancePct,
  });

  factory PlacementAttendanceSummary.fromMap(Map<String, dynamic> data) {
    return PlacementAttendanceSummary(
      userId: data['user_id'] as String,
      eligibleSessions: (data['eligible_sessions'] as num).toInt(),
      attendedSessions: (data['attended_sessions'] as num).toInt(),
      attendancePct: double.tryParse(
              data['attendance_pct']?.toString() ?? '0') ??
          0.0,
    );
  }
}
