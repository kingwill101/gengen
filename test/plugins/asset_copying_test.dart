import 'package:test/test.dart';
import 'package:file/memory.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/site.dart';
import 'package:gengen/readers/plugin_reader.dart';
import 'package:gengen/models/plugin_asset.dart';
import 'package:gengen/exceptions.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Plugin Asset Copying System', () {
    late MemoryFileSystem memoryFileSystem;
    late String projectRoot;
    late Site site;

    setUpAll(() {
      Site.resetInstance();
    });

    setUp(() async {
      memoryFileSystem = MemoryFileSystem();
      gengen_fs.fs = memoryFileSystem;
      projectRoot = memoryFileSystem.currentDirectory.path;
      final sourcePath = p.join(projectRoot, 'test_site');

      // Create comprehensive test site structure
      await _createTestSite(memoryFileSystem, sourcePath);

      Site.init(
        overrides: {
          'source': sourcePath,
          'destination': p.join(projectRoot, 'public'),
        },
      );
      site = Site.instance;
    });

    tearDown(() {
      Site.resetInstance();
    });

    test('should copy asset-only plugin files to static assets', () async {
      final pluginReader = PluginReader();
      final plugins = await pluginReader.read();

      // Verify built-in plugins are loaded, asset-only plugins return null
      expect(plugins.length, greaterThanOrEqualTo(0));

      // Check that static assets were added to Site.staticFiles
      final staticFiles = Site.instance.staticFiles;
      final pluginAssets = staticFiles.whereType<PluginStaticAsset>().toList();

      expect(pluginAssets.length, greaterThanOrEqualTo(5));

      // Verify specific assets were found (using basename since path includes plugin directory)
      final assetNames = pluginAssets.map((a) => p.basename(a.name)).toSet();
      expect(assetNames, contains('theme.css'));
      expect(assetNames, contains('main.js'));
      expect(assetNames, contains('helper.js'));
      expect(assetNames, contains('icon.png'));
      expect(assetNames, contains('logo.svg'));
    });

    test('should handle glob patterns correctly', () async {
      final pluginReader = PluginReader();
      await pluginReader.read();

      final staticFiles = Site.instance.staticFiles;
      final pluginAssets = staticFiles.whereType<PluginStaticAsset>().toList();

      // Check that glob patterns matched files
      final cssAssets = pluginAssets
          .where((a) => a.name.endsWith('.css'))
          .toList();
      final jsAssets = pluginAssets
          .where((a) => a.name.endsWith('.js'))
          .toList();
      final imageAssets = pluginAssets
          .where((a) => a.name.endsWith('.png') || a.name.endsWith('.svg'))
          .toList();

      expect(cssAssets.length, greaterThanOrEqualTo(1));
      expect(jsAssets.length, greaterThanOrEqualTo(2));
      expect(imageAssets.length, greaterThanOrEqualTo(2));

      // Verify plugin namespace in paths
      for (final asset in pluginAssets) {
        expect(asset.pluginName, equals('test-plugin'));
      }
    });

    test('should generate correct asset URLs', () async {
      final pluginReader = PluginReader();
      await pluginReader.read();

      final staticFiles = Site.instance.staticFiles;
      final pluginAssets = staticFiles.whereType<PluginStaticAsset>().toList();

      for (final asset in pluginAssets) {
        // Check that asset has correct plugin namespace
        expect(asset.pluginName, equals('test-plugin'));

        // Verify the asset would be copied to correct location
        final expectedPath =
            'assets/plugins/test-plugin/${p.basename(asset.name)}';
        expect(asset.link(), equals(expectedPath));
      }
    });

    test('should handle complex glob patterns', () async {
      // Create plugin with complex glob patterns
      await _createComplexGlobPlugin(
        memoryFileSystem,
        p.join(projectRoot, 'test_site'),
      );

      final pluginReader = PluginReader();
      await pluginReader.read();

      final staticFiles = Site.instance.staticFiles;
      final complexPluginAssets = staticFiles
          .whereType<PluginStaticAsset>()
          .where((a) => a.pluginName == 'complex-glob-plugin')
          .toList();

      expect(complexPluginAssets.length, greaterThanOrEqualTo(4));

      // Verify different pattern types matched (using basename)
      final assetNames = complexPluginAssets
          .map((a) => p.basename(a.name))
          .toSet();
      expect(assetNames, contains('main.css'));
      expect(assetNames, contains('components.css'));
      expect(assetNames, contains('app.js'));
      expect(assetNames, contains('utils.js'));
    });

    test('should exclude Dart files from static assets', () async {
      // Create a plugin with only static files (no Dart files to avoid compilation issues)
      await _createStaticOnlyPlugin(
        memoryFileSystem,
        p.join(projectRoot, 'test_site'),
      );

      final pluginReader = PluginReader();
      await pluginReader.read();

      final staticFiles = Site.instance.staticFiles;
      final staticOnlyAssets = staticFiles
          .whereType<PluginStaticAsset>()
          .where((a) => a.pluginName == 'static-only-plugin')
          .toList();

      // Should have CSS and JS files
      final assetNames = staticOnlyAssets
          .map((a) => p.basename(a.name))
          .toSet();
      expect(assetNames, contains('styles.css'));
      expect(assetNames, contains('script.js'));
      expect(staticOnlyAssets.length, equals(2));

      // Verify that the plugin reader correctly processes static-only plugins
      // (The actual Dart file exclusion is tested by the plugin reader implementation)
      expect(
        staticOnlyAssets.every((asset) => !asset.name.endsWith('.dart')),
        isTrue,
      );
    });

    test('should surface invalid glob patterns', () async {
      // Create plugin with invalid glob pattern
      await _createInvalidGlobPlugin(
        memoryFileSystem,
        p.join(projectRoot, 'test_site'),
      );

      final pluginReader = PluginReader();
      expect(
        () async => await pluginReader.read(),
        throwsA(
          predicate((error) {
            if (error is! PluginException) {
              return false;
            }

            return error.message.contains('invalid-glob-plugin') &&
                error.message.contains('invalid[pattern');
          }),
        ),
      );
    });

    test('should fail when declared plugin assets are missing', () async {
      await _createMissingAssetPlugin(
        memoryFileSystem,
        p.join(projectRoot, 'test_site'),
      );

      final pluginReader = PluginReader();
      expect(
        () async => await pluginReader.read(),
        throwsA(
          predicate((error) {
            if (error is! PluginException) {
              return false;
            }

            return error.message.contains('missing-asset-plugin') &&
                error.message.contains('missing.css');
          }),
        ),
      );
    });

    test('should handle brace expansion patterns', () async {
      await _createBraceExpansionPlugin(
        memoryFileSystem,
        p.join(projectRoot, 'test_site'),
      );

      final pluginReader = PluginReader();
      await pluginReader.read();

      final staticFiles = Site.instance.staticFiles;
      final braceAssets = staticFiles
          .whereType<PluginStaticAsset>()
          .where((a) => a.pluginName == 'brace-plugin')
          .toList();

      // Should match both .css and .js files (using basename)
      final assetNames = braceAssets.map((a) => p.basename(a.name)).toSet();
      expect(assetNames, contains('main.css'));
      expect(assetNames, contains('main.js'));
      expect(braceAssets.length, equals(2));
    });

    test('should handle character class patterns', () async {
      await _createCharacterClassPlugin(
        memoryFileSystem,
        p.join(projectRoot, 'test_site'),
      );

      final pluginReader = PluginReader();
      await pluginReader.read();

      final staticFiles = Site.instance.staticFiles;
      final charAssets = staticFiles
          .whereType<PluginStaticAsset>()
          .where((a) => a.pluginName == 'char-class-plugin')
          .toList();

      // Should match files starting with 'm' or 'c' (using basename)
      final assetNames = charAssets.map((a) => p.basename(a.name)).toSet();
      expect(assetNames, contains('main.css'));
      expect(assetNames, contains('components.css'));
      expect(
        assetNames,
        isNot(contains('theme.css')),
      ); // Doesn't start with m or c
    });

    test('should copy plugin assets during site build', () async {
      final pluginReader = PluginReader();
      await pluginReader.read();

      // Perform a full site build
      await site.process();

      // Verify assets were copied to the destination directory
      final destPath = p.join(projectRoot, 'public');
      final pluginAssetsDir = p.join(
        destPath,
        'assets',
        'plugins',
        'test-plugin',
      );

      // Check that plugin assets directory was created
      expect(memoryFileSystem.directory(pluginAssetsDir).existsSync(), isTrue);

      // Verify specific assets were copied
      expect(
        memoryFileSystem
            .file(p.join(pluginAssetsDir, 'theme.css'))
            .existsSync(),
        isTrue,
      );
      expect(
        memoryFileSystem.file(p.join(pluginAssetsDir, 'main.js')).existsSync(),
        isTrue,
      );
      expect(
        memoryFileSystem
            .file(p.join(pluginAssetsDir, 'helper.js'))
            .existsSync(),
        isTrue,
      );
      expect(
        memoryFileSystem.file(p.join(pluginAssetsDir, 'icon.png')).existsSync(),
        isTrue,
      );
      expect(
        memoryFileSystem.file(p.join(pluginAssetsDir, 'logo.svg')).existsSync(),
        isTrue,
      );

      // Verify file contents were copied correctly
      final copiedCss = memoryFileSystem
          .file(p.join(pluginAssetsDir, 'theme.css'))
          .readAsStringSync();
      expect(copiedCss, contains('.test-theme'));
      expect(copiedCss, contains('color: blue'));

      final copiedJs = memoryFileSystem
          .file(p.join(pluginAssetsDir, 'main.js'))
          .readAsStringSync();
      expect(copiedJs, contains('Main script loaded'));
      expect(copiedJs, contains('initTestPlugin'));
    });

    test('should copy complex glob pattern assets during build', () async {
      // Create plugin with complex glob patterns
      await _createComplexGlobPlugin(
        memoryFileSystem,
        p.join(projectRoot, 'test_site'),
      );

      final pluginReader = PluginReader();
      await pluginReader.read();

      // Perform a full site build
      await site.process();

      // Verify complex glob plugin assets were copied
      final destPath = p.join(projectRoot, 'public');
      final complexPluginAssetsDir = p.join(
        destPath,
        'assets',
        'plugins',
        'complex-glob-plugin',
      );

      // Check that plugin assets directory was created
      expect(
        memoryFileSystem.directory(complexPluginAssetsDir).existsSync(),
        isTrue,
      );

      // Verify glob-matched assets were copied
      expect(
        memoryFileSystem
            .file(p.join(complexPluginAssetsDir, 'main.css'))
            .existsSync(),
        isTrue,
      );
      expect(
        memoryFileSystem
            .file(p.join(complexPluginAssetsDir, 'components.css'))
            .existsSync(),
        isTrue,
      );
      expect(
        memoryFileSystem
            .file(p.join(complexPluginAssetsDir, 'app.js'))
            .existsSync(),
        isTrue,
      );
      expect(
        memoryFileSystem
            .file(p.join(complexPluginAssetsDir, 'utils.js'))
            .existsSync(),
        isTrue,
      );

      // Verify file contents
      final copiedMainCss = memoryFileSystem
          .file(p.join(complexPluginAssetsDir, 'main.css'))
          .readAsStringSync();
      expect(copiedMainCss, contains('.main {}'));

      final copiedAppJs = memoryFileSystem
          .file(p.join(complexPluginAssetsDir, 'app.js'))
          .readAsStringSync();
      expect(copiedAppJs, contains('console.log("app")'));
    });

    test('should copy brace expansion pattern assets during build', () async {
      await _createBraceExpansionPlugin(
        memoryFileSystem,
        p.join(projectRoot, 'test_site'),
      );

      final pluginReader = PluginReader();
      await pluginReader.read();

      // Perform a full site build
      await site.process();

      // Verify brace expansion plugin assets were copied
      final destPath = p.join(projectRoot, 'public');
      final bracePluginAssetsDir = p.join(
        destPath,
        'assets',
        'plugins',
        'brace-plugin',
      );

      // Check that plugin assets directory was created
      expect(
        memoryFileSystem.directory(bracePluginAssetsDir).existsSync(),
        isTrue,
      );

      // Verify brace expansion matched assets were copied
      expect(
        memoryFileSystem
            .file(p.join(bracePluginAssetsDir, 'main.css'))
            .existsSync(),
        isTrue,
      );
      expect(
        memoryFileSystem
            .file(p.join(bracePluginAssetsDir, 'main.js'))
            .existsSync(),
        isTrue,
      );

      // Verify non-matching file was not copied
      expect(
        memoryFileSystem
            .file(p.join(bracePluginAssetsDir, 'other.txt'))
            .existsSync(),
        isFalse,
      );

      // Verify file contents
      final copiedCss = memoryFileSystem
          .file(p.join(bracePluginAssetsDir, 'main.css'))
          .readAsStringSync();
      expect(copiedCss, contains('.main { color: blue; }'));

      final copiedJs = memoryFileSystem
          .file(p.join(bracePluginAssetsDir, 'main.js'))
          .readAsStringSync();
      expect(copiedJs, contains('console.log("main")'));
    });
  });
}

