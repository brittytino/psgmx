class Announcement {
  final String id;
  final String title;
  final String message;
  final bool isPriority;
  final DateTime? expiryDate;
  final String createdBy;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    this.isPriority = false,
    this.expiryDate,
    required this.createdBy,
    required this.createdAt,
  });

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      isPriority: map['is_priority'] ?? false,
      expiryDate: map['expiry_date'] != null ? DateTime.parse(map['expiry_date']) : null,
      createdBy: map['created_by'] ?? '',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'is_priority': isPriority,
      'expiry_date': expiryDate?.toIso8601String(),
      'created_by': createdBy,
    };
  }
}
