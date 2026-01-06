import 'package:file/memory.dart';
import 'package:file/file.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/gengen.dart';
import 'package:gengen/di.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late MemoryFileSystem memoryFileSystem;
  late String projectRoot;

  setUp(() {
    memoryFileSystem = MemoryFileSystem();
    gengen_fs.fs = memoryFileSystem;
    projectRoot = '/test-site';
  });

  tearDown(() {
    Site.resetInstance();
    // Clean up GetIt registrations
    if (getIt.isRegistered<FileSystem>()) {
      getIt.unregister<FileSystem>();
    }
  });

  group('GenGen Library API', () {
    test('should initialize and build a basic site', () async {
      // Create a basic site structure
      await memoryFileSystem
          .directory(p.join(projectRoot, '_posts'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_layouts'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_themes'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_themes', 'default'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_themes', 'default', '_layouts'))
          .create(recursive: true);

      // Create config file
      memoryFileSystem
          .file(p.join(projectRoot, '_config.yaml'))
          .writeAsStringSync('''
title: Test Site
description: A test site for GenGen library
theme: default
''');

      // Create theme config
      memoryFileSystem
          .file(p.join(projectRoot, '_themes', 'default', 'config.yaml'))
          .writeAsStringSync('''
name: default
version: 1.0.0
''');

      // Create a simple layout in the theme
      memoryFileSystem
          .file(
            p.join(
              projectRoot,
              '_themes',
              'default',
              '_layouts',
              'default.html',
            ),
          )
          .writeAsStringSync('''
<!DOCTYPE html>
<html>
<head>
  <title>{{ site.title }}</title>
</head>
<body>
  {{ content }}
</body>
</html>
''');

      // Create a simple layout in the main layouts directory as fallback
      memoryFileSystem
          .file(p.join(projectRoot, '_layouts', 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html>
<head>
  <title>{{ site.title }}</title>
</head>
<body>
  {{ content }}
</body>
</html>
''');

      // Create index page
      memoryFileSystem
          .file(p.join(projectRoot, 'index.html'))
          .writeAsStringSync('''
---
layout: default
title: Home
---
<h1>Welcome to {{ site.title }}</h1>
<p>{{ site.description }}</p>
''');

      // Create a post
      memoryFileSystem
          .file(p.join(projectRoot, '_posts', '2024-01-01-hello-world.md'))
          .writeAsStringSync('''
---
layout: default
title: Hello World
date: 2024-01-01
---
# Hello World

This is my first post!
''');

      // Test the GenGen library with new simplified API
      final generator = GenGen()
        ..source(projectRoot)
        ..destination(p.join(projectRoot, '_site'));

      // Build the site
      final result = await generator.build();

      // Verify build results
      expect(result['title'], equals('Test Site'));
      expect(result['posts_count'], equals(1));

      // Get site info
      final siteInfo = await generator.getSiteInfo();
      expect(siteInfo['title'], equals('Test Site'));
      expect(siteInfo['description'], equals('A test site for GenGen library'));
      expect(siteInfo['posts_count'], equals(1));

      // Verify the site was initialized and works
      expect(generator.isInitialized, isTrue);
      expect(generator.site.posts.length, equals(1));

      // Clean up
      generator.dispose();
    });

    test('should handle configuration errors gracefully', () async {
      final generator = GenGen()..source('/nonexistent-directory');

      // Try to build with invalid source directory
      await expectLater(generator.build(), throwsA(isA<SiteBuildException>()));
    });

    test('should require initialization before operations', () async {
      final generator = GenGen();

      // Dispose immediately to test disposed state
      generator.dispose();

      // Try to build after disposal
      await expectLater(generator.build(), throwsA(isA<GenGenException>()));
    });

    test('should support custom plugins', () async {
      // Create minimal site structure
      await memoryFileSystem.directory(projectRoot).create(recursive: true);
      memoryFileSystem
          .file(p.join(projectRoot, '_config.yaml'))
          .writeAsStringSync('''
title: Plugin Test Site
''');

      // Create a test plugin
      final testPlugin = TestPlugin();

      final generator = GenGen()
        ..source(projectRoot)
        ..destination(p.join(projectRoot, '_site'))
        ..plugin(testPlugin);

      // Build to initialize
      await generator.build();

      // Verify plugin was added
      expect(generator.site.plugins.whereType<TestPlugin>().length, equals(1));

      generator.dispose();
    });

    test('should provide access to site data', () async {
      // Create minimal site structure
      await memoryFileSystem.directory(projectRoot).create(recursive: true);
      memoryFileSystem
          .file(p.join(projectRoot, '_config.yaml'))
          .writeAsStringSync('''
title: Data Test Site
''');

      final generator = GenGen()
        ..source(projectRoot)
        ..destination(p.join(projectRoot, '_site'));

      // Build to initialize
      await generator.build();

      // Access site data
      final site = generator.site;
      expect(site.config.get<String>('title'), equals('Data Test Site'));

      generator.dispose();
    });
  });
}

/// Test plugin for verifying plugin system integration
class TestPlugin extends BasePlugin {
  @override
  PluginMetadata get metadata => PluginMetadata(
    name: 'TestPlugin',
    version: '1.0.0',
    description: 'A test plugin',
  );
}
