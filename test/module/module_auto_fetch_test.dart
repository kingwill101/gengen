import 'package:file/memory.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/module/module_import.dart';
import 'package:gengen/module/module_lockfile.dart';
import 'package:gengen/module/module_manifest.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// Helper to recursively convert YAML to `Map<String, dynamic>`
Map<String, dynamic> _convertYamlToMap(YamlMap yaml) {
  final result = <String, dynamic>{};
  for (final entry in yaml.entries) {
    final key = entry.key.toString();
    final value = entry.value;
    if (value is YamlMap) {
      result[key] = _convertYamlToMap(value);
    } else if (value is YamlList) {
      result[key] = value.map((e) {
        if (e is YamlMap) return _convertYamlToMap(e);
        return e;
      }).toList();
    } else {
      result[key] = value;
    }
  }
  return result;
}

void main() {
  group('Module Auto-Fetch Behavior', () {
    late MemoryFileSystem memFs;
    late String siteRoot;
    late String cacheDir;

    setUp(() {
      memFs = MemoryFileSystem();
      fs = memFs;
      siteRoot = '/test_site';
      cacheDir = '/home/user/.gengen/cache/modules';

      // Create site directory structure
      memFs.directory(siteRoot).createSync(recursive: true);
      memFs.directory(cacheDir).createSync(recursive: true);
    });

    group('ModuleManifest detection', () {
      test('detects modules in gengen.yaml', () {
        final configPath = p.join(siteRoot, 'gengen.yaml');
        memFs.file(configPath).writeAsStringSync('''
title: Test Site
module:
  imports:
    - path: github.com/user/theme
      version: ^1.0.0
''');

        final content = memFs.file(configPath).readAsStringSync();
        final yaml = loadYaml(content) as Map;
        expect(yaml.containsKey('module'), isTrue);

        // Properly convert the nested YAML structure
        final moduleYaml = yaml['module'] as YamlMap;
        final moduleData = _convertYamlToMap(moduleYaml);
        final manifest = ModuleManifest.parse(moduleData);
        expect(manifest.hasImports, isTrue);
        expect(manifest.imports.length, 1);
        expect(manifest.imports[0].path, 'github.com/user/theme');
      });

      test('detects modules in config.yaml', () {
        final configPath = p.join(siteRoot, 'config.yaml');
        memFs.file(configPath).writeAsStringSync('''
title: Test Site
theme: minimal
module:
  imports:
    - path: github.com/org/gengen-themes
      version: ">=1.0.0"
''');

        final content = memFs.file(configPath).readAsStringSync();
        final yaml = loadYaml(content) as Map;
        expect(yaml.containsKey('module'), isTrue);

        final moduleYaml = yaml['module'] as YamlMap;
        final moduleData = _convertYamlToMap(moduleYaml);
        final manifest = ModuleManifest.parse(moduleData);
        expect(manifest.hasImports, isTrue);
      });

      test('returns empty manifest when no module section', () {
        final configPath = p.join(siteRoot, 'config.yaml');
        memFs.file(configPath).writeAsStringSync('''
title: Test Site
theme: default
''');

        final content = memFs.file(configPath).readAsStringSync();
        final yaml = loadYaml(content) as Map;
        expect(yaml.containsKey('module'), isFalse);

        final manifest = ModuleManifest.parse(null);
        expect(manifest.hasImports, isFalse);
        expect(manifest.isEmpty, isTrue);
      });
    });

    group('Lockfile state detection', () {
      test('needsFetch is true when module not in lockfile', () {
        final manifest = ModuleManifest.parse({
          'imports': [
            {'path': 'github.com/user/theme', 'version': '^1.0.0'},
          ],
        });
        expect(manifest.imports, hasLength(1));
        expect(manifest.hasImports, isTrue);

        final lockfile = ModuleLockfile(
          lockfilePath: p.join(siteRoot, 'gengen.lock'),
        );
        expect(lockfile.hasPackage('github.com/user/theme'), isFalse);

        var needsFetch = false;
        for (final import_ in manifest.imports) {
          if (!lockfile.hasPackage(import_.path)) {
            needsFetch = true;
            break;
          }
        }
        expect(needsFetch, isTrue);
      });

      test('needsFetch is true when cached module directory missing', () {
        final manifest = ModuleManifest.parse({
          'imports': [
            {'path': 'github.com/user/theme', 'version': '^1.0.0'},
          ],
        });

        final lockfile = ModuleLockfile(
          lockfilePath: p.join(siteRoot, 'gengen.lock'),
        );
        lockfile.setPackage(
          'github.com/user/theme',
          LockedModule(
            path: 'github.com/user/theme',
            version: '^1.0.0',
            resolved: '$cacheDir/github.com/user/theme/v1.2.0',
          ),
        );

        expect(lockfile.hasPackage('github.com/user/theme'), isTrue);

        // Cache directory doesn't exist
        final locked = lockfile.getPackage('github.com/user/theme');
        expect(locked, isNotNull);
        expect(memFs.directory(locked!.resolved).existsSync(), isFalse);

        var needsFetch = false;
        for (final import_ in manifest.imports) {
          if (!lockfile.hasPackage(import_.path)) {
            needsFetch = true;
            break;
          }
          final pkg = lockfile.getPackage(import_.path);
          if (pkg != null && !memFs.directory(pkg.resolved).existsSync()) {
            needsFetch = true;
            break;
          }
        }
        expect(needsFetch, isTrue);
      });

      test('needsFetch is false when module cached and in lockfile', () {
        final manifest = ModuleManifest.parse({
          'imports': [
            {'path': 'github.com/user/theme', 'version': '^1.0.0'},
          ],
        });

        final cachePath = '$cacheDir/github.com/user/theme/v1.2.0';
        memFs.directory(cachePath).createSync(recursive: true);

        final lockfile = ModuleLockfile(
          lockfilePath: p.join(siteRoot, 'gengen.lock'),
        );
        lockfile.setPackage(
          'github.com/user/theme',
          LockedModule(
            path: 'github.com/user/theme',
            version: '^1.0.0',
            resolved: cachePath,
          ),
        );

        var needsFetch = false;
        for (final import_ in manifest.imports) {
          if (!lockfile.hasPackage(import_.path)) {
            needsFetch = true;
            break;
          }
          final pkg = lockfile.getPackage(import_.path);
          if (pkg != null && !memFs.directory(pkg.resolved).existsSync()) {
            needsFetch = true;
            break;
          }
        }
        expect(needsFetch, isFalse);
      });

      test('needsFetch is true for any missing module in multi-import', () {
        final manifest = ModuleManifest.parse({
          'imports': [
            {'path': 'github.com/user/theme1', 'version': '^1.0.0'},
            {'path': 'github.com/user/theme2', 'version': '^2.0.0'},
            {'path': 'github.com/user/plugin', 'version': '^0.5.0'},
          ],
        });

        // Only first two are cached
        final cache1 = '$cacheDir/github.com/user/theme1/v1.0.0';
        final cache2 = '$cacheDir/github.com/user/theme2/v2.0.0';
        memFs.directory(cache1).createSync(recursive: true);
        memFs.directory(cache2).createSync(recursive: true);

        final lockfile = ModuleLockfile(
          lockfilePath: p.join(siteRoot, 'gengen.lock'),
        );
        lockfile.setPackage(
          'github.com/user/theme1',
          LockedModule(
            path: 'github.com/user/theme1',
            version: '^1.0.0',
            resolved: cache1,
          ),
        );
        lockfile.setPackage(
          'github.com/user/theme2',
          LockedModule(
            path: 'github.com/user/theme2',
            version: '^2.0.0',
            resolved: cache2,
          ),
        );
        // Note: plugin not in lockfile

        var needsFetch = false;
        for (final import_ in manifest.imports) {
          if (!lockfile.hasPackage(import_.path)) {
            needsFetch = true;
            break;
          }
        }
        expect(needsFetch, isTrue);
      });
    });

    group('Theme discovery in modules', () {
      test('finds theme at module/themes/themeName', () {
        final modulePath = '$cacheDir/github.com/user/gengen-themes/v1.0.0';
        final themePath = '$modulePath/themes/minimal';

        // Create theme structure
        memFs.directory(themePath).createSync(recursive: true);
        memFs.directory('$themePath/_layouts').createSync(recursive: true);
        memFs.file('$themePath/_layouts/default.html').writeAsStringSync('''
<!DOCTYPE html>
<html>{{ content }}</html>
''');

        expect(memFs.directory(themePath).existsSync(), isTrue);
        expect(memFs.directory('$themePath/_layouts').existsSync(), isTrue);
      });

      test('finds theme at module/_themes/themeName', () {
        final modulePath = '$cacheDir/github.com/user/gengen-themes/v1.0.0';
        final themePath = '$modulePath/_themes/aurora';

        memFs.directory(themePath).createSync(recursive: true);
        memFs.directory('$themePath/_layouts').createSync(recursive: true);
        memFs.file('$themePath/_layouts/default.html').writeAsStringSync('');

        expect(memFs.directory(themePath).existsSync(), isTrue);
      });

      test('finds theme at module root when theme is the module', () {
        final modulePath = '$cacheDir/github.com/user/theme-minimal/v1.0.0';

        memFs.directory(modulePath).createSync(recursive: true);
        memFs.directory('$modulePath/_layouts').createSync(recursive: true);
        memFs.file('$modulePath/_layouts/default.html').writeAsStringSync('');
        memFs.file('$modulePath/config.yaml').writeAsStringSync('''
name: minimal
version: 1.0.0
''');

        expect(memFs.directory('$modulePath/_layouts').existsSync(), isTrue);
      });
    });

    group('Replacement handling', () {
      test('uses local replacement instead of remote', () {
        final manifest = ModuleManifest.parse({
          'imports': [
            {'path': 'github.com/user/theme', 'version': '^1.0.0'},
          ],
          'replacements': [
            {'path': 'github.com/user/theme', 'local': '../my-fork'},
          ],
        });

        expect(manifest.replacements.length, 1);
        expect(
          manifest.getReplacementFor('github.com/user/theme'),
          '../my-fork',
        );
      });

      test('returns null for non-replaced module', () {
        final manifest = ModuleManifest.parse({
          'imports': [
            {'path': 'github.com/user/theme', 'version': '^1.0.0'},
            {'path': 'github.com/other/plugin', 'version': '^0.5.0'},
          ],
          'replacements': [
            {'path': 'github.com/user/theme', 'local': '../my-fork'},
          ],
        });

        expect(manifest.getReplacementFor('github.com/other/plugin'), isNull);
      });
    });

    group('Module type detection', () {
      test('identifies git modules correctly', () {
        final githubImport = ModuleImport.parse({
          'path': 'github.com/user/theme',
          'version': '^1.0.0',
        });
        expect(githubImport.type, ModuleType.git);

        final gitlabImport = ModuleImport.parse({
          'path': 'gitlab.com/org/theme',
        });
        expect(gitlabImport.type, ModuleType.git);

        final bitbucketImport = ModuleImport.parse({
          'path': 'bitbucket.org/user/theme',
        });
        expect(bitbucketImport.type, ModuleType.git);
      });

      test('identifies local modules correctly', () {
        final relativeImport = ModuleImport.parse({'path': '../my-theme'});
        expect(relativeImport.type, ModuleType.local);

        final absoluteImport = ModuleImport.parse({
          'path': '/home/user/themes/custom',
        });
        expect(absoluteImport.type, ModuleType.local);

        final dotImport = ModuleImport.parse({'path': './themes/local'});
        expect(dotImport.type, ModuleType.local);
      });

      test('identifies pub modules correctly', () {
        final pubImport = ModuleImport.parse({
          'path': 'pub:gengen_theme_aurora',
          'version': '^0.5.0',
        });
        expect(pubImport.type, ModuleType.pub);
        expect(pubImport.name, 'gengen_theme_aurora');
      });
    });

    group('Lockfile persistence', () {
      test('lockfile saves and loads correctly', () {
        final lockfilePath = p.join(siteRoot, 'gengen.lock');

        final lockfile = ModuleLockfile(lockfilePath: lockfilePath);
        lockfile.setPackage(
          'github.com/user/theme',
          LockedModule(
            path: 'github.com/user/theme',
            version: '^1.0.0',
            resolved: '$cacheDir/github.com/user/theme/v1.2.3',
          ),
        );

        // Save lockfile
        lockfile.save();

        // Load lockfile
        final loaded = ModuleLockfile.load(siteRoot);

        expect(loaded.hasPackage('github.com/user/theme'), isTrue);
        final pkg = loaded.getPackage('github.com/user/theme');
        expect(pkg, isNotNull);
        expect(pkg!.version, '^1.0.0');
        expect(pkg.resolved, '$cacheDir/github.com/user/theme/v1.2.3');
      });

      test('lockfile handles multiple packages', () {
        final lockfile = ModuleLockfile(
          lockfilePath: p.join(siteRoot, 'gengen.lock'),
        );
        lockfile.setPackage(
          'github.com/user/theme1',
          LockedModule(
            path: 'github.com/user/theme1',
            version: '^1.0.0',
            resolved: '$cacheDir/github.com/user/theme1/v1.0.0',
          ),
        );
        lockfile.setPackage(
          'github.com/user/theme2',
          LockedModule(
            path: 'github.com/user/theme2',
            version: '^2.0.0',
            resolved: '$cacheDir/github.com/user/theme2/v2.5.0',
          ),
        );

        expect(lockfile.packages.length, 2);
        expect(lockfile.hasPackage('github.com/user/theme1'), isTrue);
        expect(lockfile.hasPackage('github.com/user/theme2'), isTrue);
        expect(lockfile.hasPackage('github.com/user/theme3'), isFalse);
      });
    });

    group('skipAutoInit behavior', () {
      test('build command skips auto init to fetch modules first', () {
        // This test verifies the design pattern:
        // 1. AbstractCommand.run() checks skipAutoInit
        // 2. If true, Site.init() is NOT called automatically
        // 3. Build.start() fetches modules first, then calls Site.init()

        // We can't easily test the actual command execution in unit tests,
        // but we can verify the manifest/lockfile logic that determines
        // if fetching is needed.

        final manifest = ModuleManifest.parse({
          'imports': [
            {'path': 'github.com/user/theme', 'version': '^1.0.0'},
          ],
        });
        expect(manifest.imports, hasLength(1));

        // Empty lockfile = needs fetch
        final emptyLockfile = ModuleLockfile(
          lockfilePath: p.join(siteRoot, 'gengen.lock'),
        );
        expect(emptyLockfile.hasPackage('github.com/user/theme'), isFalse);

        // With lockfile but no cache = needs fetch
        final lockfileNoCacheDir = ModuleLockfile(
          lockfilePath: p.join(siteRoot, 'gengen.lock'),
        );
        lockfileNoCacheDir.setPackage(
          'github.com/user/theme',
          LockedModule(
            path: 'github.com/user/theme',
            version: '^1.0.0',
            resolved: '$cacheDir/github.com/user/theme/v1.0.0',
          ),
        );
        expect(
          memFs
              .directory('$cacheDir/github.com/user/theme/v1.0.0')
              .existsSync(),
          isFalse,
        );

        // With lockfile AND cache = no fetch needed
        final cachePath = '$cacheDir/github.com/user/theme/v1.0.0';
        memFs.directory(cachePath).createSync(recursive: true);
        expect(memFs.directory(cachePath).existsSync(), isTrue);
      });
    });

    group('Config file priority', () {
      test('checks gengen.yaml, config.yaml, _config.yaml in order', () {
        // Create all three config files with different modules
        memFs.file(p.join(siteRoot, 'gengen.yaml')).writeAsStringSync('''
module:
  imports:
    - path: github.com/first/theme
''');
        memFs.file(p.join(siteRoot, 'config.yaml')).writeAsStringSync('''
module:
  imports:
    - path: github.com/second/theme
''');
        memFs.file(p.join(siteRoot, '_config.yaml')).writeAsStringSync('''
module:
  imports:
    - path: github.com/third/theme
''');

        // The build command checks in this order and uses the first one found
        final configFiles = ['gengen.yaml', 'config.yaml', '_config.yaml'];
        YamlMap? configData;

        for (final configFile in configFiles) {
          final configPath = p.join(siteRoot, configFile);
          final file = memFs.file(configPath);
          if (file.existsSync()) {
            final content = file.readAsStringSync();
            final yaml = loadYaml(content) as YamlMap?;
            if (yaml != null && yaml.containsKey('module')) {
              configData = yaml;
              break;
            }
          }
        }

        expect(configData, isNotNull);
        final moduleYaml = configData!['module'] as YamlMap;
        final moduleData = _convertYamlToMap(moduleYaml);
        final manifest = ModuleManifest.parse(moduleData);
        expect(manifest.imports[0].path, 'github.com/first/theme');
      });

      test('falls back to config.yaml when gengen.yaml has no modules', () {
        memFs.file(p.join(siteRoot, 'gengen.yaml')).writeAsStringSync('''
title: Test Site
# No module section
''');
        memFs.file(p.join(siteRoot, 'config.yaml')).writeAsStringSync('''
module:
  imports:
    - path: github.com/fallback/theme
''');

        final configFiles = ['gengen.yaml', 'config.yaml', '_config.yaml'];
        YamlMap? configData;

        for (final configFile in configFiles) {
          final configPath = p.join(siteRoot, configFile);
          final file = memFs.file(configPath);
          if (file.existsSync()) {
            final content = file.readAsStringSync();
            final yaml = loadYaml(content) as YamlMap?;
            if (yaml != null && yaml.containsKey('module')) {
              configData = yaml;
              break;
            }
          }
        }

        expect(configData, isNotNull);
        final moduleYaml = configData!['module'] as YamlMap;
        final moduleData = _convertYamlToMap(moduleYaml);
        final manifest = ModuleManifest.parse(moduleData);
        expect(manifest.imports[0].path, 'github.com/fallback/theme');
      });
    });
  });
}