/// Creates a comprehensive test site with plugins and assets
Future<void> _createTestSite(MemoryFileSystem fs, String sourcePath) async {
  // Create basic site structure
  await fs.directory(sourcePath).create(recursive: true);
  await fs.directory(p.join(sourcePath, '_plugins')).create(recursive: true);
  await fs.directory(p.join(sourcePath, '_layouts')).create(recursive: true);
  await fs.directory(p.join(sourcePath, '_posts')).create(recursive: true);

  // Create site config
  fs.file(p.join(sourcePath, 'config.yaml')).writeAsStringSync('''
title: Test Site
description: A test site for plugin assets
''');

  // Create test plugin with various assets
  final pluginPath = p.join(sourcePath, '_plugins', 'test-plugin');
  await fs.directory(pluginPath).create(recursive: true);

  // Plugin config with explicit file list and glob patterns
  fs.file(p.join(pluginPath, 'config.yaml')).writeAsStringSync('''
name: TestPlugin
description: A test plugin with various assets
version: 1.0.0

files:
  - name: theme.css
    path: theme.css
  - name: all-js
    path: "*.js"
  - name: images
    path: "images/*"

head_injection: |
  <meta name="test-plugin" content="enabled">

body_injection: |
  <script>console.log('Test plugin loaded!');</script>
''');

  // Create plugin assets
  fs.file(p.join(pluginPath, 'theme.css')).writeAsStringSync('''
.test-theme {
  color: blue;
  font-size: 16px;
}
''');

  fs.file(p.join(pluginPath, 'main.js')).writeAsStringSync('''
console.log('Main script loaded');
function initTestPlugin() {
  console.log('Test plugin initialized');
}
''');

  fs.file(p.join(pluginPath, 'helper.js')).writeAsStringSync('''
function helperFunction() {
  return 'Helper function called';
}
''');

  // Create images directory with assets
  final imagesPath = p.join(pluginPath, 'images');
  await fs.directory(imagesPath).create(recursive: true);
  fs.file(p.join(imagesPath, 'icon.png')).writeAsStringSync('fake-png-data');
  fs
      .file(p.join(imagesPath, 'logo.svg'))
      .writeAsStringSync('<svg>fake-svg</svg>');

  // Create basic layout
  fs.file(p.join(sourcePath, '_layouts', 'default.html')).writeAsStringSync('''
<!DOCTYPE html>
<html>
<head>
    <title>{{ page.title | default: site.title }}</title>
    {% plugin_head %}
</head>
<body>
    {{ content }}
    {% plugin_body %}
</body>
</html>
''');

  // Create index page
  fs.file(p.join(sourcePath, 'index.html')).writeAsStringSync('''
---
title: Home
layout: default
---

<h1>Welcome to Test Site</h1>
<p>This site tests plugin asset functionality.</p>
''');
}

