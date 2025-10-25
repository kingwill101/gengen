import 'package:file/memory.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/plugin/builtin/sitemap.dart';
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

  group('SitemapPlugin', () {
    test('should have correct metadata', () {
      final plugin = SitemapPlugin();
      expect(plugin.metadata.name, equals('SitemapPlugin'));
      expect(plugin.metadata.version, equals('1.0.0'));
      expect(plugin.metadata.description, equals('Generates XML sitemap for all site content'));
    });

    test('should use default configuration values', () {
      final plugin = SitemapPlugin();
      expect(plugin.outputPath, equals('sitemap.xml'));
    });

    test('should accept custom configuration', () {
      final plugin = SitemapPlugin(
        outputPath: 'my-sitemap.xml',
      );
      expect(plugin.outputPath, equals('my-sitemap.xml'));
    });

    test('should generate sitemap from posts and pages', () async {
      // Create test site structure
      await memoryFileSystem.directory(p.join(projectRoot, '_posts')).create(recursive: true);
      await memoryFileSystem.directory(p.join(projectRoot, '_layouts')).create(recursive: true);
      await memoryFileSystem.directory(p.join(projectRoot, 'public')).create(recursive: true);

      // Create config
      memoryFileSystem.file(p.join(projectRoot, 'config.yaml')).writeAsStringSync('''
title: Test Site
description: A test site for sitemap generation
url: https://example.com
''');

      // Create posts
      memoryFileSystem.file(p.join(projectRoot, '_posts', '2024-01-01-first-post.md')).writeAsStringSync('''
---
title: First Post
date: 2024-01-01
---

This is the first post.
''');

      // Create pages
      memoryFileSystem.file(p.join(projectRoot, 'about.md')).writeAsStringSync('''
---
title: About
layout: default
---

This is the about page.
''');

      // Create layout
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

      await Site.instance.read();

      // Test plugin
      final plugin = SitemapPlugin();
      await plugin.afterRender();

      // Check that sitemap file was created
      final sitemapFile = memoryFileSystem.file(p.join(projectRoot, 'public', 'sitemap.xml'));
      expect(await sitemapFile.exists(), isTrue);

      // Check sitemap content
      final sitemapContent = await sitemapFile.readAsString();
      expect(sitemapContent, contains('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(sitemapContent, contains('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'));
      expect(sitemapContent, contains('<priority>1.0</priority>'));
      expect(sitemapContent, contains('<changefreq>daily</changefreq>'));
      expect(sitemapContent, contains('first-post.html'));
      expect(sitemapContent, contains('about.html'));
    });

    test('should handle empty content gracefully', () async {
      // Create test site structure with no content
      await memoryFileSystem.directory(p.join(projectRoot, 'public')).create(recursive: true);

      // Create config
      memoryFileSystem.file(p.join(projectRoot, 'config.yaml')).writeAsStringSync('''
title: Empty Site
description: A site with no content
url: https://example.com
''');

      // Initialize site
      Site.init(overrides: {
        'source': projectRoot,
        'destination': p.join(projectRoot, 'public'),
      });

      await Site.instance.read();

      // Test plugin
      final plugin = SitemapPlugin();
      await plugin.afterRender();

      // Check that sitemap file was not created
      final sitemapFile = memoryFileSystem.file(p.join(projectRoot, 'public', 'sitemap.xml'));
      expect(await sitemapFile.exists(), isFalse);
    });

    test('should exclude drafts from sitemap', () async {
      // Create test site structure
      await memoryFileSystem.directory(p.join(projectRoot, '_posts')).create(recursive: true);
      await memoryFileSystem.directory(p.join(projectRoot, '_layouts')).create(recursive: true);
      await memoryFileSystem.directory(p.join(projectRoot, 'public')).create(recursive: true);

      // Create config
      memoryFileSystem.file(p.join(projectRoot, 'config.yaml')).writeAsStringSync('''
title: Test Site
url: https://example.com
''');

      // Create published post
      memoryFileSystem.file(p.join(projectRoot, '_posts', '2024-01-01-published.md')).writeAsStringSync('''
---
title: Published Post
date: 2024-01-01
---

This post is published.
''');

      // Create draft post
      memoryFileSystem.file(p.join(projectRoot, '_posts', '2024-01-02-draft.md')).writeAsStringSync('''
---
title: Draft Post
date: 2024-01-02
draft: true
---

This post is a draft.
''');

      // Create layout
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

      await Site.instance.read();

      // Test plugin
      final plugin = SitemapPlugin();
      await plugin.afterRender();

      // Check sitemap content
      final sitemapFile = memoryFileSystem.file(p.join(projectRoot, 'public', 'sitemap.xml'));
      final sitemapContent = await sitemapFile.readAsString();
      
      // Should contain published post but not draft
      expect(sitemapContent, contains('published-post.html'));
      expect(sitemapContent, isNot(contains('draft.html')));
    });
  });
} 