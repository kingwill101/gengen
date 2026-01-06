import 'package:file/memory.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late MemoryFileSystem memoryFileSystem;
  late String projectRoot;

  setUp(() {
    memoryFileSystem = MemoryFileSystem();
    gengen_fs.fs = memoryFileSystem;
    projectRoot = '/test_project';
  });

  tearDown(() {
    Site.resetInstance();
  });

  group('Basic Post Permalink Generation', () {
    test('basic post without categories should use "posts" category', () async {
      // Create site structure
      await memoryFileSystem
          .directory(p.join(projectRoot, '_posts'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_layouts'))
          .create(recursive: true);

      // Create site config with default permalink (date format)
      memoryFileSystem
          .file(p.join(projectRoot, '_config.yaml'))
          .writeAsStringSync('''
title: Test Site
description: Test site for basic post
''');

      // Create basic post with no categories or tags
      memoryFileSystem
          .file(p.join(projectRoot, '_posts', '2024-01-15-basic-post.md'))
          .writeAsStringSync('''
---
title: Basic Post
date: 2024-01-15
---

This is a basic post with no categories.
''');

      // Create basic layout
      memoryFileSystem
          .file(p.join(projectRoot, '_layouts', 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

      // Initialize site
      Site.init(
        overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        },
      );

      await Site.instance.read();

      final posts = Site.instance.posts;
      expect(posts.length, equals(1));

      final basicPost = posts.first;
      expect(basicPost.config['title'], equals('Basic Post'));

      // Should use default "posts" category since no categories specified
      // Default permalink is "date": :categories/:year/:month/:day/:title:output_ext
      expect(basicPost.link(), equals('posts/2024/01/15/basic-post.html'));
    });

    test('post with categories should use first category', () async {
      // Create site structure
      await memoryFileSystem
          .directory(p.join(projectRoot, '_posts'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_layouts'))
          .create(recursive: true);

      // Create site config
      memoryFileSystem
          .file(p.join(projectRoot, '_config.yaml'))
          .writeAsStringSync('''
title: Test Site
description: Test site for category post
''');

      // Create post with multiple categories
      memoryFileSystem
          .file(p.join(projectRoot, '_posts', '2024-02-20-tech-post.md'))
          .writeAsStringSync('''
---
title: Tech Post
date: 2024-02-20
categories: [technology, programming, web]
---

This post has multiple categories.
''');

      // Create basic layout
      memoryFileSystem
          .file(p.join(projectRoot, '_layouts', 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

      // Initialize site
      Site.init(
        overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        },
      );

      await Site.instance.read();

      final posts = Site.instance.posts;
      expect(posts.length, equals(1));

      final techPost = posts.first;
      expect(techPost.config['title'], equals('Tech Post'));
      expect(
        techPost.config['categories'],
        equals(['technology', 'programming', 'web']),
      );

      // Should use first category "technology"
      expect(techPost.link(), equals('technology/2024/02/20/tech-post.html'));
    });

    test(
      'post with tags but no categories should use "posts" category',
      () async {
        // Create site structure
        await memoryFileSystem
            .directory(p.join(projectRoot, '_posts'))
            .create(recursive: true);
        await memoryFileSystem
            .directory(p.join(projectRoot, '_layouts'))
            .create(recursive: true);

        // Create site config
        memoryFileSystem
            .file(p.join(projectRoot, '_config.yaml'))
            .writeAsStringSync('''
title: Test Site
description: Test site for tagged post
''');

        // Create post with tags but no categories
        memoryFileSystem
            .file(p.join(projectRoot, '_posts', '2024-03-10-tagged-post.md'))
            .writeAsStringSync('''
---
title: Tagged Post
date: 2024-03-10
tags: [dart, testing, development]
---

This post has tags but no categories.
''');

        // Create basic layout
        memoryFileSystem
            .file(p.join(projectRoot, '_layouts', 'default.html'))
            .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

        // Initialize site
        Site.init(
          overrides: {
            'source': projectRoot,
            'destination': p.join(projectRoot, 'public'),
          },
        );

        await Site.instance.read();

        final posts = Site.instance.posts;
        expect(posts.length, equals(1));

        final taggedPost = posts.first;
        expect(taggedPost.config['title'], equals('Tagged Post'));
        expect(
          taggedPost.config['tags'],
          equals(['dart', 'testing', 'development']),
        );
        expect(taggedPost.config['categories'], anyOf(isNull, isEmpty));

        // Should use default "posts" category since no categories specified
        // Tags should NOT be used as categories
        expect(taggedPost.link(), equals('posts/2024/03/10/tagged-post.html'));
      },
    );
  });

  group('Built-in Permalink Structures', () {
    test(
      'date format: :categories/:year/:month/:day/:title:output_ext',
      () async {
        // Create site structure
        await memoryFileSystem
            .directory(p.join(projectRoot, '_posts'))
            .create(recursive: true);
        await memoryFileSystem
            .directory(p.join(projectRoot, '_layouts'))
            .create(recursive: true);

        // Create site config with explicit date permalink
        memoryFileSystem
            .file(p.join(projectRoot, '_config.yaml'))
            .writeAsStringSync('''
title: Test Site
description: Test site for date permalink
permalink: date
''');

        // Create post with category
        memoryFileSystem
            .file(
              p.join(projectRoot, '_posts', '2024-05-25-date-format-test.md'),
            )
            .writeAsStringSync('''
---
title: Date Format Test
date: 2024-05-25
categories: [tutorials]
---

Testing the date permalink format.
''');

        // Create basic layout
        memoryFileSystem
            .file(p.join(projectRoot, '_layouts', 'default.html'))
            .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

        // Initialize site
        Site.init(
          overrides: {
            'source': projectRoot,
            'destination': p.join(projectRoot, 'public'),
          },
        );

        await Site.instance.read();

        final posts = Site.instance.posts;
        expect(posts.length, equals(1));

        final post = posts.first;
        expect(post.config['title'], equals('Date Format Test'));

        // Date format: :categories/:year/:month/:day/:title:output_ext
        expect(
          post.link(),
          equals('tutorials/2024/05/25/date-format-test.html'),
        );
      },
    );

    test('pretty format: :categories/:year/:month/:day/:title/', () async {
      // Create site structure
      await memoryFileSystem
          .directory(p.join(projectRoot, '_posts'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_layouts'))
          .create(recursive: true);

      // Create site config with pretty permalinks
      memoryFileSystem
          .file(p.join(projectRoot, '_config.yaml'))
          .writeAsStringSync('''
title: Test Site
description: Test site for pretty permalinks
permalink: pretty
''');

      // Create post
      memoryFileSystem
          .file(p.join(projectRoot, '_posts', '2024-04-01-pretty-post.md'))
          .writeAsStringSync('''
---
title: Pretty Post
date: 2024-04-01
categories: [blog]
---

This post uses pretty permalinks.
''');

      // Create basic layout
      memoryFileSystem
          .file(p.join(projectRoot, '_layouts', 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

      // Initialize site
      Site.init(
        overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        },
      );

      await Site.instance.read();

      final posts = Site.instance.posts;
      expect(posts.length, equals(1));

      final prettyPost = posts.first;
      expect(prettyPost.config['title'], equals('Pretty Post'));

      // Pretty format is :categories/:year/:month/:day/:title/
      // Should add index.html for directory structure
      expect(
        prettyPost.link(),
        equals('blog/2024/04/01/pretty-post/index.html'),
      );
    });

    test(
      'ordinal format: :categories/:year/:y_day/:title:output_ext',
      () async {
        // Create site structure
        await memoryFileSystem
            .directory(p.join(projectRoot, '_posts'))
            .create(recursive: true);
        await memoryFileSystem
            .directory(p.join(projectRoot, '_layouts'))
            .create(recursive: true);

        // Create site config with ordinal permalink
        memoryFileSystem
            .file(p.join(projectRoot, '_config.yaml'))
            .writeAsStringSync('''
title: Test Site
description: Test site for ordinal permalink
permalink: ordinal
''');

        // Create post on March 1st (60th day of 2024, leap year)
        memoryFileSystem
            .file(p.join(projectRoot, '_posts', '2024-03-01-ordinal-test.md'))
            .writeAsStringSync('''
---
title: Ordinal Test
date: 2024-03-01
categories: [science]
---

Testing the ordinal permalink format.
''');

        // Create basic layout
        memoryFileSystem
            .file(p.join(projectRoot, '_layouts', 'default.html'))
            .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

        // Initialize site
        Site.init(
          overrides: {
            'source': projectRoot,
            'destination': p.join(projectRoot, 'public'),
          },
        );

        await Site.instance.read();

        final posts = Site.instance.posts;
        expect(posts.length, equals(1));

        final post = posts.first;
        expect(post.config['title'], equals('Ordinal Test'));

        // Ordinal format: :categories/:year/:y_day/:title:output_ext
        // March 1st is the 61st day of 2024 (leap year), formatted as 061
        expect(post.link(), equals('science/2024/061/ordinal-test.html'));
      },
    );

    test(
      'weekdate format: :categories/:year/W:week/:short_day/:title:output_ext',
      () async {
        // Create site structure
        await memoryFileSystem
            .directory(p.join(projectRoot, '_posts'))
            .create(recursive: true);
        await memoryFileSystem
            .directory(p.join(projectRoot, '_layouts'))
            .create(recursive: true);

        // Create site config with weekdate permalink
        memoryFileSystem
            .file(p.join(projectRoot, '_config.yaml'))
            .writeAsStringSync('''
title: Test Site
description: Test site for weekdate permalink
permalink: weekdate
''');

        // Create post on January 8th, 2024 (Monday, week 2)
        memoryFileSystem
            .file(p.join(projectRoot, '_posts', '2024-01-08-weekdate-test.md'))
            .writeAsStringSync('''
---
title: Weekdate Test
date: 2024-01-08
categories: [weekly]
---

Testing the weekdate permalink format.
''');

        // Create basic layout
        memoryFileSystem
            .file(p.join(projectRoot, '_layouts', 'default.html'))
            .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

        // Initialize site
        Site.init(
          overrides: {
            'source': projectRoot,
            'destination': p.join(projectRoot, 'public'),
          },
        );

        await Site.instance.read();

        final posts = Site.instance.posts;
        expect(posts.length, equals(1));

        final post = posts.first;
        expect(post.config['title'], equals('Weekdate Test'));

        // Weekdate format: :categories/:year/W:week/:short_day/:title:output_ext
        // January 8th, 2024 is Monday (1) in week 2
        expect(post.link(), equals('weekly/2024/W02/Mon/weekdate-test.html'));
      },
    );

    test('none format: :categories/:title:output_ext', () async {
      // Create site structure
      await memoryFileSystem
          .directory(p.join(projectRoot, '_posts'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_layouts'))
          .create(recursive: true);

      // Create site config with none permalink
      memoryFileSystem
          .file(p.join(projectRoot, '_config.yaml'))
          .writeAsStringSync('''
title: Test Site
description: Test site for none permalink
permalink: none
''');

      // Create post
      memoryFileSystem
          .file(p.join(projectRoot, '_posts', '2024-07-15-none-format-test.md'))
          .writeAsStringSync('''
---
title: None Format Test
date: 2024-07-15
categories: [simple]
---

Testing the none permalink format (no date components).
''');

      // Create basic layout
      memoryFileSystem
          .file(p.join(projectRoot, '_layouts', 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

      // Initialize site
      Site.init(
        overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        },
      );

      await Site.instance.read();

      final posts = Site.instance.posts;
      expect(posts.length, equals(1));

      final post = posts.first;
      expect(post.config['title'], equals('None Format Test'));

      // None format: :categories/:title:output_ext (no date)
      expect(post.link(), equals('simple/none-format-test.html'));
    });

    test('post format: :path/:basename:output_ext', () async {
      // Create site structure
      await memoryFileSystem
          .directory(p.join(projectRoot, '_posts'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_layouts'))
          .create(recursive: true);

      // Create site config with post permalink
      memoryFileSystem
          .file(p.join(projectRoot, '_config.yaml'))
          .writeAsStringSync('''
title: Test Site
description: Test site for post permalink
permalink: post
''');

      // Create post
      memoryFileSystem
          .file(p.join(projectRoot, '_posts', '2024-08-20-post-format-test.md'))
          .writeAsStringSync('''
---
title: Post Format Test
date: 2024-08-20
categories: [meta]
---

Testing the post permalink format (preserves original path).
''');

      // Create basic layout
      memoryFileSystem
          .file(p.join(projectRoot, '_layouts', 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

      // Initialize site
      Site.init(
        overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        },
      );

      await Site.instance.read();

      final posts = Site.instance.posts;
      expect(posts.length, equals(1));

      final post = posts.first;
      expect(post.config['title'], equals('Post Format Test'));

      // Post format: :path/:basename:output_ext (preserves original structure)
      // The current implementation preserves _posts in the path for 'post' format
      expect(post.link(), equals('_posts/2024-08-20-post-format-test.html'));
    });
  });

  group('Custom Permalink Patterns', () {
    test('custom pattern with year and title only', () async {
      // Create site structure
      await memoryFileSystem
          .directory(p.join(projectRoot, '_posts'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_layouts'))
          .create(recursive: true);

      // Create site config with custom permalink pattern
      memoryFileSystem
          .file(p.join(projectRoot, '_config.yaml'))
          .writeAsStringSync('''
title: Test Site
description: Test site for custom permalinks
permalink: /blog/:year/:title/
''');

      // Create post
      memoryFileSystem
          .file(p.join(projectRoot, '_posts', '2024-05-15-custom-post.md'))
          .writeAsStringSync('''
---
title: Custom Post
date: 2024-05-15
---

This post uses custom permalink pattern.
''');

      // Create basic layout
      memoryFileSystem
          .file(p.join(projectRoot, '_layouts', 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

      // Initialize site
      Site.init(
        overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        },
      );

      await Site.instance.read();

      final posts = Site.instance.posts;
      expect(posts.length, equals(1));

      final customPost = posts.first;
      expect(customPost.config['title'], equals('Custom Post'));

      // Custom pattern /blog/:year/:title/ should add index.html
      expect(customPost.link(), equals('blog/2024/custom-post/index.html'));
    });

    test('custom pattern with month names and categories', () async {
      // Create site structure
      await memoryFileSystem
          .directory(p.join(projectRoot, '_posts'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_layouts'))
          .create(recursive: true);

      // Create site config with custom permalink using month names
      memoryFileSystem
          .file(p.join(projectRoot, '_config.yaml'))
          .writeAsStringSync('''
title: Test Site
description: Test site for month name permalinks
permalink: /:categories/:year/:long_month/:title.html
''');

      // Create post in September
      memoryFileSystem
          .file(p.join(projectRoot, '_posts', '2024-09-12-month-name-test.md'))
          .writeAsStringSync('''
---
title: Month Name Test
date: 2024-09-12
categories: [archive]
---

Testing custom permalink with full month names.
''');

      // Create basic layout
      memoryFileSystem
          .file(p.join(projectRoot, '_layouts', 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

      // Initialize site
      Site.init(
        overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        },
      );

      await Site.instance.read();

      final posts = Site.instance.posts;
      expect(posts.length, equals(1));

      final post = posts.first;
      expect(post.config['title'], equals('Month Name Test'));

      // Custom pattern with :long_month should use full month name
      expect(
        post.link(),
        equals('archive/2024/September/month-name-test.html'),
      );
    });

    test('custom pattern with short month and day names', () async {
      // Create site structure
      await memoryFileSystem
          .directory(p.join(projectRoot, '_posts'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_layouts'))
          .create(recursive: true);

      // Create site config with short month/day names
      memoryFileSystem
          .file(p.join(projectRoot, '_config.yaml'))
          .writeAsStringSync('''
title: Test Site
description: Test site for short date permalinks
permalink: /:short_month-:short_day/:title/
''');

      // Create post on Friday, June 14th
      memoryFileSystem
          .file(p.join(projectRoot, '_posts', '2024-06-14-short-date-test.md'))
          .writeAsStringSync('''
---
title: Short Date Test
date: 2024-06-14
---

Testing custom permalink with short month and day names.
''');

      // Create basic layout
      memoryFileSystem
          .file(p.join(projectRoot, '_layouts', 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

      // Initialize site
      Site.init(
        overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        },
      );

      await Site.instance.read();

      final posts = Site.instance.posts;
      expect(posts.length, equals(1));

      final post = posts.first;
      expect(post.config['title'], equals('Short Date Test'));

      // Custom pattern with :short_month and :short_day
      // June 14, 2024 is Friday
      expect(post.link(), equals('Jun-Fri/short-date-test/index.html'));
    });

    test('custom pattern with numeric month and day', () async {
      // Create site structure
      await memoryFileSystem
          .directory(p.join(projectRoot, '_posts'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_layouts'))
          .create(recursive: true);

      // Create site config with numeric dates
      memoryFileSystem
          .file(p.join(projectRoot, '_config.yaml'))
          .writeAsStringSync('''
title: Test Site
description: Test site for numeric date permalinks
permalink: /:year/:i_month/:i_day/:title.html
''');

      // Create post on March 5th
      memoryFileSystem
          .file(
            p.join(projectRoot, '_posts', '2024-03-05-numeric-date-test.md'),
          )
          .writeAsStringSync('''
---
title: Numeric Date Test
date: 2024-03-05
---

Testing custom permalink with numeric month and day (no zero padding).
''');

      // Create basic layout
      memoryFileSystem
          .file(p.join(projectRoot, '_layouts', 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

      // Initialize site
      Site.init(
        overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        },
      );

      await Site.instance.read();

      final posts = Site.instance.posts;
      expect(posts.length, equals(1));

      final post = posts.first;
      expect(post.config['title'], equals('Numeric Date Test'));

      // Custom pattern with :i_month and :i_day (no zero padding)
      expect(post.link(), equals('2024/3/5/numeric-date-test.html'));
    });

    test('literal custom path without tokens', () async {
      // Create site structure
      await memoryFileSystem
          .directory(p.join(projectRoot, '_posts'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_layouts'))
          .create(recursive: true);

      // Create site config with default permalink
      memoryFileSystem
          .file(p.join(projectRoot, '_config.yaml'))
          .writeAsStringSync('''
title: Test Site
description: Test site for literal path
permalink: date
''');

      // Create post with literal custom path
      memoryFileSystem
          .file(
            p.join(projectRoot, '_posts', '2024-10-01-literal-path-test.md'),
          )
          .writeAsStringSync('''
---
title: Literal Path Test
date: 2024-10-01
permalink: /special/fixed/path/
---

This post uses a literal custom path that ignores the site permalink pattern.
''');

      // Create basic layout
      memoryFileSystem
          .file(p.join(projectRoot, '_layouts', 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

      // Initialize site
      Site.init(
        overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        },
      );

      await Site.instance.read();

      final posts = Site.instance.posts;
      expect(posts.length, equals(1));

      final post = posts.first;
      expect(post.config['title'], equals('Literal Path Test'));
      expect(post.config['permalink'], equals('/special/fixed/path/'));

      // Should use the literal path, adding index.html for clean URL
      expect(post.link(), equals('special/fixed/path/index.html'));
    });

    test('post-specific permalink with tokens', () async {
      // Create site structure
      await memoryFileSystem
          .directory(p.join(projectRoot, '_posts'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_layouts'))
          .create(recursive: true);

      // Create site config with default permalink
      memoryFileSystem
          .file(p.join(projectRoot, '_config.yaml'))
          .writeAsStringSync('''
title: Test Site
description: Test site for post-specific permalink with tokens
permalink: date
''');

      // Create post with custom permalink using tokens
      memoryFileSystem
          .file(
            p.join(projectRoot, '_posts', '2024-11-20-token-override-test.md'),
          )
          .writeAsStringSync('''
---
title: Token Override Test
date: 2024-11-20
categories: [special]
permalink: /custom/:categories/:short_year/:title/
---

This post overrides the site permalink with its own token-based pattern.
''');

      // Create basic layout
      memoryFileSystem
          .file(p.join(projectRoot, '_layouts', 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

      // Initialize site
      Site.init(
        overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        },
      );

      await Site.instance.read();

      final posts = Site.instance.posts;
      expect(posts.length, equals(1));

      final post = posts.first;
      expect(post.config['title'], equals('Token Override Test'));
      expect(
        post.config['permalink'],
        equals('/custom/:categories/:short_year/:title/'),
      );

      // Should process the tokens in the custom permalink
      // :short_year for 2024 is "24"
      expect(
        post.link(),
        equals('custom/special/24/token-override-test/index.html'),
      );
    });
  });

  group('Edge Cases and Special Characters', () {
    test('post with special characters in title', () async {
      // Create site structure
      await memoryFileSystem
          .directory(p.join(projectRoot, '_posts'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_layouts'))
          .create(recursive: true);

      // Create site config
      memoryFileSystem
          .file(p.join(projectRoot, '_config.yaml'))
          .writeAsStringSync('''
title: Test Site
description: Test site for special characters
''');

      // Create post with special characters in title
      memoryFileSystem
          .file(p.join(projectRoot, '_posts', '2024-12-01-special-chars.md'))
          .writeAsStringSync('''
---
title: "Special & Characters! @#\$%^&*()_+ Post"
date: 2024-12-01
---

Testing how special characters are handled in permalinks.
''');

      // Create basic layout
      memoryFileSystem
          .file(p.join(projectRoot, '_layouts', 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

      // Initialize site
      Site.init(
        overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        },
      );

      await Site.instance.read();

      final posts = Site.instance.posts;
      expect(posts.length, equals(1));

      final post = posts.first;
      expect(
        post.config['title'],
        equals('Special & Characters! @#\$%^&*()_+ Post'),
      );

      // Special characters should be normalized/sanitized in the URL
      expect(post.link(), equals('posts/2024/12/01/special-chars.html'));
    });

    test('post with empty categories should default to "posts"', () async {
      // Create site structure
      await memoryFileSystem
          .directory(p.join(projectRoot, '_posts'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_layouts'))
          .create(recursive: true);

      // Create site config
      memoryFileSystem
          .file(p.join(projectRoot, '_config.yaml'))
          .writeAsStringSync('''
title: Test Site
description: Test site for empty categories
''');

      // Create post with empty categories array
      memoryFileSystem
          .file(p.join(projectRoot, '_posts', '2024-12-15-empty-categories.md'))
          .writeAsStringSync('''
---
title: Empty Categories Test
date: 2024-12-15
categories: []
---

Testing how empty categories are handled.
''');

      // Create basic layout
      memoryFileSystem
          .file(p.join(projectRoot, '_layouts', 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

      // Initialize site
      Site.init(
        overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        },
      );

      await Site.instance.read();

      final posts = Site.instance.posts;
      expect(posts.length, equals(1));

      final post = posts.first;
      expect(post.config['title'], equals('Empty Categories Test'));
      expect(post.config['categories'], equals([]));

      // Empty categories should default to "posts"
      expect(post.link(), equals('posts/2024/12/15/empty-categories.html'));
    });

    test('post with slug override should use slug instead of title', () async {
      // Create site structure
      await memoryFileSystem
          .directory(p.join(projectRoot, '_posts'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_layouts'))
          .create(recursive: true);

      // Create site config
      memoryFileSystem
          .file(p.join(projectRoot, '_config.yaml'))
          .writeAsStringSync('''
title: Test Site
description: Test site for slug override
''');

      // Create post with custom slug
      memoryFileSystem
          .file(p.join(projectRoot, '_posts', '2024-12-25-slug-test.md'))
          .writeAsStringSync('''
---
title: "This is a Very Long Title That Should Be Overridden"
date: 2024-12-25
slug: short-slug
---

Testing how slug overrides the title in permalinks.
''');

      // Create basic layout
      memoryFileSystem
          .file(p.join(projectRoot, '_layouts', 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

      // Initialize site
      Site.init(
        overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        },
      );

      await Site.instance.read();

      final posts = Site.instance.posts;
      expect(posts.length, equals(1));

      final post = posts.first;
      expect(
        post.config['title'],
        equals('This is a Very Long Title That Should Be Overridden'),
      );
      expect(post.config['slug'], equals('short-slug'));

      // Should use slug instead of normalized title
      expect(post.link(), equals('posts/2024/12/25/short-slug.html'));
    });
  });

  group('Post Sorting and Metadata', () {
    test('posts should be sorted by date (newest first)', () async {
      // Create site structure
      await memoryFileSystem
          .directory(p.join(projectRoot, '_posts'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_layouts'))
          .create(recursive: true);

      // Create site config
      memoryFileSystem
          .file(p.join(projectRoot, '_config.yaml'))
          .writeAsStringSync('''
title: Test Site
description: Test site for post sorting
''');

      // Create multiple posts with different dates
      memoryFileSystem
          .file(p.join(projectRoot, '_posts', '2024-01-01-old-post.md'))
          .writeAsStringSync('''
---
title: Old Post
date: 2024-01-01
---

This is an old post.
''');

      memoryFileSystem
          .file(p.join(projectRoot, '_posts', '2024-12-31-new-post.md'))
          .writeAsStringSync('''
---
title: New Post
date: 2024-12-31
---

This is a new post.
''');

      memoryFileSystem
          .file(p.join(projectRoot, '_posts', '2024-06-15-middle-post.md'))
          .writeAsStringSync('''
---
title: Middle Post
date: 2024-06-15
---

This is a middle post.
''');

      // Create layout
      memoryFileSystem
          .file(p.join(projectRoot, '_layouts', 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

      // Initialize site
      Site.init(
        overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        },
      );

      await Site.instance.read();

      final posts = Site.instance.posts;
      expect(posts.length, equals(3));

      // Posts should be sorted by date, newest first
      expect(posts[0].config['title'], equals('New Post'));
      expect(posts[1].config['title'], equals('Middle Post'));
      expect(posts[2].config['title'], equals('Old Post'));

      // Verify dates are properly sorted
      for (int i = 0; i < posts.length - 1; i++) {
        expect(
          posts[i].date.isAfter(posts[i + 1].date) ||
              posts[i].date.isAtSameMomentAs(posts[i + 1].date),
          isTrue,
          reason: 'Posts should be sorted by date (newest first)',
        );
      }
    });

    test('post should extract metadata correctly', () async {
      // Create site structure
      await memoryFileSystem
          .directory(p.join(projectRoot, '_posts'))
          .create(recursive: true);
      await memoryFileSystem
          .directory(p.join(projectRoot, '_layouts'))
          .create(recursive: true);

      // Create site config
      memoryFileSystem
          .file(p.join(projectRoot, '_config.yaml'))
          .writeAsStringSync('''
title: Test Site
description: Test site for metadata extraction
''');

      // Create post with rich metadata
      memoryFileSystem
          .file(p.join(projectRoot, '_posts', '2024-10-01-metadata-test.md'))
          .writeAsStringSync('''
---
title: Metadata Test Post
date: 2024-10-01
author: John Doe
categories: [tech, programming]
tags: [dart, testing, metadata]
excerpt: This is a test excerpt for the post.
featured: true
reading_time: 5
custom_field: custom_value
---

This post has extensive metadata for testing.
''');

      // Create layout
      memoryFileSystem
          .file(p.join(projectRoot, '_layouts', 'default.html'))
          .writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

      // Initialize site
      Site.init(
        overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        },
      );

      await Site.instance.read();

      final posts = Site.instance.posts;
      expect(posts.length, equals(1));

      final metadataPost = posts.first;

      // Test all metadata fields
      expect(metadataPost.config['title'], equals('Metadata Test Post'));
      expect(metadataPost.config['author'], equals('John Doe'));
      expect(
        metadataPost.config['categories'],
        equals(['tech', 'programming']),
      );
      expect(
        metadataPost.config['tags'],
        equals(['dart', 'testing', 'metadata']),
      );
      expect(
        metadataPost.config['excerpt'],
        equals('This is a test excerpt for the post.'),
      );
      expect(metadataPost.config['featured'], equals(true));
      expect(metadataPost.config['reading_time'], equals(5));
      expect(metadataPost.config['custom_field'], equals('custom_value'));

      // Test date parsing
      expect(metadataPost.date.year, equals(2024));
      expect(metadataPost.date.month, equals(10));
      expect(metadataPost.date.day, equals(1));
    });
  });
}
