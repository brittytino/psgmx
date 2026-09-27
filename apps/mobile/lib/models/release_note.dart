/// Release Note Model
///
/// Represents a single entry in the [app_release_notes] Supabase table.
/// Fetched by [UpdateService] and displayed in [WhatsNewScreen].
library;

class ReleaseNote {
  /// Semantic version string, e.g. "4.3.2"
  final String version;

  /// Display title, e.g. "What's New in v4.3.2"
  final String title;

  /// Short bullet-point highlights (shown as list items)
  final List<String> highlights;

  /// Optional longer description paragraph
  final String? description;

  /// Release date
  final DateTime releaseDate;

  /// Target platform: 'android', 'ios', or 'all'
  final String platform;

  const ReleaseNote({
    required this.version,
    required this.title,
    required this.highlights,
    this.description,
    required this.releaseDate,
    this.platform = 'all',
  });

  factory ReleaseNote.fromMap(Map<String, dynamic> map) {
    return ReleaseNote(
      version: map['version'] as String? ?? '',
      title: map['title'] as String? ?? 'What\'s New',
      highlights: List<String>.from(map['highlights'] as List? ?? const []),
      description: map['description'] as String?,
      releaseDate: map['release_date'] != null
          ? DateTime.tryParse(map['release_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      platform: map['platform'] as String? ?? 'all',
    );
  }

  Map<String, dynamic> toMap() => {
        'version': version,
        'title': title,
        'highlights': highlights,
        'description': description,
        'release_date': releaseDate.toIso8601String().substring(0, 10),
        'platform': platform,
      };

  @override
  String toString() => 'ReleaseNote(version: $version, highlights: ${highlights.length} items)';
}