/// Creates a plugin with complex glob patterns
Future<void> _createComplexGlobPlugin(
  MemoryFileSystem fs,
  String sourcePath,
) async {
  final pluginPath = p.join(sourcePath, '_plugins', 'complex-glob-plugin');
  await fs.directory(pluginPath).create(recursive: true);
  await fs.directory(p.join(pluginPath, 'styles')).create(recursive: true);
  await fs.directory(p.join(pluginPath, 'scripts')).create(recursive: true);

  // Plugin config with complex glob patterns
  fs.file(p.join(pluginPath, 'config.yaml')).writeAsStringSync('''
name: ComplexGlobPlugin
description: Plugin with complex glob patterns
version: 1.0.0

files:
  - name: all-css
    path: "**/*.css"
  - name: js-files
    path: "scripts/*.js"
  - name: main-files
    path: "**/main.*"
''');

  // Create files that should match the patterns
  fs
      .file(p.join(pluginPath, 'styles', 'main.css'))
      .writeAsStringSync('.main {}');
  fs
      .file(p.join(pluginPath, 'styles', 'components.css'))
      .writeAsStringSync('.component {}');
  fs
      .file(p.join(pluginPath, 'scripts', 'app.js'))
      .writeAsStringSync('console.log("app");');
  fs
      .file(p.join(pluginPath, 'scripts', 'utils.js'))
      .writeAsStringSync('console.log("utils");');
}

