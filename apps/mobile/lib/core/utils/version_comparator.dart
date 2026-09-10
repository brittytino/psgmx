/// Semantic Version Comparison Utility
/// Provides safe, correct version comparison for app updates
///
/// Handles versions like:
/// - "1.0.0"
/// - "1.2.3"
/// - "2.0.0-beta"
/// - "1.0.0+build123"
library;

class SemanticVersion implements Comparable<SemanticVersion> {
  final int major;
  final int minor;
  final int patch;
  final String? preRelease;
  final String? buildMetadata;

  const SemanticVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.preRelease,
    this.buildMetadata,
  });

  /// Parse a version string like "1.2.3", "1.2.3-beta", or "1.2.3+build"
  factory SemanticVersion.parse(String version) {
    final match = RegExp(
      r'^[vV]?(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+([0-9A-Za-z.-]+))?$',
    ).firstMatch(version.trim());
    if (match == null) {
      throw FormatException('Invalid semantic version', version);
    }

    return SemanticVersion(
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: int.parse(match.group(3)!),
      preRelease: match.group(4),
      buildMetadata: match.group(5),
    );
  }

  /// Try to parse, returns null on failure
  static SemanticVersion? tryParse(String version) {
    try {
      return SemanticVersion.parse(version);
    } catch (_) {
      return null;
    }
  }

  /// Compare two versions
  /// Returns:
  ///   negative if this < other
  ///   zero if this == other
  ///   positive if this > other
  @override
  int compareTo(SemanticVersion other) {
    // Compare major
    if (major != other.major) {
      return major.compareTo(other.major);
    }

    // Compare minor
    if (minor != other.minor) {
      return minor.compareTo(other.minor);
    }

    // Compare patch
    if (patch != other.patch) {
      return patch.compareTo(other.patch);
    }

    // Handle pre-release comparison
    // A version WITHOUT pre-release is GREATER than one WITH pre-release
    // e.g., 1.0.0 > 1.0.0-beta
    if (preRelease == null && other.preRelease != null) {
      return 1; // This is greater (stable > pre-release)
    }
    if (preRelease != null && other.preRelease == null) {
      return -1; // This is lesser (pre-release < stable)
    }
    if (preRelease != null && other.preRelease != null) {
      final currentParts = preRelease!.split('.');
      final otherParts = other.preRelease!.split('.');
      final sharedLength = currentParts.length < otherParts.length
          ? currentParts.length
          : otherParts.length;

      for (var index = 0; index < sharedLength; index++) {
        final currentPart = currentParts[index];
        final otherPart = otherParts[index];
        final currentNumber = int.tryParse(currentPart);
        final otherNumber = int.tryParse(otherPart);

        if (currentNumber != null && otherNumber != null) {
          final comparison = currentNumber.compareTo(otherNumber);
          if (comparison != 0) return comparison;
        } else if (currentNumber != null) {
          return -1;
        } else if (otherNumber != null) {
          return 1;
        } else {
          final comparison = currentPart.compareTo(otherPart);
          if (comparison != 0) return comparison;
        }
      }
      return currentParts.length.compareTo(otherParts.length);
    }

    // Build metadata is ignored in precedence
    return 0;
  }

  /// Operators for easy comparison
  bool operator <(SemanticVersion other) => compareTo(other) < 0;
  bool operator <=(SemanticVersion other) => compareTo(other) <= 0;
  bool operator >(SemanticVersion other) => compareTo(other) > 0;
  bool operator >=(SemanticVersion other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SemanticVersion) return false;
    return major == other.major &&
        minor == other.minor &&
        patch == other.patch &&
        preRelease == other.preRelease;
  }

  @override
  int get hashCode => Object.hash(major, minor, patch, preRelease);

  @override
  String toString() {
    final buffer = StringBuffer('$major.$minor.$patch');
    if (preRelease != null) {
      buffer.write('-$preRelease');
    }
    if (buildMetadata != null) {
      buffer.write('+$buildMetadata');
    }
    return buffer.toString();
  }
}

/// Utility class for version comparisons
class VersionComparator {
  /// Check if current version is older than required
  static bool isUpdateRequired({
    required String currentVersion,
    required String minRequiredVersion,
  }) {
    final current = SemanticVersion.tryParse(currentVersion);
    final required = SemanticVersion.tryParse(minRequiredVersion);

    if (current == null || required == null) {
      // If parsing fails, be safe and don't force update
      return false;
    }

    return current < required;
  }

  /// Check if a newer version is available (optional update)
  static bool isNewerVersionAvailable({
    required String currentVersion,
    required String latestVersion,
  }) {
    final current = SemanticVersion.tryParse(currentVersion);
    final latest = SemanticVersion.tryParse(latestVersion);

    if (current == null || latest == null) {
      return false;
    }

    return current < latest;
  }

  /// Get update status
  static UpdateStatus getUpdateStatus({
    required String currentVersion,
    required String minRequiredVersion,
    required String latestVersion,
    required bool forceUpdate,
    required bool emergencyBlock,
  }) {
    // Emergency block takes highest priority
    if (emergencyBlock) {
      return UpdateStatus.emergencyBlocked;
    }

    final current = SemanticVersion.tryParse(currentVersion);
    final minRequired = SemanticVersion.tryParse(minRequiredVersion);
    final latest = SemanticVersion.tryParse(latestVersion);

    // If parsing fails, allow app to continue (fail-open)
    if (current == null || minRequired == null || latest == null) {
      return UpdateStatus.upToDate;
    }

    // Check if below minimum required version
    if (current < minRequired) {
      return UpdateStatus.forceUpdateRequired;
    }

    // Check if newer version available
    if (current < latest) {
      return forceUpdate
          ? UpdateStatus.forceUpdateRequired
          : UpdateStatus.optionalUpdateAvailable;
    }

    return UpdateStatus.upToDate;
  }
}

/// Enum representing update status
enum UpdateStatus {
  /// App is up to date, no action needed
  upToDate,

  /// A newer version is available but not required
  optionalUpdateAvailable,

  /// User MUST update to continue using the app
  forceUpdateRequired,

  /// App is emergency blocked - cannot be used at all
  emergencyBlocked,
}
