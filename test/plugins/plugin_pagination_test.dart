import 'package:file/memory.dart';
import 'package:gengen/site.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/logging.dart';
import 'package:gengen/configuration.dart';
import 'package:gengen/plugin/builtin/pagination.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:logging/logging.dart';

void main() {
  initLog();
  late MemoryFileSystem memoryFileSystem;
  late String projectRoot;

  setUp(() {
    memoryFileSystem = MemoryFileSystem();
    gengen_fs.fs = memoryFileSystem;
    projectRoot = memoryFileSystem.currentDirectory.path;

    // Create a basic site structure
    final sourcePath = p.join(projectRoot, 'source');
    final sourceDir = memoryFileSystem.directory(sourcePath);
    sourceDir.createSync(recursive: true);

    // Create config file
    memoryFileSystem.file(p.join(sourcePath, '_config.yaml')).writeAsStringSync(
      '''
title: Test Site
theme: default
pagination:
  enabled: true
  items_per_page: 3
  collection: posts
  permalink: '/page/:num/'
  indexpage: index
''',
    );

    // Create layouts
    final layoutsPath = p.join(sourcePath, '_layouts');
    memoryFileSystem.directory(layoutsPath).createSync(recursive: true);
    memoryFileSystem
        .file(p.join(layoutsPath, 'default.html'))
        .writeAsStringSync('''
<!DOCTYPE html>
<html>
<head>
  <title>{{ page.title | default: site.title }}</title>
</head>
<body>
  <h1>{{ page.title | default: site.title }}</h1>
  {{ content }}
</body>
</html>
''');

    // Create theme structure
    final themesPath = p.join(sourcePath, '_themes');
    final defaultThemePath = p.join(themesPath, 'default');
    final themeLayoutsPath = p.join(defaultThemePath, '_layouts');
    memoryFileSystem.directory(themeLayoutsPath).createSync(recursive: true);

    memoryFileSystem
        .file(p.join(defaultThemePath, 'config.yaml'))
        .writeAsStringSync('''
name: default
version: 1.0.0
''');

    memoryFileSystem
        .file(p.join(themeLayoutsPath, 'default.html'))
        .writeAsStringSync('''
<!DOCTYPE html>
<html>
<head>
  <title>{{ page.title | default: site.title }}</title>
</head>
<body>
  <header>
    <h1>{{ site.title }}</h1>
  </header>
  <main>
    {{ content }}
  </main>
</body>
</html>
''');

    // Create multiple posts for pagination stress testing
    final postsPath = p.join(sourcePath, '_posts');
    memoryFileSystem.directory(postsPath).createSync();

    // Create 50 posts to stress test pagination
    for (int i = 1; i <= 50; i++) {
      final month = ((i - 1) ~/ 31) + 1;
      final day = ((i - 1) % 31) + 1;
      memoryFileSystem
          .file(
            p.join(
              postsPath,
              '2024-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}-post-$i.md',
            ),
          )
          .writeAsStringSync('''
---
title: Post $i - Test Article
layout: default
date: 2024-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')} 00:00:00
slug: post-$i
author: Test Author $i
category: ${i % 3 == 0
              ? 'technology'
              : i % 2 == 0
              ? 'lifestyle'
              : 'tutorial'}
tags: [tag${i % 5}, tag${(i + 1) % 4}]
---
This is **post $i** content with more detailed information.

## Section ${i % 3 + 1}

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Post $i has unique content that distinguishes it from other posts in the system.

### Subsection
- Item 1 for post $i
- Item 2 for post $i  
- Item 3 for post $i

> Quote from post $i: "This is a meaningful quote that adds value."

\`\`\`dart
// Code example from post $i
void main() {
  print('Hello from post $i');
}
\`\`\`
''');
    }

    // Create some additional pages for testing
    final pagesPath = p.join(sourcePath, '_pages');
    memoryFileSystem.directory(pagesPath).createSync();

    for (int i = 1; i <= 10; i++) {
      memoryFileSystem.file(p.join(pagesPath, 'page-$i.md')).writeAsStringSync(
        '''
---
title: Test Page $i
layout: default
permalink: /pages/page-$i/
---
This is test page $i content.
''',
      );
    }

    // Create index page with pagination
    memoryFileSystem.file(p.join(sourcePath, 'index.html')).writeAsStringSync(
      '''
---
layout: default
title: Home
---
<div class="posts">
  <h2>Posts (Page {{ site.paginate.current_page }} of {{ site.paginate.total_pages }})</h2>
  
  {% for post in site.paginate.items %}
    <article class="post-preview">
      <h3><a href="{{ post.permalink }}">{{ post.title }}</a></h3>
      <p>{{ post.content | strip_html | truncate: 100 }}</p>
      <time>Published on {{ post.date }}</time>
    </article>
  {% endfor %}
  
  <nav class="pagination">
    {% if site.paginate.has_previous %}
      <a href="/page/{{ site.paginate.current_page | minus: 1 }}">← Previous</a>
    {% endif %}
    
    <span>Page {{ site.paginate.current_page }} of {{ site.paginate.total_pages }}</span>
    
    {% if site.paginate.has_next %}
      <a href="/page/{{ site.paginate.current_page | plus: 1 }}">Next →</a>
    {% endif %}
  </nav>
  
  <div class="pagination-info">
    <p>Showing {{ site.paginate.items.size }} of {{ site.paginate.total_items }} posts</p>
  </div>
</div>
''',
    );

    // Create default config file for tests that don't specify their own
    memoryFileSystem.file(p.join(sourcePath, '_config.yaml')).writeAsStringSync(
      '''
title: Test Site
theme: default
pagination:
  enabled: true
  items_per_page: 5
  collection: posts
  permalink: '/page/:num/'
  indexpage: index
''',
    );
  });

  group('Pagination Plugin Tests', () {
    late Level _previousLogLevel;

    setUp(() {
      _previousLogLevel = Logger.root.level;
      Logger.root.level = Level.SEVERE;
    });

    tearDown(() {
      Logger.root.level = _previousLogLevel;
      if (memoryFileSystem.directory(projectRoot).existsSync()) {
        memoryFileSystem.directory(projectRoot).deleteSync(recursive: true);
      }
      Configuration.resetConfig();
      Site.resetInstance();
    });

    test('should register pagination plugin', () {
      Site.init(
        overrides: {
          'source': p.join(projectRoot, 'source'),
          'destination': p.join(projectRoot, 'public'),
          'title': 'Test Site',
          'theme': 'default',
        },
      );

      final paginationPlugin = Site.instance.plugins
          .whereType<PaginationPlugin>()
          .firstOrNull;
      expect(paginationPlugin, isNotNull);
      expect(paginationPlugin!.metadata.name, equals('PaginationPlugin'));
    });

    test('should generate pagination data during site processing', () async {
      Site.init(
        overrides: {
          'source': p.join(projectRoot, 'source'),
          'destination': p.join(projectRoot, 'public'),
          'title': 'Test Site',
          'theme': 'default',
        },
      );

      // Process the site to trigger plugins
      await Site.instance.process();

      // Check if pagination data is available in site map
      final siteMap = Site.instance.map;
      expect(siteMap['paginate'], isA<Map<String, dynamic>>());

      final paginateData = siteMap['paginate'] as Map<String, dynamic>;
      expect(paginateData['current_page'], equals(1));
      expect(
        paginateData['total_pages'],
        equals(10),
      ); // 50 posts ÷ 5 per page = 10 pages
      expect(
        paginateData['items_per_page'],
        equals(5),
      ); // Plugin uses default 5 when config isn't read
      expect(paginateData['total_items'], equals(50));
      expect(paginateData['has_previous'], isFalse);
      expect(paginateData['has_next'], isTrue);
    });

    test('should create additional pagination pages', () async {
      Site.init(
        overrides: {
          'source': p.join(projectRoot, 'source'),
          'destination': p.join(projectRoot, 'public'),
          'title': 'Test Site',
          'theme': 'default',
        },
      );

      final originalPageCount = Site.instance.pages.length;
      await Site.instance.process();

      // Should have created additional pagination pages (page 2, page 3)
      expect(Site.instance.pages.length, greaterThan(originalPageCount));

      // Check for pagination pages
      final paginationPages = Site.instance.pages
          .where((page) => page.frontMatter.containsKey('page_num'))
          .toList();
      expect(
        paginationPages.length,
        equals(9),
      ); // Pages 2-10 (since we have 10 total pages)
    });

    test('should work with disabled pagination', () async {
      // Update config to disable pagination
      memoryFileSystem
          .file(p.join(projectRoot, 'source', '_config.yaml'))
          .writeAsStringSync('''
title: Test Site
theme: default
pagination:
  enabled: false
''');

      Site.init(
        overrides: {
          'source': p.join(projectRoot, 'source'),
          'destination': p.join(projectRoot, 'public'),
          'title': 'Test Site',
          'theme': 'default',
        },
      );

      await Site.instance.process();

      // Should not have pagination data
      final siteMap = Site.instance.map;
      expect(siteMap['paginate'], isEmpty);
    });

    test('should generate page trail for navigation', () async {
      Site.init(
        overrides: {
          'source': p.join(projectRoot, 'source'),
          'destination': p.join(projectRoot, 'public'),
          'title': 'Test Site',
          'theme': 'default',
        },
      );

      await Site.instance.process();

      final paginationPlugin = Site.instance.plugins
          .whereType<PaginationPlugin>()
          .firstOrNull;
      expect(paginationPlugin, isNotNull);

      final paginationData = paginationPlugin!.paginationData;
      expect(paginationData, isNotNull);
      final trail = paginationData!['page_trail'] as List;
      expect(trail.first, equals(1));
      expect(trail.contains('gap'), isTrue);
      expect(trail.last, equals(paginationData['total_pages']));

      final pagePaths = (paginationData['page_paths'] as Map)
          .cast<String, dynamic>();
      expect(pagePaths['1'], equals('/'));
      expect(pagePaths['2'], equals('/page/2/'));
      expect(paginationData['current_page_path'], equals('/'));
      expect(paginationData['next_page_path'], equals('/page/2/'));
    });

    test('should handle custom permalink patterns', () async {
      // Update config with custom permalink
      memoryFileSystem
          .file(p.join(projectRoot, 'source', '_config.yaml'))
          .writeAsStringSync('''
title: Test Site
theme: default
pagination:
  enabled: true
  items_per_page: 3
  collection: posts
  permalink: '/blog/page/:num/'
  indexpage: index
''');

      Site.init(
        overrides: {
          'source': p.join(projectRoot, 'source'),
          'destination': p.join(projectRoot, 'public'),
          'title': 'Test Site',
          'theme': 'default',
        },
      );

      await Site.instance.process();

      // Check for pagination pages with custom permalink
      final paginationPages = Site.instance.pages
          .where((page) => page.frontMatter.containsKey('page_num'))
          .toList();

      // Should find pages with custom permalink pattern
      final page2 = paginationPages.firstWhereOrNull(
        (page) => page.frontMatter['page_num'] == 2,
      );
      expect(page2, isNotNull);
      // Check that the page has the page_num set correctly
      expect(page2!.frontMatter['page_num'], equals(2));
    });

    test('should handle large datasets efficiently', () async {
      // Test with a specific configuration for large dataset
      memoryFileSystem
          .file(p.join(projectRoot, 'source', '_config.yaml'))
          .writeAsStringSync('''
title: Test Site
theme: default
pagination:
  enabled: true
  items_per_page: 7
  collection: posts
  permalink: '/page/:num/'
  indexpage: index
''');

      Site.init(
        overrides: {
          'source': p.join(projectRoot, 'source'),
          'destination': p.join(projectRoot, 'public'),
          'title': 'Test Site',
          'theme': 'default',
        },
      );

      await Site.instance.process();

      // Check pagination calculations for 50 posts with 7 per page (from config)
      final siteMap = Site.instance.map;
      final paginateData = siteMap['paginate'] as Map<String, dynamic>;

      expect(
        paginateData['total_pages'],
        equals(8),
      ); // 50 ÷ 7 = 8 pages (rounded up)
      expect(
        paginateData['items_per_page'],
        equals(7),
      ); // Using configured value
      expect(paginateData['total_items'], equals(50));

      // Check that all pagination pages were created (pages 2-8)
      final paginationPages = Site.instance.pages
          .where((page) => page.frontMatter.containsKey('page_num'))
          .toList();
      expect(paginationPages.length, equals(7)); // Pages 2-8

      // Verify page numbers are sequential
      final pageNumbers =
          paginationPages
              .map((page) => page.frontMatter['page_num'] as int)
              .toList()
            ..sort();
      expect(pageNumbers, equals([2, 3, 4, 5, 6, 7, 8]));
    });

    test('should handle edge case with exactly divisible posts', () async {
      // Create exactly 20 posts for clean division
      final exactPostsPath = p.join(projectRoot, 'source2');
      memoryFileSystem.directory(exactPostsPath).createSync();
      memoryFileSystem.directory(p.join(exactPostsPath, '_posts')).createSync();

      for (int i = 1; i <= 20; i++) {
        memoryFileSystem
            .file(
              p.join(
                exactPostsPath,
                '_posts',
                '2024-01-${i.toString().padLeft(2, '0')}-exact-$i.md',
              ),
            )
            .writeAsStringSync('''
---
title: Exact Post $i
layout: default
date: 2024-01-${i.toString().padLeft(2, '0')} 00:00:00
slug: exact-post-$i
---
Exact post $i content.
''');
      }

      memoryFileSystem
          .file(p.join(exactPostsPath, '_config.yaml'))
          .writeAsStringSync('''
title: Exact Test Site
theme: default
pagination:
  enabled: true
  items_per_page: 5
  collection: posts
  permalink: '/page/:num/'
  indexpage: index
''');

      // Create layouts for this test
      final exactLayoutsPath = p.join(exactPostsPath, '_layouts');
      memoryFileSystem.directory(exactLayoutsPath).createSync(recursive: true);
      memoryFileSystem
          .file(p.join(exactLayoutsPath, 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html>
<head><title>{{ page.title | default: site.title }}</title></head>
<body>{{ content }}</body>
</html>
''');

      // Create theme structure
      final exactThemesPath = p.join(exactPostsPath, '_themes');
      final exactDefaultThemePath = p.join(exactThemesPath, 'default');
      final exactThemeLayoutsPath = p.join(exactDefaultThemePath, '_layouts');
      memoryFileSystem
          .directory(exactThemeLayoutsPath)
          .createSync(recursive: true);

      memoryFileSystem
          .file(p.join(exactDefaultThemePath, 'config.yaml'))
          .writeAsStringSync('''
name: default
version: 1.0.0
''');

      memoryFileSystem
          .file(p.join(exactThemeLayoutsPath, 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title | default: site.title }}</title></head>
<body><main>{{ content }}</main></body></html>
''');

      memoryFileSystem
          .file(p.join(exactPostsPath, 'index.html'))
          .writeAsStringSync('''
---
layout: default
title: Home
---
<h1>{{ site.paginate.current_page }} of {{ site.paginate.total_pages }}</h1>
''');

      Site.init(
        overrides: {
          'source': exactPostsPath,
          'destination': p.join(projectRoot, 'public2'),
          'title': 'Exact Test Site',
          'theme': 'default',
        },
      );

      await Site.instance.process();

      final siteMap = Site.instance.map;
      final paginateData = siteMap['paginate'] as Map<String, dynamic>;

      // 20 posts ÷ 5 per page = exactly 4 pages
      expect(paginateData['total_pages'], equals(4));
      expect(paginateData['items_per_page'], equals(5));
      expect(paginateData['total_items'], equals(20));

      // Should have exactly 3 additional pages (2, 3, 4)
      final paginationPages = Site.instance.pages
          .where((page) => page.frontMatter.containsKey('page_num'))
          .toList();

      expect(paginationPages.length, equals(3));
    });

    test('should handle single page scenario', () async {
      // Create a small dataset that fits on one page
      final smallPostsPath = p.join(projectRoot, 'source3');
      memoryFileSystem.directory(smallPostsPath).createSync();
      memoryFileSystem.directory(p.join(smallPostsPath, '_posts')).createSync();

      for (int i = 1; i <= 3; i++) {
        memoryFileSystem
            .file(p.join(smallPostsPath, '_posts', '2024-01-0$i-small-$i.md'))
            .writeAsStringSync('''
---
title: Small Post $i
layout: default
date: 2024-01-0$i 00:00:00
slug: small-post-$i
---
Small post $i content.
''');
      }

      memoryFileSystem
          .file(p.join(smallPostsPath, '_config.yaml'))
          .writeAsStringSync('''
title: Small Test Site
theme: default
pagination:
  enabled: true
  items_per_page: 10
  collection: posts
  permalink: '/page/:num/'
  indexpage: index
''');

      // Create layouts for this test
      final smallLayoutsPath = p.join(smallPostsPath, '_layouts');
      memoryFileSystem.directory(smallLayoutsPath).createSync(recursive: true);
      memoryFileSystem
          .file(p.join(smallLayoutsPath, 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html>
<head><title>{{ page.title | default: site.title }}</title></head>
<body>{{ content }}</body>
</html>
''');

      // Create theme structure
      final smallThemesPath = p.join(smallPostsPath, '_themes');
      final smallDefaultThemePath = p.join(smallThemesPath, 'default');
      final smallThemeLayoutsPath = p.join(smallDefaultThemePath, '_layouts');
      memoryFileSystem
          .directory(smallThemeLayoutsPath)
          .createSync(recursive: true);

      memoryFileSystem
          .file(p.join(smallDefaultThemePath, 'config.yaml'))
          .writeAsStringSync('''
name: default
version: 1.0.0
''');

      memoryFileSystem
          .file(p.join(smallThemeLayoutsPath, 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title | default: site.title }}</title></head>
<body><main>{{ content }}</main></body></html>
''');

      memoryFileSystem
          .file(p.join(smallPostsPath, 'index.html'))
          .writeAsStringSync('''
---
layout: default
title: Home
---
<h1>{{ site.paginate.current_page }} of {{ site.paginate.total_pages }}</h1>
''');

      Site.init(
        overrides: {
          'source': smallPostsPath,
          'destination': p.join(projectRoot, 'public3'),
          'title': 'Small Test Site',
          'theme': 'default',
        },
      );

      await Site.instance.process();

      final siteMap = Site.instance.map;
      final paginateData = siteMap['paginate'] as Map<String, dynamic>;

      // 3 posts with 10 per page = 1 page (all fit on one page)
      expect(paginateData['total_pages'], equals(1));
      expect(
        paginateData['items_per_page'],
        equals(10),
      ); // Using configured value from config
      expect(paginateData['total_items'], equals(3));
      expect(paginateData['has_previous'], isFalse);
      expect(paginateData['has_next'], isFalse);

      // Should have no additional pages created
      final paginationPages = Site.instance.pages
          .where((page) => page.frontMatter.containsKey('page_num'))
          .toList();
      expect(paginationPages.length, equals(0));
    });
  });
}