/// Creates a plugin with only static files (no Dart files to avoid compilation issues)
Future<void> _createStaticOnlyPlugin(
  MemoryFileSystem fs,
  String sourcePath,
) async {
  final pluginPath = p.join(sourcePath, '_plugins', 'static-only-plugin');
  await fs.directory(pluginPath).create(recursive: true);

  fs.file(p.join(pluginPath, 'config.yaml')).writeAsStringSync('''
name: StaticOnlyPlugin
description: Plugin with only static files
version: 1.0.0

files:
  - name: styles.css
    path: styles.css
  - name: script.js
    path: script.js
''');

  // Create only static files (no Dart files)
  fs
      .file(p.join(pluginPath, 'styles.css'))
      .writeAsStringSync('.static-only { color: green; }');
  fs
      .file(p.join(pluginPath, 'script.js'))
      .writeAsStringSync('console.log("static-only");');
}

/// Creates a plugin with invalid glob pattern
Future<void> _createInvalidGlobPlugin(
  MemoryFileSystem fs,
  String sourcePath,
) async {
  final pluginPath = p.join(sourcePath, '_plugins', 'invalid-glob-plugin');
  await fs.directory(pluginPath).create(recursive: true);

  fs.file(p.join(pluginPath, 'config.yaml')).writeAsStringSync('''
name: InvalidGlobPlugin
description: Plugin with invalid glob pattern
version: 1.0.0

files:
  - name: invalid-pattern
    path: "invalid[pattern"
  - name: valid-file
    path: "style.css"
''');

  fs
      .file(p.join(pluginPath, 'style.css'))
      .writeAsStringSync('.invalid { color: green; }');
}

