/// A company that visited campus for a placement drive.
/// Created by the Placement Rep or a Coordinator with [manage_company_records].
class Company {
  final String id;
  final String batchId;
  final String name;
  final DateTime visitDate;
  final List<String> rolesOffered;
  final String? packageBand;
  final String? eligibility;
  /// List of round descriptors, e.g. [{name: "Aptitude", type: "online", ...}]
  final List<Map<String, dynamic>> rounds;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Company({
    required this.id,
    required this.batchId,
    required this.name,
    required this.visitDate,
    required this.rolesOffered,
    this.packageBand,
    this.eligibility,
    this.rounds = const [],
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Company.fromMap(Map<String, dynamic> data) {
    final rawRoles = data['roles_offered'];
    List<String> roles;
    if (rawRoles is List) {
      roles = rawRoles.map((e) => e.toString()).toList();
    } else {
      roles = [];
    }

    final rawRounds = data['rounds'];
    List<Map<String, dynamic>> rounds = [];
    if (rawRounds is List) {
      rounds = rawRounds.cast<Map<String, dynamic>>();
    }

    return Company(
      id: data['id'] as String,
      batchId: data['batch_id'] as String,
      name: data['name'] as String,
      visitDate: DateTime.parse(data['visit_date'] as String),
      rolesOffered: roles,
      packageBand: data['package_band'] as String?,
      eligibility: data['eligibility'] as String?,
      rounds: rounds,
      createdBy: data['created_by'] as String,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'batch_id': batchId,
        'name': name,
        'visit_date': visitDate.toIso8601String().split('T')[0],
        'roles_offered': rolesOffered,
        'package_band': packageBand,
        'eligibility': eligibility,
        'rounds': rounds,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Company && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// A personal round-by-round experience entry written by a second-year student.
/// Read-only for first-year and graduated batches.
class PlacementLogEntry {
  final String id;
  final String companyId;
  final String userId;
  final String roundName;
  final String experienceText;
  final bool isModerated;
  final String? moderatedBy;
  final String? outcome;
  final bool? isAnonymous;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlacementLogEntry({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.roundName,
    required this.experienceText,
    this.isModerated = false,
    this.moderatedBy,
    this.outcome,
    this.isAnonymous,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlacementLogEntry.fromMap(Map<String, dynamic> data) {
    return PlacementLogEntry(
      id: data['id'] as String,
      companyId: data['company_id'] as String,
      userId: data['user_id'] as String,
      roundName: data['round_name'] as String,
      experienceText: data['experience_text'] as String,
      isModerated: data['is_moderated'] as bool? ?? false,
      moderatedBy: data['moderated_by'] as String?,
      outcome: data['outcome'] as String?,
      isAnonymous: data['is_anonymous'] as bool?,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'user_id': userId,
        'round_name': roundName,
        'experience_text': experienceText,
        'is_moderated': isModerated,
        'moderated_by': moderatedBy,
        'outcome': outcome,
        'is_anonymous': isAnonymous,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
