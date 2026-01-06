import 'package:gengen/module/version_constraint.dart';
import 'package:test/test.dart';

void main() {
  group('Version', () {
    test('parses basic version', () {
      final v = Version.parse('1.2.3');
      expect(v.major, 1);
      expect(v.minor, 2);
      expect(v.patch, 3);
    });

    test('parses version with v prefix', () {
      final v = Version.parse('v1.2.3');
      expect(v.major, 1);
      expect(v.minor, 2);
      expect(v.patch, 3);
    });

    test('parses version with prerelease', () {
      final v = Version.parse('1.2.3-beta.1');
      expect(v.major, 1);
      expect(v.minor, 2);
      expect(v.patch, 3);
      expect(v.prerelease, 'beta.1');
    });

    test('parses version with build metadata', () {
      final v = Version.parse('1.2.3+build.456');
      expect(v.major, 1);
      expect(v.minor, 2);
      expect(v.patch, 3);
      expect(v.build, 'build.456');
    });

    test('compares versions correctly', () {
      expect(Version.parse('1.0.0') < Version.parse('2.0.0'), true);
      expect(Version.parse('1.0.0') < Version.parse('1.1.0'), true);
      expect(Version.parse('1.0.0') < Version.parse('1.0.1'), true);
      expect(Version.parse('1.0.0') == Version.parse('1.0.0'), true);
    });

    test('prerelease has lower precedence', () {
      expect(Version.parse('1.0.0-alpha') < Version.parse('1.0.0'), true);
    });

    test('tryParse returns null for invalid versions', () {
      expect(Version.tryParse('invalid'), isNull);
      expect(Version.tryParse('1.2'), isNull);
      expect(Version.tryParse('abc'), isNull);
      expect(Version.tryParse(''), isNull);
    });

    test('tryParse returns Version for valid versions', () {
      expect(Version.tryParse('1.0.0'), isNotNull);
      expect(Version.tryParse('v2.3.4'), isNotNull);
      expect(Version.tryParse('0.0.1-alpha'), isNotNull);
    });

    test('toString formats version correctly', () {
      expect(Version.parse('1.2.3').toString(), '1.2.3');
      expect(Version.parse('1.2.3-beta').toString(), '1.2.3-beta');
      expect(Version(1, 2, 3, build: 'build1').toString(), '1.2.3+build1');
      expect(
        Version(1, 2, 3, prerelease: 'rc1', build: 'b1').toString(),
        '1.2.3-rc1+b1',
      );
    });

    test('comparison operators work correctly', () {
      final v1 = Version.parse('1.0.0');
      final v2 = Version.parse('2.0.0');
      final v1copy = Version.parse('1.0.0');

      expect(v1 < v2, true);
      expect(v1 <= v2, true);
      expect(v1 <= v1copy, true);
      expect(v2 > v1, true);
      expect(v2 >= v1, true);
      expect(v1 >= v1copy, true);
      expect(v1 == v1copy, true);
      expect(v1 == v2, false);
    });
  });

  group('VersionConstraint', () {
    test('parses any constraint', () {
      final c = VersionConstraint.parse('any');
      expect(c, isA<AnyVersionConstraint>());
      expect(c.allows(Version.parse('1.0.0')), true);
      expect(c.allows(Version.parse('99.99.99')), true);
    });

    test('parses empty constraint as any', () {
      final c = VersionConstraint.parse('');
      expect(c, isA<AnyVersionConstraint>());
      expect(c.allows(Version.parse('1.0.0')), true);
    });

    test('parses exact constraint', () {
      final c = VersionConstraint.parse('1.2.3');
      expect(c, isA<ExactConstraint>());
      expect(c.allows(Version.parse('1.2.3')), true);
      expect(c.allows(Version.parse('1.2.4')), false);
    });

    group('CaretConstraint', () {
      test('parses caret constraint', () {
        final c = VersionConstraint.parse('^1.2.3');
        expect(c, isA<CaretConstraint>());
        expect(c.allows(Version.parse('1.2.3')), true);
        expect(c.allows(Version.parse('1.3.0')), true);
        expect(c.allows(Version.parse('1.99.99')), true);
        expect(c.allows(Version.parse('2.0.0')), false);
        expect(c.allows(Version.parse('1.2.2')), false);
      });

      test('^1.0.0 allows 1.x.x but not 2.0.0', () {
        final c = VersionConstraint.parse('^1.0.0');
        expect(c.allows(Version.parse('1.0.0')), true);
        expect(c.allows(Version.parse('1.0.1')), true);
        expect(c.allows(Version.parse('1.5.0')), true);
        expect(c.allows(Version.parse('1.99.99')), true);
        expect(c.allows(Version.parse('2.0.0')), false);
        expect(c.allows(Version.parse('0.9.9')), false);
      });

      test('^0.1.0 allows 0.1.x but not 0.2.0', () {
        final c = VersionConstraint.parse('^0.1.0');
        expect(c.allows(Version.parse('0.1.0')), true);
        expect(c.allows(Version.parse('0.1.5')), true);
        expect(c.allows(Version.parse('0.1.99')), true);
        expect(c.allows(Version.parse('0.2.0')), false);
        expect(c.allows(Version.parse('0.0.9')), false);
        expect(c.allows(Version.parse('1.0.0')), false);
      });

      test('^0.0.3 allows only 0.0.3', () {
        final c = VersionConstraint.parse('^0.0.3');
        expect(c.allows(Version.parse('0.0.3')), true);
        expect(c.allows(Version.parse('0.0.4')), false);
        expect(c.allows(Version.parse('0.0.2')), false);
        expect(c.allows(Version.parse('0.1.0')), false);
      });

      test('caret constraint toString', () {
        expect(VersionConstraint.parse('^1.2.3').toString(), '^1.2.3');
      });
    });

    group('ComparisonConstraint', () {
      test('parses >= constraint', () {
        final c = VersionConstraint.parse('>=1.0.0');
        expect(c.allows(Version.parse('1.0.0')), true);
        expect(c.allows(Version.parse('2.0.0')), true);
        expect(c.allows(Version.parse('0.9.0')), false);
      });

      test('parses > constraint', () {
        final c = VersionConstraint.parse('>1.0.0');
        expect(c.allows(Version.parse('1.0.0')), false);
        expect(c.allows(Version.parse('1.0.1')), true);
        expect(c.allows(Version.parse('2.0.0')), true);
      });

      test('parses <= constraint', () {
        final c = VersionConstraint.parse('<=2.0.0');
        expect(c.allows(Version.parse('2.0.0')), true);
        expect(c.allows(Version.parse('1.9.9')), true);
        expect(c.allows(Version.parse('2.0.1')), false);
      });

      test('parses < constraint', () {
        final c = VersionConstraint.parse('<2.0.0');
        expect(c.allows(Version.parse('1.9.9')), true);
        expect(c.allows(Version.parse('2.0.0')), false);
      });
    });

    group('RangeConstraint', () {
      test('parses range constraint', () {
        final c = VersionConstraint.parse('>=1.0.0 <2.0.0');
        expect(c, isA<RangeConstraint>());
        expect(c.allows(Version.parse('1.0.0')), true);
        expect(c.allows(Version.parse('1.5.0')), true);
        expect(c.allows(Version.parse('0.9.0')), false);
        expect(c.allows(Version.parse('2.0.0')), false);
      });

      test('parses complex range constraint', () {
        final c = VersionConstraint.parse('>1.0.0 <=3.0.0');
        expect(c.allows(Version.parse('1.0.0')), false);
        expect(c.allows(Version.parse('1.0.1')), true);
        expect(c.allows(Version.parse('2.5.0')), true);
        expect(c.allows(Version.parse('3.0.0')), true);
        expect(c.allows(Version.parse('3.0.1')), false);
      });

      test('range constraint toString', () {
        final c = VersionConstraint.parse('>=1.0.0 <2.0.0');
        expect(c.toString(), '>=1.0.0 <2.0.0');
      });
    });

    group('GitRefConstraint', () {
      test('parses git branch constraint', () {
        final c = VersionConstraint.parse('branch:main');
        expect(c, isA<GitRefConstraint>());
        expect(c.isGitRef, true);
        expect((c as GitRefConstraint).type, GitRefType.branch);
        expect(c.ref, 'main');
      });

      test('parses git tag constraint', () {
        final c = VersionConstraint.parse('tag:v1.0.0');
        expect(c, isA<GitRefConstraint>());
        expect((c as GitRefConstraint).type, GitRefType.tag);
        expect(c.ref, 'v1.0.0');
      });

      test('parses git commit constraint', () {
        final c = VersionConstraint.parse('commit:abc123def');
        expect(c, isA<GitRefConstraint>());
        expect((c as GitRefConstraint).type, GitRefType.commit);
        expect(c.ref, 'abc123def');
      });

      test('git ref constraint always allows any version', () {
        final c = VersionConstraint.parse('branch:develop');
        expect(c.allows(Version.parse('1.0.0')), true);
        expect(c.allows(Version.parse('999.0.0')), true);
      });

      test('git ref constraint toString', () {
        expect(
          VersionConstraint.parse('branch:main').toString(),
          'branch:main',
        );
        expect(
          VersionConstraint.parse('tag:v1.0.0').toString(),
          'tag:v1.0.0',
        );
        expect(
          VersionConstraint.parse('commit:abc').toString(),
          'commit:abc',
        );
      });
    });
  });

  group('Version matching real-world scenarios', () {
    test('typical npm-style caret constraint', () {
      final c = VersionConstraint.parse('^1.0.0');
      // Should match any 1.x.x
      expect(c.allows(Version.parse('1.0.0')), true);
      expect(c.allows(Version.parse('1.0.1')), true);
      expect(c.allows(Version.parse('1.1.0')), true);
      expect(c.allows(Version.parse('1.9.9')), true);
      // Should not match 2.x or 0.x
      expect(c.allows(Version.parse('2.0.0')), false);
      expect(c.allows(Version.parse('0.9.9')), false);
    });

    test('selecting best version from list', () {
      final constraint = VersionConstraint.parse('^1.0.0');
      final available = ['0.9.0', '1.0.0', '1.0.1', '1.1.0', '2.0.0'];

      final matching = available
          .map((v) => Version.tryParse(v))
          .whereType<Version>()
          .where((v) => constraint.allows(v))
          .toList()
        ..sort((a, b) => b.compareTo(a)); // Sort descending

      expect(matching.first.toString(), '1.1.0');
    });

    test('selecting best version with v prefix', () {
      final constraint = VersionConstraint.parse('^1.0.0');
      final available = ['v0.9.0', 'v1.0.0', 'v1.0.1', 'v1.1.0', 'v2.0.0'];

      final matching = available.map((v) {
        final clean = v.startsWith('v') ? v.substring(1) : v;
        return Version.tryParse(clean);
      }).whereType<Version>().where((v) => constraint.allows(v)).toList()
        ..sort((a, b) => b.compareTo(a));

      expect(matching.first.toString(), '1.1.0');
    });

    test('constraint ^0.x.y is stricter', () {
      // ^0.2.0 should only match 0.2.x
      final c = VersionConstraint.parse('^0.2.0');
      expect(c.allows(Version.parse('0.2.0')), true);
      expect(c.allows(Version.parse('0.2.5')), true);
      expect(c.allows(Version.parse('0.3.0')), false);
      expect(c.allows(Version.parse('1.0.0')), false);
    });

    test('exact version match', () {
      final c = VersionConstraint.parse('2.1.0');
      expect(c.allows(Version.parse('2.1.0')), true);
      expect(c.allows(Version.parse('2.1.1')), false);
      expect(c.allows(Version.parse('2.0.9')), false);
    });

    test('prerelease versions', () {
      final stable = Version.parse('1.0.0');
      final alpha = Version.parse('1.0.0-alpha');
      final beta = Version.parse('1.0.0-beta');

      expect(alpha < stable, true);
      expect(beta < stable, true);
      expect(alpha < beta, true); // alpha comes before beta alphabetically
    });
  });
}
