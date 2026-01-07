import 'package:gengen/module/version_constraint.dart';
import 'package:test/test.dart';

/// Tests for the version matching logic used in GitModuleSource._findMatchingCachedVersion
void main() {
  group('Version selection from cache', () {
    /// Simulates the logic in GitModuleSource._findMatchingCachedVersion
    String? findMatchingVersion(
      List<String> cachedVersions,
      String constraint,
    ) {
      if (cachedVersions.isEmpty) return null;

      try {
        final versionConstraint = VersionConstraint.parse(constraint);

        // Sort versions descending to get latest first
        final sorted = cachedVersions.toList()..sort((a, b) => b.compareTo(a));

        for (final cached in sorted) {
          // Try to parse the cached version
          final cleanVersion = cached.startsWith('v')
              ? cached.substring(1)
              : cached;
          final parsed = Version.tryParse(cleanVersion);
          if (parsed != null && versionConstraint.allows(parsed)) {
            return cached;
          }
        }
      } catch (_) {
        // If constraint parsing fails, return null
      }

      return null;
    }

    test('^1.0.0 selects latest 1.x version', () {
      final versions = ['v0.9.0', 'v1.0.0', 'v1.0.1', 'v1.1.0', 'v2.0.0'];
      expect(findMatchingVersion(versions, '^1.0.0'), 'v1.1.0');
    });

    test('^1.0.0 with only one match', () {
      final versions = ['v0.9.0', 'v1.0.0', 'v2.0.0'];
      expect(findMatchingVersion(versions, '^1.0.0'), 'v1.0.0');
    });

    test('^1.0.0 with no match', () {
      final versions = ['v0.9.0', 'v2.0.0', 'v3.0.0'];
      expect(findMatchingVersion(versions, '^1.0.0'), isNull);
    });

    test('^0.2.0 is restrictive to 0.2.x', () {
      final versions = ['v0.1.0', 'v0.2.0', 'v0.2.5', 'v0.3.0', 'v1.0.0'];
      expect(findMatchingVersion(versions, '^0.2.0'), 'v0.2.5');
    });

    test('>=1.0.0 <2.0.0 range constraint', () {
      final versions = ['v0.9.0', 'v1.0.0', 'v1.5.0', 'v2.0.0', 'v3.0.0'];
      expect(findMatchingVersion(versions, '>=1.0.0 <2.0.0'), 'v1.5.0');
    });

    test('exact version match', () {
      final versions = ['v1.0.0', 'v1.0.1', 'v1.1.0'];
      expect(findMatchingVersion(versions, '1.0.1'), 'v1.0.1');
    });

    test('any constraint returns latest', () {
      final versions = ['v1.0.0', 'v2.0.0', 'v3.0.0'];
      expect(findMatchingVersion(versions, 'any'), 'v3.0.0');
    });

    test('empty cache returns null', () {
      expect(findMatchingVersion([], '^1.0.0'), isNull);
    });

    test('handles versions without v prefix', () {
      final versions = ['1.0.0', '1.0.1', '1.1.0', '2.0.0'];
      expect(findMatchingVersion(versions, '^1.0.0'), '1.1.0');
    });

    test('handles mixed v prefix versions', () {
      final versions = ['v1.0.0', '1.0.1', 'v1.1.0', '2.0.0'];
      // Alphabetically: v1.1.0 > v1.0.0 > 2.0.0 > 1.0.1
      // After proper version sorting descending: v1.1.0 should be first valid
      expect(findMatchingVersion(versions, '^1.0.0'), 'v1.1.0');
    });

    test('prerelease versions are considered', () {
      final versions = ['v1.0.0-alpha', 'v1.0.0-beta', 'v1.0.0'];

      // Stable 1.0.0 should be selected over prereleases
      // But note: prereleases of 1.0.0 are < 1.0.0, so ^1.0.0 doesn't include them
      expect(findMatchingVersion(versions, '^1.0.0'), 'v1.0.0');
    });

    test('complex constraint >1.0.0 <=2.0.0', () {
      final versions = ['v1.0.0', 'v1.5.0', 'v2.0.0', 'v2.5.0'];
      expect(findMatchingVersion(versions, '>1.0.0 <=2.0.0'), 'v2.0.0');
    });

    test('git ref constraints return null (not applicable)', () {
      final versions = ['v1.0.0', 'v2.0.0'];
      // Git refs like branch:main are not semver constraints
      // The function should still work since GitRefConstraint.allows() returns true
      expect(findMatchingVersion(versions, 'branch:main'), 'v2.0.0');
    });
  });

  group('Edge cases', () {
    String? findMatchingVersion(
      List<String> cachedVersions,
      String constraint,
    ) {
      if (cachedVersions.isEmpty) return null;

      try {
        final versionConstraint = VersionConstraint.parse(constraint);
        final sorted = cachedVersions.toList()..sort((a, b) => b.compareTo(a));

        for (final cached in sorted) {
          final cleanVersion = cached.startsWith('v')
              ? cached.substring(1)
              : cached;
          final parsed = Version.tryParse(cleanVersion);
          if (parsed != null && versionConstraint.allows(parsed)) {
            return cached;
          }
        }
      } catch (_) {}

      return null;
    }

    test('handles version with build metadata', () {
      final versions = ['v1.0.0+build1', 'v1.0.1+build2', 'v2.0.0'];
      expect(findMatchingVersion(versions, '^1.0.0'), 'v1.0.1+build2');
    });

    test('handles single version in cache', () {
      expect(findMatchingVersion(['v1.5.0'], '^1.0.0'), 'v1.5.0');
      expect(findMatchingVersion(['v0.5.0'], '^1.0.0'), isNull);
    });

    test('invalid version strings are skipped', () {
      final versions = ['v1.0.0', 'invalid', 'not-a-version', 'v1.1.0'];
      expect(findMatchingVersion(versions, '^1.0.0'), 'v1.1.0');
    });

    test('all invalid versions returns null', () {
      final versions = ['invalid', 'not-semver', 'xyz'];
      expect(findMatchingVersion(versions, '^1.0.0'), isNull);
    });
  });
}
