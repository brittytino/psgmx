import 'package:flutter_test/flutter_test.dart';
import 'package:psgmx_mobile/core/utils/version_comparator.dart';

void main() {
  group('SemanticVersion', () {
    test('parses release tags and ignores build metadata in precedence', () {
      expect(SemanticVersion.parse('v4.2.0+15').toString(), '4.2.0+15');
      expect(
        SemanticVersion.parse('4.2.0+15')
            .compareTo(SemanticVersion.parse('4.2.0+16')),
        0,
      );
    });

    test('rejects malformed values so update checks fail open', () {
      expect(SemanticVersion.tryParse('latest'), isNull);
      expect(
        VersionComparator.isUpdateRequired(
          currentVersion: 'latest',
          minRequiredVersion: '4.0.0',
        ),
        isFalse,
      );
    });

    test('orders prerelease identifiers using semantic-version rules', () {
      expect(
        SemanticVersion.parse('4.2.0-beta.2') <
            SemanticVersion.parse('4.2.0-beta.10'),
        isTrue,
      );
      expect(
        SemanticVersion.parse('4.2.0-rc.1') < SemanticVersion.parse('4.2.0'),
        isTrue,
      );
    });
  });

  test('update status respects emergency, required, and optional versions', () {
    expect(
      VersionComparator.getUpdateStatus(
        currentVersion: '4.2.0',
        minRequiredVersion: '4.0.0',
        latestVersion: '4.2.0',
        forceUpdate: false,
        emergencyBlock: false,
      ),
      UpdateStatus.upToDate,
    );
    expect(
      VersionComparator.getUpdateStatus(
        currentVersion: '4.1.0',
        minRequiredVersion: '4.0.0',
        latestVersion: '4.2.0',
        forceUpdate: false,
        emergencyBlock: false,
      ),
      UpdateStatus.optionalUpdateAvailable,
    );
    expect(
      VersionComparator.getUpdateStatus(
        currentVersion: '4.1.0',
        minRequiredVersion: '4.2.0',
        latestVersion: '4.2.0',
        forceUpdate: false,
        emergencyBlock: false,
      ),
      UpdateStatus.forceUpdateRequired,
    );
    expect(
      VersionComparator.getUpdateStatus(
        currentVersion: '4.2.0',
        minRequiredVersion: '4.0.0',
        latestVersion: '4.2.0',
        forceUpdate: false,
        emergencyBlock: true,
      ),
      UpdateStatus.emergencyBlocked,
    );
  });
}
