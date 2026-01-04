import 'package:file/memory.dart';
import 'package:gengen/site.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/configuration.dart';
import 'package:gengen/plugin/builtin/liquid.dart';
import 'package:gengen/plugin/builtin/markdown.dart';
import 'package:test/test.dart';
import 'package:logging/logging.dart';

void main() {
  group('Plugin Debug Tests', () {
    late MemoryFileSystem fs;
    late Site site;

    // Set up logging to capture detailed output
    setUpAll(() {
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) {
        print('${record.level.name}: ${record.loggerName}: ${record.message}');
        if (record.error != null) {
          print('Error: ${record.error}');
        }
        if (record.stackTrace != null) {
          print('Stack trace: ${record.stackTrace}');
        }
      });
    });

    tearDown(() {
      Configuration.resetConfig();
    });

    setUp(() async {
      fs = MemoryFileSystem();
      gengen_fs.fs = fs;

      final projectRoot = fs.currentDirectory.path;

      // Create test site structure  
      await fs.directory('$projectRoot/test_site').create(recursive: true);
      await fs.directory('$projectRoot/test_site/_posts').create(recursive: true);
      await fs.directory('$projectRoot/test_site/_themes').create(recursive: true);
      await fs.directory('$projectRoot/test_site/_themes/default').create(recursive: true);
      await fs.directory('$projectRoot/test_site/_themes/default/_layouts').create(recursive: true);
      await fs.directory('$projectRoot/test_site/public').create(recursive: true);

      // Create config file
      await fs.file('$projectRoot/test_site/_config.yaml').writeAsString('''
title: "Test Site"
source: $projectRoot/test_site
destination: $projectRoot/test_site/public
permalink: "posts/:title/"
''');

      // Create a default layout
      await fs.file('$projectRoot/test_site/_themes/default/_layouts/default.html').writeAsString('''
<!DOCTYPE html>
<html>
<head><title>{{ page.title }}</title></head>
<body>{{ content }}</body>
</html>
''');

      // Create theme config
      await fs.file('$projectRoot/test_site/_themes/default/config.yaml').writeAsString('''
name: default
version: 1.0.0
''');

      // Create the problematic post
      await fs.file('$projectRoot/test_site/_posts/2024-01-10-pagination-test.md').writeAsString('''
---
title: "Pagination Test Post"
date: 2024-01-10
layout: default
---

# Pagination Test Post

This post has problematic liquid syntax:

{% for post in site.paginate.items %}
  <article>{{ post.title }}</article>
{% endfor %}

Regular content after liquid.
''');

      // Create a simple working post
      await fs.file('$projectRoot/test_site/_posts/2024-01-15-simple-post.md').writeAsString('''
---
title: "Simple Test Post"
date: 2024-01-15
layout: default
---

# Simple Test Post

This is a simple test post with NO liquid syntax.

Just some regular markdown content here.
''');
    });

    test('should test with NO plugins enabled', () async {
      print('\n=== TESTING WITH NO PLUGINS ===');
      
      Site.init(overrides: {
        'source': '${fs.currentDirectory.path}/test_site',
        'destination': '${fs.currentDirectory.path}/test_site/public',
      });
      site = Site.instance;
      
      // Clear all plugins
      site.plugins.clear();
      print('Active plugins: ${site.plugins.map((p) => p.runtimeType).toList()}');
      
      await site.process();

      final problematicPost = site.posts.firstWhere(
        (post) => post.name.contains('pagination-test'),
      );

      print('\n--- PROBLEMATIC POST (NO PLUGINS) ---');
      print('Content length: ${problematicPost.content.length}');
      
      await problematicPost.render();
      print('Rendered content length: ${problematicPost.renderer.content.length}');
      
      await problematicPost.write();
      
      final outputFile = fs.file(problematicPost.filePath);
      expect(await outputFile.exists(), true);
      final fileContent = await outputFile.readAsString();
      print('Output file size: ${fileContent.length} bytes');
      print('Output preview: ${fileContent.substring(0, fileContent.length > 200 ? 200 : fileContent.length)}...');
      
      expect(fileContent.isNotEmpty, true);
      expect(fileContent, contains('# Pagination Test Post'));
      expect(fileContent, contains('{% for post in site.paginate.items %}'));
    });

    test('should test with ONLY markdown plugin enabled', () async {
      print('\n=== TESTING WITH ONLY MARKDOWN PLUGIN ===');
      
      Site.init(overrides: {
        'source': '${fs.currentDirectory.path}/test_site',
        'destination': '${fs.currentDirectory.path}/test_site/public',
      });
      site = Site.instance;
      
      site.plugins.clear();
      site.plugins.add(MarkdownPlugin());
      print('Active plugins: ${site.plugins.map((p) => p.runtimeType).toList()}');
      
      await site.process();

      final problematicPost = site.posts.firstWhere(
        (post) => post.name.contains('pagination-test'),
      );

      print('\n--- PROBLEMATIC POST (MARKDOWN ONLY) ---');
      
      await problematicPost.render();
      print('Rendered content length: ${problematicPost.renderer.content.length}');
      
      await problematicPost.write();
      
      final outputFile = fs.file(problematicPost.filePath);
      final fileContent = await outputFile.readAsString();
      print('Output file size: ${fileContent.length} bytes');
      print('Output preview: ${fileContent.substring(0, fileContent.length > 200 ? 200 : fileContent.length)}...');
      
      expect(fileContent.isNotEmpty, true);
      expect(fileContent, contains('Pagination Test Post'));
      expect(fileContent, contains('{% for post in site.paginate.items %}'));
    });

    test('should test with ONLY liquid plugin enabled', () async {
      print('\n=== TESTING WITH ONLY LIQUID PLUGIN ===');
      
      Site.init(overrides: {
        'source': '${fs.currentDirectory.path}/test_site',
        'destination': '${fs.currentDirectory.path}/test_site/public',
      });
      site = Site.instance;
      
      site.plugins.clear();
      site.plugins.add(LiquidPlugin());
      print('Active plugins: ${site.plugins.map((p) => p.runtimeType).toList()}');
      
      await site.process();

      final problematicPost = site.posts.firstWhere(
        (post) => post.name.contains('pagination-test'),
      );

      print('\n--- PROBLEMATIC POST (LIQUID ONLY) ---');
      
      await problematicPost.render();
      print('Rendered content length: ${problematicPost.renderer.content.length}');
      
      await problematicPost.write();
      
      final outputFile = fs.file(problematicPost.filePath);
      final fileContent = await outputFile.readAsString();
      print('Output file size: ${fileContent.length} bytes');
      print('Output preview: ${fileContent.substring(0, fileContent.length > 200 ? 200 : fileContent.length)}...');
      
      expect(fileContent.isNotEmpty, true);
      expect(fileContent, contains('# Pagination Test Post'));
    });

    test('should test liquid plugin directly', () async {
      print('\n=== TESTING LIQUID PLUGIN DIRECTLY ===');
      
      Site.init(overrides: {
        'source': '${fs.currentDirectory.path}/test_site',
        'destination': '${fs.currentDirectory.path}/test_site/public',
      });
      site = Site.instance;
      
      await site.process();

      final problematicPost = site.posts.firstWhere(
        (post) => post.name.contains('pagination-test'),
      );

      print('\n--- MANUAL LIQUID PLUGIN TESTING ---');
      print('Original content: ${problematicPost.content}');
      
      final liquidPlugin = LiquidPlugin();
      
      try {
        final result = await liquidPlugin.convert(problematicPost.content, problematicPost);
        print('Liquid plugin result length: ${result.length}');
        print('Liquid plugin result: "$result"');
        
        if (result.isEmpty) {
          print('ERROR: Liquid plugin returned empty string!');
        }
      } catch (e, stack) {
        print('ERROR: Liquid plugin threw exception: $e');
        print('Stack trace: $stack');
      }
    });
  });
} 