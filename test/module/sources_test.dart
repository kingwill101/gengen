import 'package:gengen/module/module_cache.dart';
import 'package:gengen/module/module_import.dart';
import 'package:gengen/module/sources.dart';
import 'package:test/test.dart';

void main() {
  group('GitModuleSource cached version matching', () {
    late GitModuleSource source;
    late ModuleCache cache;

    setUp(() {
      cache = ModuleCache(cacheRoot: '/tmp/test-cache');
      source = GitModuleSource(cache: cache);
    });

    test('canHandle returns true for git module types', () {
      final gitImport = ModuleImport(
        path: 'github.com/user/repo',
        type: ModuleType.git,
      );
      final localImport = ModuleImport(
        path: '../local',
        type: ModuleType.local,
      );

      expect(source.canHandle(gitImport), true);
      expect(source.canHandle(localImport), false);
    });
  });

  group('LocalModuleSource', () {
    test('canHandle returns true for local module types', () {
      final source = LocalModuleSource(siteRoot: '/tmp/site');

      final localImport = ModuleImport(
        path: '../theme',
        type: ModuleType.local,
      );
      final gitImport = ModuleImport(
        path: 'github.com/user/repo',
        type: ModuleType.git,
      );

      expect(source.canHandle(localImport), true);
      expect(source.canHandle(gitImport), false);
    });
  });

  group('PubModuleSource', () {
    late PubModuleSource source;
    late ModuleCache cache;

    setUp(() {
      cache = ModuleCache(cacheRoot: '/tmp/test-cache');
      source = PubModuleSource(cache: cache);
    });

    test('canHandle returns true for pub module types', () {
      final pubImport = ModuleImport(
        path: 'pub:some_package',
        type: ModuleType.pub,
      );
      final gitImport = ModuleImport(
        path: 'github.com/user/repo',
        type: ModuleType.git,
      );

      expect(source.canHandle(pubImport), true);
      expect(source.canHandle(gitImport), false);
    });
  });

  group('ModuleType detection', () {
    test('detects github.com as git', () {
      expect(ModuleType.fromPath('github.com/user/repo'), ModuleType.git);
    });

    test('detects gitlab.com as git', () {
      expect(ModuleType.fromPath('gitlab.com/org/project'), ModuleType.git);
    });

    test('detects bitbucket.org as git', () {
      expect(ModuleType.fromPath('bitbucket.org/team/repo'), ModuleType.git);
    });

    test('detects pub: prefix as pub', () {
      expect(ModuleType.fromPath('pub:package_name'), ModuleType.pub);
    });

    test('detects relative path as local', () {
      expect(ModuleType.fromPath('../theme'), ModuleType.local);
      expect(ModuleType.fromPath('./plugin'), ModuleType.local);
    });

    test('detects absolute path as local', () {
      expect(ModuleType.fromPath('/home/user/theme'), ModuleType.local);
    });
  });

  group('ModuleImport parsing', () {
    test('extracts name from github path', () {
      final import_ = ModuleImport.parse({'path': 'github.com/user/my-theme'});
      expect(import_.name, 'my-theme');
    });

    test('extracts name from nested github path', () {
      final import_ = ModuleImport.parse({
        'path': 'github.com/org/repo/themes/minimal',
      });
      expect(import_.name, 'minimal');
    });

    test('extracts name from pub package', () {
      final import_ = ModuleImport.parse({'path': 'pub:gengen_theme_aurora'});
      expect(import_.name, 'gengen_theme_aurora');
    });

    test('extracts name from local path', () {
      final import_ = ModuleImport.parse({'path': '../my-local-theme'});
      expect(import_.name, 'my-local-theme');
    });

    test('preserves version constraint', () {
      final import_ = ModuleImport.parse({
        'path': 'github.com/user/theme',
        'version': '^1.0.0',
      });
      expect(import_.version, '^1.0.0');
    });

    test('handles missing version', () {
      final import_ = ModuleImport.parse({'path': 'github.com/user/theme'});
      expect(import_.version, isNull);
    });
  });
}
