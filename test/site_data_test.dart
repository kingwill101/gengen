import 'package:file/memory.dart';
import 'package:gengen/site.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/logging.dart';
import 'package:gengen/configuration.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  initLog();
  late MemoryFileSystem memoryFileSystem;
  late String projectRoot;

  setUp(() {
    memoryFileSystem = MemoryFileSystem();
    gengen_fs.fs = memoryFileSystem;
    projectRoot = memoryFileSystem.currentDirectory.path;

    // Create a comprehensive site structure for testing data features
    final sourcePath = p.join(projectRoot, 'source');
    final sourceDir = memoryFileSystem.directory(sourcePath);
    sourceDir.createSync(recursive: true);

    // Create site data structure
    final dataPath = p.join(sourcePath, '_data');
    memoryFileSystem.directory(dataPath).createSync(recursive: true);
    
    // Users data file
    memoryFileSystem.file(p.join(dataPath, 'users.yml')).writeAsStringSync('''
tom:
  name: Tom Preston-Werner
  github: mojombo
  role: founder
dick:
  name: Dick Costolo
  twitter: dickc
  role: ceo
''');

    // Navigation data
    memoryFileSystem.file(p.join(dataPath, 'navigation.yml')).writeAsStringSync('''
- name: Home
  url: /
- name: About
  url: /about/
''');

    // Create posts
    final postsPath = p.join(sourcePath, '_posts');
    memoryFileSystem.directory(postsPath).createSync(recursive: true);
    
    memoryFileSystem.file(p.join(postsPath, '2024-01-01-first-post.md'))
        .writeAsStringSync('''
---
title: First Post
date: 2024-01-01
author: tom
featured: true
---
Welcome to my site!
''');

    memoryFileSystem.file(p.join(postsPath, '2024-02-01-latest-post.md'))
        .writeAsStringSync('''
---
title: Latest Post
date: 2024-02-01
author: dick
featured: false
---
Latest update!
''');

    // Create pages
    memoryFileSystem.file(p.join(sourcePath, 'index.md'))
        .writeAsStringSync('''
---
title: Home
layout: default
---
Welcome to the homepage!
''');

    memoryFileSystem.file(p.join(sourcePath, 'about.md'))
        .writeAsStringSync('''
---
title: About
layout: page
team_size: 10
---
About us page.
''');

    // Create static files
    memoryFileSystem.file(p.join(sourcePath, 'robots.txt'))
        .writeAsStringSync('User-agent: *\nDisallow:');

    // Create layouts
    final layoutsPath = p.join(sourcePath, '_layouts');
    memoryFileSystem.directory(layoutsPath).createSync(recursive: true);
    
    memoryFileSystem.file(p.join(layoutsPath, 'default.html')).writeAsStringSync('''
<!DOCTYPE html>
<html>
<head><title>{{ page.title }}</title></head>
<body>{{ content }}</body>
</html>
''');

    // Theme structure (minimal)
    final themePath = p.join(sourcePath, '_themes', 'default');
    memoryFileSystem.directory(themePath).createSync(recursive: true);
    
    final themeLayoutsPath = p.join(themePath, '_layouts');
    memoryFileSystem.directory(themeLayoutsPath).createSync(recursive: true);
    memoryFileSystem.file(p.join(themeLayoutsPath, 'default.html')).writeAsStringSync('{{ content }}');
  });

  group('Site Data Management', () {
    tearDown(() {
      memoryFileSystem.directory(projectRoot).deleteSync(recursive: true);
      Configuration.resetConfig();
      Site.resetInstance();
    });

    test('dump() should export comprehensive site metadata', () async {
      Site.init(overrides: {
        'source': p.join(projectRoot, 'source'),
        'destination': p.join(projectRoot, 'public'),
        'theme': 'default',
      });

      final site = Site.instance;
      final siteData = await site.dump();

      // Verify basic site information
      expect(siteData['source'], equals(p.join(projectRoot, 'source')));
      expect(siteData['destination'], equals(p.join(projectRoot, 'public')));
      expect(siteData['workingDir'], isA<String>());

      // Verify content collections
      expect(siteData['posts'], isA<List<Map<String, dynamic>>>());
      expect(siteData['pages'], isA<List<Map<String, dynamic>>>());
      expect(siteData['staticFiles'], isA<List<Base>>());

      // Verify posts data
      final posts = siteData['posts'] as List<Map<String, dynamic>>;
      expect(posts.length, equals(2));

      // Verify pages data  
      final pages = siteData['pages'] as List<Map<String, dynamic>>;
      expect(pages.length, greaterThanOrEqualTo(2));

      // Verify layouts
      expect(siteData['layouts'], isA<Map<String, dynamic>>());

      // Verify plugins
      expect(siteData['plugins'], isA<List<Map<String, dynamic>>>());

      // Verify configuration
      expect(siteData['config'], isA<Map<String, dynamic>>());
    });

    test('data getter should provide access to _data directory contents', () async {
      Site.init(overrides: {
        'source': p.join(projectRoot, 'source'),
        'destination': p.join(projectRoot, 'public'),
        'theme': 'default',
      });

      final site = Site.instance;
      await site.read();

      final siteData = site.data;

      // Verify users data
      expect(siteData['users'], isA<Map<String, dynamic>>());
      final users = siteData['users'] as Map<String, dynamic>;
      expect(users.containsKey('tom'), isTrue);
      expect(users['tom']['name'], equals('Tom Preston-Werner'));

      // Verify navigation data
      expect(siteData['navigation'], isA<List<dynamic>>());
      final navigation = siteData['navigation'] as List<dynamic>;
      expect(navigation.length, equals(2));
      expect(navigation.first, isA<Map<String, Object?>>());
    });

    test('map getter should provide liquid template context', () async {
      Site.init(overrides: {
        'source': p.join(projectRoot, 'source'),
        'destination': p.join(projectRoot, 'public'),
        'theme': 'default',
      });

      final site = Site.instance;
      await site.read();

      final liquidContext = site.map;

      // Verify posts are included and sorted by date (newest first)
      expect(liquidContext.containsKey('posts'), isTrue);
      final posts = liquidContext['posts'] as List;
      expect(posts.length, equals(2));

      // Verify posts are sorted by date descending  
      // Posts are DocumentDrop objects with invoke() method for accessing properties
      final postTitles = posts.map((post) => post.invoke(const Symbol('title'))).toList();
      expect(postTitles, equals(['Latest Post', 'First Post']));

      // Verify pages are included
      expect(liquidContext.containsKey('pages'), isTrue);
      final pages = liquidContext['pages'] as List;
      expect(pages.length, greaterThanOrEqualTo(2));

      // Verify theme information
      expect(liquidContext.containsKey('theme'), isTrue);
      final theme = liquidContext['theme'] as Map;
      expect(theme.containsKey('root'), isTrue);
    });

    test('non-date posts use front matter date for ordering and permalinks', () async {
      final sourcePath = p.join(projectRoot, 'source');
      final postsPath = p.join(sourcePath, '_posts');
      memoryFileSystem
          .file(p.join(postsPath, 'mid-post.md'))
          .writeAsStringSync('''
---
title: Mid Post
date: 2024-01-15
---
Mid content.
''');

      Site.init(overrides: {
        'source': sourcePath,
        'destination': p.join(projectRoot, 'public'),
        'theme': 'default',
      });

      final site = Site.instance;
      await site.read();

      final titles = site.posts.map((post) => post.config['title']).toList();
      expect(titles, equals(['Latest Post', 'Mid Post', 'First Post']));

      final midPost =
          site.posts.firstWhere((post) => post.config['title'] == 'Mid Post');
      expect(midPost.link(), contains('2024/01/15'));
    });

    test('dump() should handle empty site gracefully', () async {
      // Create an empty source directory
      final emptySourcePath = p.join(projectRoot, 'empty_source');
      memoryFileSystem.directory(emptySourcePath).createSync(recursive: true);

      Site.init(overrides: {
        'source': emptySourcePath,
        'destination': p.join(projectRoot, 'public'),
        'theme': 'default',
      });

      final site = Site.instance;
      final siteData = await site.dump();

      // Verify basic structure exists even with empty site
      expect(siteData['posts'], isA<List<Map<String, dynamic>>>());
      expect(siteData['pages'], isA<List<Map<String, dynamic>>>());
      expect(siteData['staticFiles'], isA<List<Base>>());

      expect(
        (siteData['posts'] as List<Map<String, dynamic>>).isEmpty,
        isTrue,
      );
      expect(
        (siteData['pages'] as List<Map<String, dynamic>>).isEmpty,
        isTrue,
      );
      expect(
        (siteData['staticFiles'] as List<Base>).isEmpty,
        isTrue,
      );

      // Configuration and basic info should still be present
      expect(siteData['source'], equals(emptySourcePath));
      expect(siteData['workingDir'], isA<String>());
    });

    test('data getter should handle missing _data directory gracefully', () async {
      // Create source without _data directory
      final sourceWithoutData = p.join(projectRoot, 'no_data_source');
      memoryFileSystem.directory(sourceWithoutData).createSync(recursive: true);

      Site.init(overrides: {
        'source': sourceWithoutData,
        'destination': p.join(projectRoot, 'public'),
        'theme': 'default',
      });

      final site = Site.instance;
      await site.read();

      final siteData = site.data;
      
      // Should return empty map when no _data directory exists
      expect(siteData, isA<Map<String, dynamic>>());
      expect(siteData.isEmpty, isTrue);
    });

    test('dump() should preserve data types correctly', () async {
      Site.init(overrides: {
        'source': p.join(projectRoot, 'source'),
        'destination': p.join(projectRoot, 'public'),
        'theme': 'default',
      });

      final site = Site.instance;
      final siteData = await site.dump();

      // Verify that different data types are preserved in the dump
      final posts = siteData['posts'] as List;
      final firstPost = posts.firstWhere((post) => post['config']['title'] == 'First Post');
      
      // String values
      expect(firstPost['config']['title'], isA<String>());
      expect(firstPost['config']['author'], isA<String>());
      
      // Date values (stored as string in config)
      expect(firstPost['config']['date'], isA<String>());
      
      // Boolean values  
      expect(firstPost['config']['featured'], isA<bool>());
      expect(firstPost['config']['featured'], isTrue);

      // Verify numeric values in pages
      final pages = siteData['pages'] as List;
      final aboutPage = pages.firstWhere((page) => page['config']['title'] == 'About');
      expect(aboutPage['config']['team_size'], isA<int>());
      expect(aboutPage['config']['team_size'], equals(10));
    });

    test('map getter should provide consistent data across multiple calls', () async {
      Site.init(overrides: {
        'source': p.join(projectRoot, 'source'),
        'destination': p.join(projectRoot, 'public'),
        'theme': 'default',
      });

      final site = Site.instance;
      await site.read();

      final context1 = site.map;
      final context2 = site.map;

      // Verify that multiple calls return consistent data
      expect(context1['posts'].length, equals(context2['posts'].length));
      expect(context1['pages'].length, equals(context2['pages'].length));
      
      final posts1 = context1['posts'] as List<dynamic>;
      final posts2 = context2['posts'] as List<dynamic>;
      
      // Verify post order is consistent
      for (int i = 0; i < posts1.length; i++) {
        final title1 = posts1[i].invoke(const Symbol('title'));
        final title2 = posts2[i].invoke(const Symbol('title'));
        expect(title1, equals(title2));
      }
    });

    test('dump() should include plugin information', () async {
      Site.init(overrides: {
        'source': p.join(projectRoot, 'source'),
        'destination': p.join(projectRoot, 'public'),
        'theme': 'default',
      });

      final site = Site.instance;
      final siteData = await site.dump();

      // Verify plugins are included
      expect(siteData['plugins'], isA<List<Map<String, dynamic>>>());
      final plugins = siteData['plugins'] as List<Map<String, dynamic>>;
      
      // Should have at least the built-in plugins
      expect(plugins.length, greaterThan(0));
      
      // Each plugin should have basic metadata - just verify it's a Map with some content
      for (final plugin in plugins) {
        expect(plugin, isA<Map<String, dynamic>>());
        final pluginData = plugin;
        expect(pluginData.isNotEmpty, isTrue);
      }
    });

    test('data getter should support different data file formats', () async {
      // Add JSON data file
      final sourcePath = p.join(projectRoot, 'source');
      final dataPath = p.join(sourcePath, '_data');
      
      memoryFileSystem.file(p.join(dataPath, 'config.json')).writeAsStringSync('''
{
  "site_name": "Test Site",
  "version": "1.0.0",
  "features": {
    "search": true,
    "comments": false
  }
}
''');

      Site.init(overrides: {
        'source': sourcePath,
        'destination': p.join(projectRoot, 'public'),
        'theme': 'default',
      });

      final site = Site.instance;
      await site.read();

      final siteData = site.data;

      // Verify JSON data is properly parsed
      expect(siteData['config'], isA<Map<String, dynamic>>());
      final config = siteData['config'] as Map<String, dynamic>;
      expect(config['site_name'], equals('Test Site'));
      expect(config['version'], equals('1.0.0'));
      expect(config['features']['search'], isTrue);
      expect(config['features']['comments'], isFalse);

      // Verify YAML data is still present
      expect(siteData['users'], isA<Map<String, dynamic>>());
      expect(siteData['navigation'], isA<List<dynamic>>());
    });
  });
} 
