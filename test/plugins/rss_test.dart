import 'package:file/memory.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/plugin/builtin/rss.dart';
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

  group('RssPlugin', () {
    test('should have correct metadata', () {
      final plugin = RssPlugin();
      expect(plugin.metadata.name, equals('RssPlugin'));
      expect(plugin.metadata.version, equals('1.0.0'));
      expect(
        plugin.metadata.description,
        equals('Generates RSS 2.0 feed from site posts'),
      );
    });

    test('should use default configuration values', () {
      final plugin = RssPlugin();
      expect(plugin.outputPath, equals('feed.xml'));
      expect(plugin.maxPosts, equals(20));
    });

    test('should accept custom configuration', () {
      final plugin = RssPlugin(outputPath: 'rss.xml', maxPosts: 10);
      expect(plugin.outputPath, equals('rss.xml'));
      expect(plugin.maxPosts, equals(10));
    });

    test('should generate RSS feed from posts', () async {
      // Create test site structure
      await memoryFileSystem
          .directory(p.join(projectRoot, '_posts'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_layouts'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, 'public'))
          .create(recursive: true);

      // Create config
      memoryFileSystem
          .file(p.join(projectRoot, 'config.yaml'))
          .writeAsStringSync('''
title: Test Site
description: A test site for RSS generation
url: https://example.com
''');

      // Create posts
      memoryFileSystem
          .file(p.join(projectRoot, '_posts', '2024-01-01-first-post.md'))
          .writeAsStringSync('''
---
title: First Post
date: 2024-01-01
excerpt: This is the first post excerpt
---

This is the content of the first post.
''');

      memoryFileSystem
          .file(p.join(projectRoot, '_posts', '2024-01-02-second-post.md'))
          .writeAsStringSync('''
---
title: Second Post
date: 2024-01-02
---

This is the content of the second post.
''');

      // Create layout
      memoryFileSystem
          .file(p.join(projectRoot, '_layouts', 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body>{{ content }}</body></html>
''');

      // Initialize site
      Site.init(
        overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        },
      );

      await Site.instance.read();

      // Test plugin
      final plugin = RssPlugin();
      await plugin.afterRender();

      // Check that RSS file was created
      final rssFile = memoryFileSystem.file(
        p.join(projectRoot, 'public', 'feed.xml'),
      );
      expect(await rssFile.exists(), isTrue);

      // Check RSS content
      final rssContent = await rssFile.readAsString();
      expect(rssContent, contains('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(rssContent, contains('<rss version="2.0"'));
      expect(rssContent, contains('First Post'));
      expect(rssContent, contains('Second Post'));
      expect(rssContent, contains('This is the first post excerpt'));
    });

    test('should handle empty posts gracefully', () async {
      // Create test site structure with no posts
      await memoryFileSystem
          .directory(p.join(projectRoot, 'public'))
          .create(recursive: true);

      // Create config
      memoryFileSystem
          .file(p.join(projectRoot, 'config.yaml'))
          .writeAsStringSync('''
title: Empty Site
description: A site with no posts
url: https://example.com
''');

      // Initialize site
      Site.init(
        overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        },
      );

      await Site.instance.read();

      // Test plugin
      final plugin = RssPlugin();
      await plugin.afterRender();

      // Check that RSS file was not created
      final rssFile = memoryFileSystem.file(
        p.join(projectRoot, 'public', 'feed.xml'),
      );
      expect(await rssFile.exists(), isFalse);
    });
  });
}
