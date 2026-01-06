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
  });

  group('VersionConstraint', () {
    test('parses any constraint', () {
      final c = VersionConstraint.parse('any');
      expect(c, isA<AnyVersionConstraint>());
      expect(c.allows(Version.parse('1.0.0')), true);
      expect(c.allows(Version.parse('99.99.99')), true);
    });

    test('parses exact constraint', () {
      final c = VersionConstraint.parse('1.2.3');
      expect(c, isA<ExactConstraint>());
      expect(c.allows(Version.parse('1.2.3')), true);
      expect(c.allows(Version.parse('1.2.4')), false);
    });

    test('parses caret constraint', () {
      final c = VersionConstraint.parse('^1.2.3');
      expect(c, isA<CaretConstraint>());
      expect(c.allows(Version.parse('1.2.3')), true);
      expect(c.allows(Version.parse('1.3.0')), true);
      expect(c.allows(Version.parse('1.99.99')), true);
      expect(c.allows(Version.parse('2.0.0')), false);
      expect(c.allows(Version.parse('1.2.2')), false);
    });

    test('caret constraint with 0.x is more restrictive', () {
      final c = VersionConstraint.parse('^0.2.3');
      expect(c.allows(Version.parse('0.2.3')), true);
      expect(c.allows(Version.parse('0.2.9')), true);
      expect(c.allows(Version.parse('0.3.0')), false);
    });

    test('parses comparison constraints', () {
      final gte = VersionConstraint.parse('>=1.0.0');
      expect(gte.allows(Version.parse('1.0.0')), true);
      expect(gte.allows(Version.parse('2.0.0')), true);
      expect(gte.allows(Version.parse('0.9.0')), false);

      final lt = VersionConstraint.parse('<2.0.0');
      expect(lt.allows(Version.parse('1.9.9')), true);
      expect(lt.allows(Version.parse('2.0.0')), false);
    });

    test('parses range constraint', () {
      final c = VersionConstraint.parse('>=1.0.0 <2.0.0');
      expect(c, isA<RangeConstraint>());
      expect(c.allows(Version.parse('1.0.0')), true);
      expect(c.allows(Version.parse('1.5.0')), true);
      expect(c.allows(Version.parse('0.9.0')), false);
      expect(c.allows(Version.parse('2.0.0')), false);
    });

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
      final c = VersionConstraint.parse('commit:abc123');
      expect(c, isA<GitRefConstraint>());
      expect((c as GitRefConstraint).type, GitRefType.commit);
      expect(c.ref, 'abc123');
    });
  });
}
