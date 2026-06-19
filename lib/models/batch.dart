/// Represents one MCA batch (e.g. "25MX" or "26MX").
///
/// At any point exactly two batches are active — one [activeSenior] going
/// through placements and one [activeJunior] one year behind them.
/// Graduated batches keep their data visible but lose login access.
enum BatchStatus { activeSenior, activeJunior, graduated }

extension BatchStatusExtension on BatchStatus {
  String get dbValue {
    switch (this) {
      case BatchStatus.activeSenior:
        return 'active_senior';
      case BatchStatus.activeJunior:
        return 'active_junior';
      case BatchStatus.graduated:
        return 'graduated';
    }
  }

  bool get isActive =>
      this == BatchStatus.activeSenior || this == BatchStatus.activeJunior;

  static BatchStatus fromDb(String value) {
    switch (value) {
      case 'active_senior':
        return BatchStatus.activeSenior;
      case 'active_junior':
        return BatchStatus.activeJunior;
      default:
        return BatchStatus.graduated;
    }
  }
}

class Batch {
  final String id;
  final String batchCode; // e.g. '25MX'
  final int startYear;
  final int endYear;
  final BatchStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Batch({
    required this.id,
    required this.batchCode,
    required this.startYear,
    required this.endYear,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Batch.fromMap(Map<String, dynamic> data) {
    return Batch(
      id: data['id'] as String,
      batchCode: data['batch_code'] as String,
      startYear: data['start_year'] as int,
      endYear: data['end_year'] as int,
      status: BatchStatusExtension.fromDb(data['status'] as String),
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'batch_code': batchCode,
        'start_year': startYear,
        'end_year': endYear,
        'status': status.dbValue,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  bool get isSenior => status == BatchStatus.activeSenior;
  bool get isJunior => status == BatchStatus.activeJunior;
  bool get isGraduated => status == BatchStatus.graduated;

  /// Parses the batch code from a roll number string.
  /// Roll numbers contain a 2-digit year prefix, e.g. "25MX001" → "25MX".
  static String? parseBatchCodeFromRollNo(String rollNo) {
    final cleaned = rollNo.trim().toUpperCase();
    // Match patterns like "25MX", "26MX" at the start of the roll number
    final match = RegExp(r'^(\d{2}MX)').firstMatch(cleaned);
    return match?.group(1);
  }

  @override
  String toString() => 'Batch($batchCode, $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Batch && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
