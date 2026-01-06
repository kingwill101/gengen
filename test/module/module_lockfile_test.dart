import 'package:gengen/module/module_lockfile.dart';
import 'package:test/test.dart';

void main() {
  group('LockedModule', () {
    test('creates from json', () {
      final module = LockedModule.fromJson('github.com/user/theme', {
        'version': '1.2.3',
        'resolved': 'https://github.com/user/theme.git',
        'sha': 'abc123',
        'locked_at': '2024-01-01T00:00:00.000Z',
      });

      expect(module.path, 'github.com/user/theme');
      expect(module.version, '1.2.3');
      expect(module.resolved, 'https://github.com/user/theme.git');
      expect(module.sha, 'abc123');
      expect(module.lockedAt, isNotNull);
    });

    test('converts to json', () {
      final module = LockedModule(
        path: 'pub:my_package',
        version: '2.0.0',
        resolved: 'https://pub.dev/packages/my_package',
        sha: 'def456',
        lockedAt: DateTime.utc(2024, 6, 15, 12, 30),
      );

      final json = module.toJson();
      expect(json['version'], '2.0.0');
      expect(json['resolved'], 'https://pub.dev/packages/my_package');
      expect(json['sha'], 'def456');
      expect(json['locked_at'], '2024-06-15T12:30:00.000Z');
    });

    test('parsedVersion returns Version for valid semver', () {
      final module = LockedModule(
        path: 'test',
        version: '1.2.3',
        resolved: 'test',
      );

      expect(module.parsedVersion, isNotNull);
      expect(module.parsedVersion!.major, 1);
      expect(module.parsedVersion!.minor, 2);
      expect(module.parsedVersion!.patch, 3);
    });

    test('parsedVersion returns null for non-semver', () {
      final module = LockedModule(
        path: 'test',
        version: 'main',
        resolved: 'test',
      );

      expect(module.parsedVersion, isNull);
    });
  });

  group('ModuleLockfile', () {
    test('creates empty lockfile', () {
      final lockfile = ModuleLockfile(lockfilePath: '/tmp/gengen.lock');

      expect(lockfile.isEmpty, true);
      expect(lockfile.packages, isEmpty);
    });

    test('manages packages', () {
      final lockfile = ModuleLockfile(lockfilePath: '/tmp/gengen.lock');

      final module = LockedModule(
        path: 'github.com/user/theme',
        version: '1.0.0',
        resolved: 'https://github.com/user/theme.git',
      );

      lockfile.setPackage('github.com/user/theme', module);

      expect(lockfile.hasPackage('github.com/user/theme'), true);
      expect(lockfile.hasPackage('other/path'), false);
      expect(lockfile.getPackage('github.com/user/theme'), module);
      expect(lockfile.isEmpty, false);

      lockfile.removePackage('github.com/user/theme');
      expect(lockfile.hasPackage('github.com/user/theme'), false);
      expect(lockfile.isEmpty, true);
    });

    test('clears all packages', () {
      final lockfile = ModuleLockfile(lockfilePath: '/tmp/gengen.lock');

      lockfile.setPackage(
        'path1',
        LockedModule(path: 'path1', version: '1.0.0', resolved: 'r1'),
      );
      lockfile.setPackage(
        'path2',
        LockedModule(path: 'path2', version: '2.0.0', resolved: 'r2'),
      );

      expect(lockfile.packages.length, 2);

      lockfile.clear();
      expect(lockfile.isEmpty, true);
    });
  });
}
