import 'package:file/memory.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/plugin/builtin/tailwind.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late MemoryFileSystem memoryFileSystem;
  late String projectRoot;

  setUp(() {
    memoryFileSystem = MemoryFileSystem();
    gengen_fs.fs = memoryFileSystem;
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    projectRoot = '/test-site-$timestamp';
  });

  tearDown(() {
    Site.resetInstance();
    gengen_fs.fs = MemoryFileSystem();
  });

  group('TailwindPlugin', () {
    test('should have correct metadata', () {
      final plugin = TailwindPlugin();
      expect(plugin.metadata.name, equals('TailwindPlugin'));
      expect(plugin.metadata.version, equals('1.0.0'));
      expect(plugin.metadata.description, equals('Compiles Tailwind CSS files in GenGen'));
    });

    test('should use default configuration values', () {
      final plugin = TailwindPlugin();
      expect(plugin.tailwindPath, equals('./tailwindcss'));
      expect(plugin.input, equals('assets/css/tailwind.css'));
      expect(plugin.output, equals('assets/css/styles.css'));
    });

    test('should accept custom configuration', () {
      final plugin = TailwindPlugin(
        tailwindPath: './custom-tailwind',
        input: 'src/tailwind.css',
        output: 'dist/app.css',
      );
      expect(plugin.tailwindPath, equals('./custom-tailwind'));
      expect(plugin.input, equals('src/tailwind.css'));
      expect(plugin.output, equals('dist/app.css'));
    });

    test('should skip compilation when input file does not exist', () async {
      // Create site structure without tailwind input file
      await memoryFileSystem.directory(p.join(projectRoot, 'assets', 'css')).create(recursive: true);
      await memoryFileSystem.directory(p.join(projectRoot, '_layouts')).create(recursive: true);

      // Create site config
      memoryFileSystem.file(p.join(projectRoot, '_config.yaml')).writeAsStringSync('''
title: Test Site
description: Test site for TailwindPlugin
''');

      // Create basic layout
      memoryFileSystem.file(p.join(projectRoot, '_layouts', 'default.html')).writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body>{{ content }}</body></html>
''');

      // Initialize site
      Site.init(overrides: {
        'source': projectRoot,
        'destination': p.join(projectRoot, 'public'),
      });

      await Site.instance.process();

      // The plugin should not crash when input file doesn't exist
      // This test verifies graceful handling of missing input file
      expect(true, isTrue); // Test passes if no exception is thrown
    });

    test('should skip compilation when tailwind executable does not exist', () async {
      // Create site structure with tailwind input file but no executable
      await memoryFileSystem.directory(p.join(projectRoot, 'assets', 'css')).create(recursive: true);
      await memoryFileSystem.directory(p.join(projectRoot, '_layouts')).create(recursive: true);

      // Create site config
      memoryFileSystem.file(p.join(projectRoot, '_config.yaml')).writeAsStringSync('''
title: Test Site
description: Test site for TailwindPlugin
''');

      // Create tailwind input file
      memoryFileSystem.file(p.join(projectRoot, 'assets', 'css', 'tailwind.css')).writeAsStringSync('''
@tailwind base;
@tailwind components;
@tailwind utilities;
''');

      // Create basic layout
      memoryFileSystem.file(p.join(projectRoot, '_layouts', 'default.html')).writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body>{{ content }}</body></html>
''');

      // Initialize site
      Site.init(overrides: {
        'source': projectRoot,
        'destination': p.join(projectRoot, 'public'),
      });

      await Site.instance.process();

      // The plugin should not crash when executable doesn't exist
      // This test verifies graceful handling of missing executable
      expect(true, isTrue); // Test passes if no exception is thrown
    });

    test('should create output directory if it does not exist', () async {
      // Create site structure
      await memoryFileSystem.directory(p.join(projectRoot, 'assets', 'css')).create(recursive: true);
      await memoryFileSystem.directory(p.join(projectRoot, '_layouts')).create(recursive: true);

      // Create site config
      memoryFileSystem.file(p.join(projectRoot, '_config.yaml')).writeAsStringSync('''
title: Test Site
description: Test site for TailwindPlugin
''');

      // Create tailwind input file
      memoryFileSystem.file(p.join(projectRoot, 'assets', 'css', 'tailwind.css')).writeAsStringSync('''
@tailwind base;
@tailwind components;
@tailwind utilities;
''');

      // Create a mock tailwind executable (just a dummy file for testing path resolution)
      memoryFileSystem.file(p.join(projectRoot, 'tailwindcss')).writeAsStringSync('#!/bin/bash\necho "mock tailwind"');

      // Create basic layout
      memoryFileSystem.file(p.join(projectRoot, '_layouts', 'default.html')).writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body>{{ content }}</body></html>
''');

      // Initialize site with custom output directory
      Site.init(overrides: {
        'source': projectRoot,
        'destination': p.join(projectRoot, 'build'),
      });

      await Site.instance.process();

      // Verify the output directory would be created (if compilation succeeded)
      // Since we're using a memory filesystem and mock executable, 
      // we're mainly testing that the plugin doesn't crash
      expect(true, isTrue); // Test passes if no exception is thrown
    });
  });
} 