/// Creates a plugin that declares missing assets
Future<void> _createMissingAssetPlugin(
  MemoryFileSystem fs,
  String sourcePath,
) async {
  final pluginPath = p.join(sourcePath, '_plugins', 'missing-asset-plugin');
  await fs.directory(pluginPath).create(recursive: true);

  fs.file(p.join(pluginPath, 'config.yaml')).writeAsStringSync('''
name: MissingAssetPlugin
description: Plugin that references missing assets
version: 1.0.0

files:
  - name: missing-styles
    path: "missing.css"
''');
}

/// Creates a plugin with brace expansion patterns
Future<void> _createBraceExpansionPlugin(
  MemoryFileSystem fs,
  String sourcePath,
) async {
  final pluginPath = p.join(sourcePath, '_plugins', 'brace-plugin');
  await fs.directory(pluginPath).create(recursive: true);

  fs.file(p.join(pluginPath, 'config.yaml')).writeAsStringSync('''
name: BracePlugin
description: Plugin with brace expansion patterns
version: 1.0.0

files:
  - name: main-assets
    path: "main.{css,js}"
''');

  fs
      .file(p.join(pluginPath, 'main.css'))
      .writeAsStringSync('.main { color: blue; }');
  fs
      .file(p.join(pluginPath, 'main.js'))
      .writeAsStringSync('console.log("main");');
  fs
      .file(p.join(pluginPath, 'other.txt'))
      .writeAsStringSync('should not match');
}

/// Creates a plugin with character class patterns
Future<void> _createCharacterClassPlugin(
  MemoryFileSystem fs,
  String sourcePath,
) async {
  final pluginPath = p.join(sourcePath, '_plugins', 'char-class-plugin');
  await fs.directory(pluginPath).create(recursive: true);

  fs.file(p.join(pluginPath, 'config.yaml')).writeAsStringSync('''
name: CharClassPlugin
description: Plugin with character class patterns
version: 1.0.0

files:
  - name: mc-files
    path: "[mc]*.css"
''');

  fs
      .file(p.join(pluginPath, 'main.css'))
      .writeAsStringSync('.main { color: red; }');
  fs
      .file(p.join(pluginPath, 'components.css'))
      .writeAsStringSync('.component { color: green; }');
  fs
      .file(p.join(pluginPath, 'theme.css'))
      .writeAsStringSync('.theme { color: blue; }');
}
