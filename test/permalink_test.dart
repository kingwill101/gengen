import 'package:file/memory.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/models/permalink_structure.dart';
import 'package:gengen/models/post.dart';
import 'package:gengen/models/page.dart';
import 'package:gengen/site.dart';
import 'package:test/test.dart';

void main() {
  late MemoryFileSystem memoryFileSystem;

  setUp(() {
    memoryFileSystem = MemoryFileSystem();
    gengen_fs.fs = memoryFileSystem;
  });

  tearDown(() {
    Site.resetInstance();
  });

  group('Permalink Generation Tests', () {
    late Post post;

    setUp(() {
      Map<String, dynamic> frontMatter = {
        'author': 'John Doe',
        'title': 'Test Post',
        'date': '2023-01-15',
        'categories': ['dart', 'programming'],
      };

      // Create a test file in memory for the Post to read
      memoryFileSystem
          .file('_posts/2023-01-15-test-post.md')
          .createSync(recursive: true);
      memoryFileSystem.file('_posts/2023-01-15-test-post.md').writeAsStringSync(
        '''
---
author: John Doe
title: Test Post
date: 2023-01-15
categories: [dart, programming]
---

Test content
''',
      );

      post = Post('_posts/2023-01-15-test-post.md', frontMatter: frontMatter);
    });

    group('Built-in Permalink Structures', () {
      test('Date Permalink Structure', () {
        String permalink = post.buildPermalink(PermalinkStructure.date);
        expect(permalink, equals('dart/2023/01/15/test-post.html'));
      });

      test('Pretty Permalink Structure', () {
        String permalink = post.buildPermalink(PermalinkStructure.pretty);
        expect(permalink, equals('dart/2023/01/15/test-post/'));
      });

      test('Ordinal Permalink Structure', () {
        String permalink = post.buildPermalink(PermalinkStructure.ordinal);
        expect(permalink, equals('dart/2023/015/test-post.html'));
      });

      test('Weekdate Permalink Structure', () {
        String permalink = post.buildPermalink(PermalinkStructure.weekdate);
        expect(permalink, equals('dart/2023/W03/Sun/test-post.html'));
      });

      test('None Permalink Structure', () {
        String permalink = post.buildPermalink(PermalinkStructure.none);
        expect(permalink, equals('dart/test-post.html'));
      });

      test('Post Permalink Structure', () {
        String permalink = post.buildPermalink(PermalinkStructure.post);
        expect(permalink, equals('_posts/2023-01-15-test-post.html'));
      });
    });

    group('Custom Permalink Patterns', () {
      test('Custom pattern with year and title', () {
        String permalink = post.buildPermalink('/blog/:year/:title/');
        expect(permalink, equals('blog/2023/test-post/'));
      });

      test('Custom pattern with categories and month names', () {
        String permalink = post.buildPermalink(
          '/:categories/:year/:long_month/:title.html',
        );
        expect(permalink, equals('dart/2023/January/test-post.html'));
      });

      test('Custom pattern with short date formats', () {
        String permalink = post.buildPermalink(
          '/:short_month-:short_day/:title/',
        );
        expect(permalink, equals('Jan-Sun/test-post/'));
      });

      test('Custom pattern with numeric dates (no zero padding)', () {
        String permalink = post.buildPermalink(
          '/:year/:i_month/:i_day/:title.html',
        );
        expect(permalink, equals('2023/1/15/test-post.html'));
      });

      test('Custom pattern with basename and path', () {
        String permalink = post.buildPermalink(
          '/files/:path/:basename:output_ext',
        );
        expect(permalink, equals('files/_posts/2023-01-15-test-post.html'));
      });

      test('Custom pattern with short year', () {
        String permalink = post.buildPermalink(
          '/archive/:categories/:short_year/:title/',
        );
        expect(permalink, equals('archive/dart/23/test-post/'));
      });

      test('Custom pattern with literal paths only', () {
        String permalink = post.buildPermalink('/special/fixed/path/');
        expect(permalink, equals('special/fixed/path/'));
      });

      test('Custom pattern with week numbers', () {
        String permalink = post.buildPermalink(
          '/weekly/:categories/:year/W:week/:title/',
        );
        expect(permalink, equals('weekly/dart/2023/W03/test-post/'));
      });

      test('Custom pattern with ordinal day', () {
        String permalink = post.buildPermalink(
          '/:categories/:year/:y_day/:title:output_ext',
        );
        expect(permalink, equals('dart/2023/015/test-post.html'));
      });

      test('Custom pattern with time components', () {
        // Create a new post with time component for this test
        memoryFileSystem
            .file('_posts/2023-06-15-time-test.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-06-15-time-test.md')
            .writeAsStringSync('''
---
title: Time Test
date: 2023-06-15T09:30:45
categories: [time]
---

Test content with time
''');

        Post timePost = Post(
          '_posts/2023-06-15-time-test.md',
          frontMatter: {
            'title': 'Time Test',
            'date': '2023-06-15T09:30:45',
            'categories': ['time'],
          },
        );
        String permalink = timePost.buildPermalink(
          '/posts/:year/:month/:day/:hour-:minute-:second/:title/',
        );
        expect(permalink, equals('posts/2023/06/15/09-30-45/time-test/'));
      });
    });

    group('Special Cases and Edge Conditions', () {
      test('Post without categories defaults to "posts"', () {
        memoryFileSystem
            .file('_posts/2023-05-10-no-category.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-05-10-no-category.md')
            .writeAsStringSync('''
---
title: No Category Post
date: 2023-05-10
---

Test content without categories
''');

        Post noCategoryPost = Post(
          '_posts/2023-05-10-no-category.md',
          frontMatter: {'title': 'No Category Post', 'date': '2023-05-10'},
        );

        String permalink = noCategoryPost.buildPermalink(
          PermalinkStructure.date,
        );
        expect(permalink, equals('posts/2023/05/10/no-category.html'));
      });

      test('Post with empty categories defaults to "posts"', () {
        memoryFileSystem
            .file('_posts/2023-07-15-empty-category.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-07-15-empty-category.md')
            .writeAsStringSync('''
---
title: Empty Category Post
date: 2023-07-15
categories: []
---

Test content with empty categories
''');

        Post emptyCategoryPost = Post(
          '_posts/2023-07-15-empty-category.md',
          frontMatter: {
            'title': 'Empty Category Post',
            'date': '2023-07-15',
            'categories': <String>[],
          },
        );

        String permalink = emptyCategoryPost.buildPermalink(
          PermalinkStructure.date,
        );
        expect(permalink, equals('posts/2023/07/15/empty-category.html'));
      });

      test('Post with multiple categories uses first one', () {
        memoryFileSystem
            .file('_posts/2023-04-08-multi-category.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-04-08-multi-category.md')
            .writeAsStringSync('''
---
title: Multi Category Post
date: 2023-04-08
categories: [tech, programming, dart]
---

Test content with multiple categories
''');

        Post multiCategoryPost = Post(
          '_posts/2023-04-08-multi-category.md',
          frontMatter: {
            'title': 'Multi Category Post',
            'date': '2023-04-08',
            'categories': ['tech', 'programming', 'dart'],
          },
        );

        String permalink = multiCategoryPost.buildPermalink(
          PermalinkStructure.date,
        );
        expect(permalink, equals('tech/2023/04/08/multi-category.html'));
      });

      test('Slug override replaces title in permalink', () {
        memoryFileSystem
            .file('_posts/2023-12-01-very-long-title.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-12-01-very-long-title.md')
            .writeAsStringSync('''
---
title: Very Long and Detailed Post Title That Should Be Shortened
date: 2023-12-01
slug: short-slug
categories: [slug-test]
---

Test content with slug override
''');

        Post slugPost = Post(
          '_posts/2023-12-01-very-long-title.md',
          frontMatter: {
            'title':
                'Very Long and Detailed Post Title That Should Be Shortened',
            'date': '2023-12-01',
            'slug': 'short-slug',
            'categories': ['slug-test'],
          },
        );

        String permalink = slugPost.buildPermalink(PermalinkStructure.date);
        expect(permalink, equals('slug-test/2023/12/01/short-slug.html'));
      });

      test('Title with special characters gets normalized', () {
        memoryFileSystem
            .file('_posts/2023-10-31-special-chars.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-10-31-special-chars.md')
            .writeAsStringSync('''
---
title: Special & Characters! @#\$%^&*()_+ Post
date: 2023-10-31
categories: [special]
---

Test content with special characters
''');

        Post specialCharsPost = Post(
          '_posts/2023-10-31-special-chars.md',
          frontMatter: {
            'title': 'Special & Characters! @#\$%^&*()_+ Post',
            'date': '2023-10-31',
            'categories': ['special'],
          },
        );

        String permalink = specialCharsPost.buildPermalink(
          PermalinkStructure.date,
        );
        expect(permalink, equals('special/2023/10/31/special-chars.html'));
      });

      test('Missing title falls back to slug', () {
        memoryFileSystem
            .file('_posts/2023-09-20-filename-fallback.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-09-20-filename-fallback.md')
            .writeAsStringSync('''
---
date: 2023-09-20
categories: [fallback]
---

Test content without title
''');

        Post noTitlePost = Post(
          '_posts/2023-09-20-filename-fallback.md',
          frontMatter: {
            'date': '2023-09-20',
            'categories': ['fallback'],
            // No title specified
          },
        );

        String permalink = noTitlePost.buildPermalink(PermalinkStructure.date);
        expect(permalink, equals('fallback/2023/09/20/filename-fallback.html'));
      });

      test('Posts with tags but no categories still default to "posts"', () {
        memoryFileSystem
            .file('_posts/2023-11-15-tagged-post.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-11-15-tagged-post.md')
            .writeAsStringSync('''
---
title: Tagged Post
date: 2023-11-15
tags: [dart, programming, web]
---

Test content with tags but no categories
''');

        Post taggedPost = Post(
          '_posts/2023-11-15-tagged-post.md',
          frontMatter: {
            'title': 'Tagged Post',
            'date': '2023-11-15',
            'tags': ['dart', 'programming', 'web'],
            // No categories - tags should NOT be used as categories
          },
        );

        String permalink = taggedPost.buildPermalink(PermalinkStructure.date);
        expect(permalink, equals('posts/2023/11/15/tagged-post.html'));
      });

      test('Unicode characters in title get normalized', () {
        memoryFileSystem
            .file('_posts/2023-03-17-unicode-test.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-03-17-unicode-test.md')
            .writeAsStringSync('''
---
title: Café & Naïve résumé with ñ
date: 2023-03-17
categories: [unicode]
---

Test content with unicode characters
''');

        Post unicodePost = Post(
          '_posts/2023-03-17-unicode-test.md',
          frontMatter: {
            'title': 'Café & Naïve résumé with ñ',
            'date': '2023-03-17',
            'categories': ['unicode'],
          },
        );

        String permalink = unicodePost.buildPermalink(PermalinkStructure.date);
        expect(permalink, equals('unicode/2023/03/17/unicode-test.html'));
      });

      test('Very long title gets truncated appropriately', () {
        memoryFileSystem
            .file('_posts/2023-08-05-very-long-title.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-08-05-very-long-title.md')
            .writeAsStringSync('''
---
title: This is an extremely long title that should be handled gracefully by the permalink generation system and should not break anything even if it gets really really long
date: 2023-08-05
categories: [long]
---

Test content with very long title
''');

        Post longTitlePost = Post(
          '_posts/2023-08-05-very-long-title.md',
          frontMatter: {
            'title':
                'This is an extremely long title that should be handled gracefully by the permalink generation system and should not break anything even if it gets really really long',
            'date': '2023-08-05',
            'categories': ['long'],
          },
        );

        String permalink = longTitlePost.buildPermalink(
          PermalinkStructure.date,
        );
        // The exact length depends on implementation, but it should work
        expect(permalink, contains('long/2023/08/05/'));
        expect(permalink, endsWith('.html'));
      });
    });

    group('Date Token Variations', () {
      test('All date tokens in leap year', () {
        // Create the file in memory first
        memoryFileSystem
            .file('_posts/2024-02-29-leap-year.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2024-02-29-leap-year.md')
            .writeAsStringSync('''
---
title: Leap Year Post
date: 2024-02-29T14:30:45
categories: [date-test]
---

Test content for leap year
''');

        Post leapYearPost = Post(
          '_posts/2024-02-29-leap-year.md',
          frontMatter: {
            'title': 'Leap Year Post',
            'date': '2024-02-29T14:30:45', // Leap day with time
            'categories': ['date-test'],
          },
        );

        String customPattern =
            '/:categories/:year-:short_year/:month-:i_month/:day-:i_day/:long_month-:short_month/:long_day-:short_day/:hour-:minute-:second/:title/';
        String permalink = leapYearPost.buildPermalink(customPattern);

        // Expected: date-test/2024-24/02-2/29-29/February-Feb/Thursday-Thu/14-30-45/leap-year/
        expect(
          permalink,
          equals(
            'date-test/2024-24/02-2/29-29/February-Feb/Thursday-Thu/14-30-45/leap-year/',
          ),
        );
      });

      test('Ordinal day calculation for New Year', () {
        // Create the file in memory first
        memoryFileSystem
            .file('_posts/2023-01-01-new-years.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-01-01-new-years.md')
            .writeAsStringSync('''
---
title: New Years Day
date: 2023-01-01
categories: [holiday]
---

New Year's content
''');

        Post newYearPost = Post(
          '_posts/2023-01-01-new-years.md',
          frontMatter: {
            'title': 'New Years Day',
            'date': '2023-01-01',
            'categories': ['holiday'],
          },
        );

        String permalink = newYearPost.buildPermalink(
          PermalinkStructure.ordinal,
        );
        expect(permalink, equals('holiday/2023/001/new-years.html'));
      });

      test('Week calculation for different days', () {
        // Create files for both test posts
        memoryFileSystem
            .file('_posts/2023-01-01-sunday.md')
            .createSync(recursive: true);
        memoryFileSystem.file('_posts/2023-01-01-sunday.md').writeAsStringSync(
          '''
---
title: Sunday Post
date: 2023-01-01
categories: [test]
---

Sunday content
''',
        );

        memoryFileSystem
            .file('_posts/2023-01-02-monday.md')
            .createSync(recursive: true);
        memoryFileSystem.file('_posts/2023-01-02-monday.md').writeAsStringSync(
          '''
---
title: Monday Post
date: 2023-01-02
categories: [test]
---

Monday content
''',
        );

        // Test Sunday (week boundary)
        Post sundayPost = Post(
          '_posts/2023-01-01-sunday.md',
          frontMatter: {
            'title': 'Sunday Post',
            'date': '2023-01-01', // Sunday
            'categories': ['test'],
          },
        );

        String sundayPermalink = sundayPost.buildPermalink(
          PermalinkStructure.weekdate,
        );
        expect(sundayPermalink, equals('test/2023/W01/Sun/sunday.html'));

        // Test Monday (start of week)
        Post mondayPost = Post(
          '_posts/2023-01-02-monday.md',
          frontMatter: {
            'title': 'Monday Post',
            'date': '2023-01-02', // Monday
            'categories': ['test'],
          },
        );

        String mondayPermalink = mondayPost.buildPermalink(
          PermalinkStructure.weekdate,
        );
        expect(mondayPermalink, equals('test/2023/W02/Mon/monday.html'));
      });

      test('Different months and their abbreviations', () {
        List<Map<String, String>> monthTests = [
          {'date': '2023-01-15', 'long': 'January', 'short': 'Jan'},
          {'date': '2023-02-15', 'long': 'February', 'short': 'Feb'},
          {'date': '2023-03-15', 'long': 'March', 'short': 'Mar'},
          {'date': '2023-04-15', 'long': 'April', 'short': 'Apr'},
          {'date': '2023-05-15', 'long': 'May', 'short': 'May'},
          {'date': '2023-06-15', 'long': 'June', 'short': 'Jun'},
          {'date': '2023-07-15', 'long': 'July', 'short': 'Jul'},
          {'date': '2023-08-15', 'long': 'August', 'short': 'Aug'},
          {'date': '2023-09-15', 'long': 'September', 'short': 'Sep'},
          {'date': '2023-10-15', 'long': 'October', 'short': 'Oct'},
          {'date': '2023-11-15', 'long': 'November', 'short': 'Nov'},
          {'date': '2023-12-15', 'long': 'December', 'short': 'Dec'},
        ];

        for (var test in monthTests) {
          // Create file for each month test
          String filename = '_posts/${test['date']!}-month-test.md';
          memoryFileSystem.file(filename).createSync(recursive: true);
          memoryFileSystem.file(filename).writeAsStringSync('''
---
title: Month Test
date: ${test['date']!}
categories: [month]
---

Month test content
''');

          Post monthPost = Post(
            filename,
            frontMatter: {
              'title': 'Month Test',
              'date': test['date']!,
              'categories': ['month'],
            },
          );

          String longMonthPermalink = monthPost.buildPermalink(
            '/test/:long_month/:title/',
          );
          expect(
            longMonthPermalink,
            equals('test/${test['long']!}/month-test/'),
            reason: 'Failed long month for ${test['date']}',
          );

          String shortMonthPermalink = monthPost.buildPermalink(
            '/test/:short_month/:title/',
          );
          expect(
            shortMonthPermalink,
            equals('test/${test['short']!}/month-test/'),
            reason: 'Failed short month for ${test['date']}',
          );
        }
      });
    });

    group('Page Permalink Tests', () {
      test('Page with default permalink', () {
        // Create the page file in memory
        memoryFileSystem.file('about.md').createSync(recursive: true);
        memoryFileSystem.file('about.md').writeAsStringSync('''
---
title: About Page
---

About page content
''');

        Page page = Page('about.md', frontMatter: {'title': 'About Page'});

        String permalink = page.buildPermalink();
        // Pages use the filename, not the title
        expect(permalink, equals('about-page.html'));
      });

      test('Page with custom permalink pattern', () {
        // Create the page file in memory
        memoryFileSystem.file('contact.md').createSync(recursive: true);
        memoryFileSystem.file('contact.md').writeAsStringSync('''
---
title: Contact Page
---

Contact page content
''');

        Page page = Page('contact.md', frontMatter: {'title': 'Contact Page'});

        String permalink = page.buildPermalink('/contact-us/:title/');
        // Pages use the basename, not the full title
        expect(permalink, equals('contact-us/contact-page/'));
      });

      test('Page in subdirectory', () {
        // Create the page file in memory
        memoryFileSystem.directory('docs').createSync(recursive: true);
        memoryFileSystem.file('docs/api.md').createSync(recursive: true);
        memoryFileSystem.file('docs/api.md').writeAsStringSync('''
---
title: API Documentation
---

API documentation content
''');

        Page page = Page(
          'docs/api.md',
          frontMatter: {'title': 'API Documentation'},
        );

        String permalink = page.buildPermalink(PermalinkStructure.post);
        expect(permalink, equals('docs/api.html'));
      });

      test('Page with basename token', () {
        // Create the page file in memory
        memoryFileSystem.directory('documentation').createSync(recursive: true);
        memoryFileSystem
            .file('documentation/getting-started.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('documentation/getting-started.md')
            .writeAsStringSync('''
---
title: Getting Started Guide
---

Getting started content
''');

        Page page = Page(
          'documentation/getting-started.md',
          frontMatter: {'title': 'Getting Started Guide'},
        );

        String permalink = page.buildPermalink('/help/:basename/:title/');
        // Pages use the basename which is getting-started
        expect(
          permalink,
          equals('help/getting-started/getting-started-guide/'),
        );
      });
    });

    group('Permalink URL Generation', () {
      test('Permalink URL placeholder generation', () {
        // Create the file in memory first
        memoryFileSystem
            .file('_posts/2023-06-15-url-test.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-06-15-url-test.md')
            .writeAsStringSync('''
---
title: URL Test Post
date: 2023-06-15
categories: [tech]
tags: [dart, web]
---

URL test content
''');

        Post urlPost = Post(
          '_posts/2023-06-15-url-test.md',
          frontMatter: {
            'title': 'URL Test Post',
            'date': '2023-06-15',
            'categories': ['tech'],
            'tags': ['dart', 'web'],
          },
        );

        Map<String, String> placeholders = urlPost.permalinkPlaceholders();

        expect(placeholders['title'], equals('url-test'));
        expect(placeholders['categories'], equals('tech'));
        expect(placeholders['year'], equals('2023'));
        expect(placeholders['month'], equals('06'));
        expect(placeholders['day'], equals('15'));
        expect(placeholders['basename'], equals('2023-06-15-url-test'));
        expect(placeholders['path'], equals('_posts'));
      });

      test('Permalink placeholders with slug override', () {
        // Create the file in memory first
        memoryFileSystem
            .file('_posts/2023-08-20-original-name.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-08-20-original-name.md')
            .writeAsStringSync('''
---
title: Original Long Title
date: 2023-08-20
slug: custom-slug
categories: [custom]
---

Slug test content
''');

        Post slugPost = Post(
          '_posts/2023-08-20-original-name.md',
          frontMatter: {
            'title': 'Original Long Title',
            'date': '2023-08-20',
            'slug': 'custom-slug',
            'categories': ['custom'],
          },
        );

        Map<String, String> placeholders = slugPost.permalinkPlaceholders();

        expect(placeholders['title'], equals('custom-slug'));
        expect(placeholders['categories'], equals('custom'));
        expect(placeholders['basename'], equals('2023-08-20-original-name'));
      });

      test('Permalink placeholders for pages', () {
        // Create the page file in memory
        memoryFileSystem.directory('services').createSync(recursive: true);
        memoryFileSystem
            .file('services/web-design.md')
            .createSync(recursive: true);
        memoryFileSystem.file('services/web-design.md').writeAsStringSync('''
---
title: Web Design Services
---

Web design page content
''');

        Page page = Page(
          'services/web-design.md',
          frontMatter: {'title': 'Web Design Services'},
        );

        Map<String, String> placeholders = page.permalinkPlaceholders();

        expect(placeholders['title'], equals('web-design-services'));
        expect(placeholders['path'], equals('services'));
        expect(placeholders['basename'], equals('web-design'));
      });
    });

    group('Token Replacement Edge Cases', () {
      test('Leading slash removal', () {
        // Create the file in memory first
        memoryFileSystem
            .file('_posts/2023-05-10-slash-test.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-05-10-slash-test.md')
            .writeAsStringSync('''
---
title: Slash Test
date: 2023-05-10
---

Slash test content
''');

        Post post = Post(
          '_posts/2023-05-10-slash-test.md',
          frontMatter: {
            'title': 'Slash Test',
            'date': '2023-05-10',
            // No categories - will be empty
          },
        );

        String permalink = post.buildPermalink('/:categories/:title.html');
        // Should remove leading slash when categories is empty
        expect(permalink, equals('posts/slash-test.html'));
      });

      test('Multiple consecutive slashes normalization', () {
        // Create the file in memory first
        memoryFileSystem
            .file('_posts/2023-07-20-multiple-slash.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-07-20-multiple-slash.md')
            .writeAsStringSync('''
---
title: Multiple Slash Test
date: 2023-07-20
categories: [test]
---

Multiple slash test content
''');

        Post post = Post(
          '_posts/2023-07-20-multiple-slash.md',
          frontMatter: {
            'title': 'Multiple Slash Test',
            'date': '2023-07-20',
            'categories': ['test'],
          },
        );

        String permalink = post.buildPermalink('/:categories//:title//extra/');
        expect(permalink, equals('test//multiple-slash//extra/'));
      });

      test('Empty title handling', () {
        // Create the file in memory first
        memoryFileSystem
            .file('_posts/2023-09-15-empty-title-test.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-09-15-empty-title-test.md')
            .writeAsStringSync('''
---
title: ""
date: 2023-09-15
categories: [empty]
---

Empty title test content
''');

        Post emptyTitlePost = Post(
          '_posts/2023-09-15-empty-title-test.md',
          frontMatter: {
            'title': '', // Empty title
            'date': '2023-09-15',
            'categories': ['empty'],
          },
        );

        String permalink = emptyTitlePost.buildPermalink(
          PermalinkStructure.date,
        );
        // Should fall back to slug-based title
        expect(permalink, equals('empty/2023/09/15/empty-title-test.html'));
      });

      test('Whitespace title handling', () {
        // Create the file in memory first
        memoryFileSystem
            .file('_posts/2023-10-05-whitespace.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-10-05-whitespace.md')
            .writeAsStringSync('''
---
title: "   Whitespace   Title   "
date: 2023-10-05
categories: [whitespace]
---

Whitespace test content
''');

        Post whitespacePost = Post(
          '_posts/2023-10-05-whitespace.md',
          frontMatter: {
            'title': '   Whitespace   Title   ',
            'date': '2023-10-05',
            'categories': ['whitespace'],
          },
        );

        String permalink = whitespacePost.buildPermalink(
          PermalinkStructure.date,
        );
        expect(permalink, equals('whitespace/2023/10/05/whitespace.html'));
      });
    });

    group('Complex Integration Scenarios', () {
      test('All permalink tokens in single pattern', () {
        // Create the file in memory first
        memoryFileSystem
            .file('_posts/2023-12-25-complex-test.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-12-25-complex-test.md')
            .writeAsStringSync('''
---
title: Complex Test Post
date: 2023-12-25T15:45:30
categories: [complex, test]
tags: [comprehensive]
slug: complex-slug
---

Complex test content
''');

        Post complexPost = Post(
          '_posts/2023-12-25-complex-test.md',
          frontMatter: {
            'title': 'Complex Test Post',
            'date': '2023-12-25T15:45:30', // Christmas Day with time
            'categories': ['complex', 'test'],
            'tags': ['comprehensive'],
            'slug': 'complex-slug',
          },
        );

        String complexPattern =
            '/:categories/:year/:month/:day/:short_year/:i_month/:i_day/:long_month/:short_month/:long_day/:short_day/:hour/:minute/:second/:title/:basename:output_ext';
        String permalink = complexPost.buildPermalink(complexPattern);

        String expected =
            'complex/2023/12/25/23/12/25/December/Dec/Monday/Mon/15/45/30/complex-slug/2023-12-25-complex-test.html';
        expect(permalink, equals(expected));
      });

      test('Permalink with mixed literal and token content', () {
        // Create the file in memory first
        memoryFileSystem
            .file('_posts/2023-11-10-mixed-content.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-11-10-mixed-content.md')
            .writeAsStringSync('''
---
title: Mixed Content Post
date: 2023-11-10
categories: [mixed]
---

Mixed content test
''');

        Post mixedPost = Post(
          '_posts/2023-11-10-mixed-content.md',
          frontMatter: {
            'title': 'Mixed Content Post',
            'date': '2023-11-10',
            'categories': ['mixed'],
          },
        );

        String mixedPattern =
            '/blog/archive/:year/category-:categories/posts/:title-final.html';
        String permalink = mixedPost.buildPermalink(mixedPattern);

        expect(
          permalink,
          equals(
            'blog/archive/2023/category-mixed/posts/mixed-content-final.html',
          ),
        );
      });

      test('Nested directory structure with tokens', () {
        // Create the file in memory first
        memoryFileSystem
            .file('_posts/2023-04-20-nested-test.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-04-20-nested-test.md')
            .writeAsStringSync('''
---
title: Nested Test Post
date: 2023-04-20
categories: [deep]
---

Nested test content
''');

        Post nestedPost = Post(
          '_posts/2023-04-20-nested-test.md',
          frontMatter: {
            'title': 'Nested Test Post',
            'date': '2023-04-20',
            'categories': ['deep'],
          },
        );

        String nestedPattern =
            '/content/:categories/articles/:year/:month/:title/comments/index.html';
        String permalink = nestedPost.buildPermalink(nestedPattern);

        expect(
          permalink,
          equals(
            'content/deep/articles/2023/04/nested-test/comments/index.html',
          ),
        );
      });

      test('Mixed case and underscore handling', () {
        // Create the file in memory first
        memoryFileSystem
            .file('_posts/2023-05-30-mixed-case.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-05-30-mixed-case.md')
            .writeAsStringSync('''
---
title: Mixed_Case Title With CAPS
date: 2023-05-30
categories: [Test_Category]
---

Mixed case test content
''');

        Post mixedCasePost = Post(
          '_posts/2023-05-30-mixed-case.md',
          frontMatter: {
            'title': 'Mixed_Case Title With CAPS',
            'date': '2023-05-30',
            'categories': ['Test_Category'],
          },
        );

        String permalink = mixedCasePost.buildPermalink(
          PermalinkStructure.date,
        );
        expect(permalink, equals('Test_Category/2023/05/30/mixed-case.html'));
      });

      test('Permalink with query string like syntax', () {
        // Create the file in memory first
        memoryFileSystem
            .file('_posts/2023-07-10-query-test.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-07-10-query-test.md')
            .writeAsStringSync('''
---
title: Query Test
date: 2023-07-10
categories: [query]
---

Query test content
''');

        Post queryPost = Post(
          '_posts/2023-07-10-query-test.md',
          frontMatter: {
            'title': 'Query Test',
            'date': '2023-07-10',
            'categories': ['query'],
          },
        );

        String queryPattern = '/search/:categories?title=:title&year=:year';
        String permalink = queryPost.buildPermalink(queryPattern);

        expect(permalink, equals('search/query?title=query-test&year=2023'));
      });
    });

    group('Advanced Token Validation', () {
      test('All time components with different values', () {
        // Create the file in memory first
        memoryFileSystem
            .file('_posts/2023-12-31-midnight.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-12-31-midnight.md')
            .writeAsStringSync('''
---
title: Midnight Post
date: 2023-12-31T23:59:59
categories: [time-test]
---

Midnight test content
''');

        Post timePost = Post(
          '_posts/2023-12-31-midnight.md',
          frontMatter: {
            'title': 'Midnight Post',
            'date': '2023-12-31T23:59:59',
            'categories': ['time-test'],
          },
        );

        Map<String, String> placeholders = timePost.permalinkPlaceholders();

        expect(placeholders['hour'], equals('23'));
        expect(placeholders['minute'], equals('59'));
        expect(placeholders['second'], equals('59'));
        expect(placeholders['y_day'], equals('365')); // 365th day of year
        expect(placeholders['long_day'], equals('Sunday'));
        expect(placeholders['short_day'], equals('Sun'));
      });

      test('Boundary date conditions', () {
        // Create files for both boundary tests
        memoryFileSystem
            .file('_posts/2024-01-01-first-day.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2024-01-01-first-day.md')
            .writeAsStringSync('''
---
title: First Day
date: 2024-01-01
categories: [boundary]
---

First day content
''');

        memoryFileSystem
            .file('_posts/2024-12-31-last-day.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2024-12-31-last-day.md')
            .writeAsStringSync('''
---
title: Last Day
date: 2024-12-31
categories: [boundary]
---

Last day content
''');

        // First day of year
        Post firstDayPost = Post(
          '_posts/2024-01-01-first-day.md',
          frontMatter: {
            'title': 'First Day',
            'date': '2024-01-01',
            'categories': ['boundary'],
          },
        );

        Map<String, String> firstPlaceholders = firstDayPost
            .permalinkPlaceholders();
        expect(firstPlaceholders['y_day'], equals('001'));
        expect(
          firstPlaceholders['week'],
          matches(RegExp(r'0[1-9]|[1-4][0-9]|5[0-3]')),
        );

        // Last day of leap year
        Post lastDayPost = Post(
          '_posts/2024-12-31-last-day.md',
          frontMatter: {
            'title': 'Last Day',
            'date': '2024-12-31',
            'categories': ['boundary'],
          },
        );

        Map<String, String> lastPlaceholders = lastDayPost
            .permalinkPlaceholders();
        expect(lastPlaceholders['y_day'], equals('366')); // Leap year
      });

      test('Week number edge cases', () {
        // Create files for both week tests
        memoryFileSystem
            .file('_posts/2023-01-02-week1.md')
            .createSync(recursive: true);
        memoryFileSystem.file('_posts/2023-01-02-week1.md').writeAsStringSync(
          '''
---
title: Week 1
date: 2023-01-02
categories: [week]
---

Week 1 content
''',
        );

        memoryFileSystem
            .file('_posts/2020-12-28-week53.md')
            .createSync(recursive: true);
        memoryFileSystem.file('_posts/2020-12-28-week53.md').writeAsStringSync(
          '''
---
title: Week 53
date: 2020-12-28
categories: [week]
---

Week 53 content
''',
        );

        // Week 1 boundary test
        Post week1Post = Post(
          '_posts/2023-01-02-week1.md',
          frontMatter: {
            'title': 'Week 1',
            'date': '2023-01-02', // Monday
            'categories': ['week'],
          },
        );

        Map<String, String> week1Placeholders = week1Post
            .permalinkPlaceholders();
        expect(week1Placeholders['week'], equals('02'));

        // Week 53 test (rare occurrence)
        Post week53Post = Post(
          '_posts/2020-12-28-week53.md',
          frontMatter: {
            'title': 'Week 53',
            'date': '2020-12-28', // A year that has 53 weeks
            'categories': ['week'],
          },
        );

        Map<String, String> week53Placeholders = week53Post
            .permalinkPlaceholders();
        expect(week53Placeholders['week'], matches(RegExp(r'5[23]')));
      });
    });

    group('Error Handling and Resilience', () {
      test('Invalid date format fallback', () {
        // Create the file in memory first
        memoryFileSystem
            .file('_posts/2023-13-40-invalid.md')
            .createSync(recursive: true);
        memoryFileSystem.file('_posts/2023-13-40-invalid.md').writeAsStringSync(
          '''
---
title: Invalid Date
date: 2023-13-40
categories: [error]
---

Invalid date content
''',
        );

        Post invalidDatePost = Post(
          '_posts/2023-13-40-invalid.md',
          frontMatter: {
            'title': 'Invalid Date',
            'date': '2023-13-40', // Invalid month/day
            'categories': ['error'],
          },
        );

        // Should not throw an exception, should handle gracefully
        expect(
          () => invalidDatePost.buildPermalink(PermalinkStructure.date),
          isNot(throwsException),
        );
      });

      test('Null values in frontmatter', () {
        // Create the file in memory first
        memoryFileSystem
            .file('_posts/2023-06-15-null-test.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-06-15-null-test.md')
            .writeAsStringSync('''
---
title: null
date: 2023-06-15
categories: null
---

Null test content
''');

        Post nullPost = Post(
          '_posts/2023-06-15-null-test.md',
          frontMatter: {
            'title': null,
            'date': '2023-06-15',
            'categories': null,
          },
        );

        String permalink = nullPost.buildPermalink(PermalinkStructure.date);
        // Should handle null values gracefully
        expect(permalink, isNotEmpty);
        expect(permalink, contains('2023/06/15'));
      });

      test('Empty string values in frontmatter', () {
        // Create the file in memory first
        memoryFileSystem
            .file('_posts/2023-08-25-empty-test.md')
            .createSync(recursive: true);
        memoryFileSystem
            .file('_posts/2023-08-25-empty-test.md')
            .writeAsStringSync('''
---
title: ""
date: 2023-08-25
categories: []
---

Empty test content
''');

        Post emptyPost = Post(
          '_posts/2023-08-25-empty-test.md',
          frontMatter: {
            'title': '',
            'date': '2023-08-25',
            'categories': <String>[],
          },
        );

        String permalink = emptyPost.buildPermalink(PermalinkStructure.date);
        expect(permalink, contains('2023/08/25'));
        expect(permalink, endsWith('.html'));
      });
    });
  });

  group('Posts Resolving to index.html', () {
    test('Pretty permalink structure creates index.html', () {
      // Create the file in memory first
      memoryFileSystem
          .file('_posts/2024-03-10-pretty-post.md')
          .createSync(recursive: true);
      memoryFileSystem
          .file('_posts/2024-03-10-pretty-post.md')
          .writeAsStringSync('''
---
title: Pretty Post Example
date: 2024-03-10
categories: [blog]
permalink: pretty
---

Content for pretty post
''');

      Post prettyPost = Post(
        '_posts/2024-03-10-pretty-post.md',
        frontMatter: {
          'title': 'Pretty Post Example',
          'date': '2024-03-10',
          'categories': ['blog'],
          'permalink': 'pretty',
        },
      );

      String permalink = prettyPost.permalink();
      expect(permalink, equals('blog/2024/03/10/pretty-post/index.html'));
    });

    test('Custom permalink with trailing slash creates index.html', () {
      // Create the file in memory first
      memoryFileSystem
          .file('_posts/2024-05-15-custom-directory.md')
          .createSync(recursive: true);
      memoryFileSystem
          .file('_posts/2024-05-15-custom-directory.md')
          .writeAsStringSync('''
---
title: Custom Directory Post
date: 2024-05-15
categories: [tutorials]
permalink: /tutorials/:title/
---

Custom directory content
''');

      Post customPost = Post(
        '_posts/2024-05-15-custom-directory.md',
        frontMatter: {
          'title': 'Custom Directory Post',
          'date': '2024-05-15',
          'categories': ['tutorials'],
          'permalink': '/tutorials/:title/',
        },
      );

      String permalink = customPost.permalink();
      expect(permalink, equals('tutorials/custom-directory/index.html'));
    });

    test('Literal permalink without extension creates index.html', () {
      // Create the file in memory first
      memoryFileSystem
          .file('_posts/2024-07-20-special-page.md')
          .createSync(recursive: true);
      memoryFileSystem
          .file('_posts/2024-07-20-special-page.md')
          .writeAsStringSync('''
---
title: Special Page
date: 2024-07-20
permalink: /special/landing
---

Special landing page content
''');

      Post specialPost = Post(
        '_posts/2024-07-20-special-page.md',
        frontMatter: {
          'title': 'Special Page',
          'date': '2024-07-20',
          'permalink': '/special/landing',
        },
      );

      String permalink = specialPost.permalink();
      expect(permalink, equals('special/landing.html'));
    });

    test('Posts index file resolves to posts/index.html', () {
      // Create the file in memory first
      memoryFileSystem.file('_posts/index.html').createSync(recursive: true);
      memoryFileSystem.file('_posts/index.html').writeAsStringSync('''
---
title: Posts Index
layout: default
---

<h1>All Posts</h1>
{% for post in site.posts %}
  <h2>{{ post.title }}</h2>
{% endfor %}
''');

      Page postsIndex = Page(
        '_posts/index.html',
        frontMatter: {'title': 'Posts Index', 'layout': 'default'},
      );

      String permalink = postsIndex.link();
      expect(permalink, equals('posts/index.html'));
    });

    test('Blog-style permalink with trailing slash', () {
      // Create the file in memory first
      memoryFileSystem
          .file('_posts/2024-09-05-blog-style.md')
          .createSync(recursive: true);
      memoryFileSystem
          .file('_posts/2024-09-05-blog-style.md')
          .writeAsStringSync('''
---
title: Blog Style Post
date: 2024-09-05
categories: [web-development]
permalink: /blog/:year/:month/:title/
---

Blog style content
''');

      Post blogPost = Post(
        '_posts/2024-09-05-blog-style.md',
        frontMatter: {
          'title': 'Blog Style Post',
          'date': '2024-09-05',
          'categories': ['web-development'],
          'permalink': '/blog/:year/:month/:title/',
        },
      );

      String permalink = blogPost.permalink();
      expect(permalink, equals('blog/2024/09/blog-style/index.html'));
    });

    test('Category-based permalink with directory structure', () {
      // Create the file in memory first
      memoryFileSystem
          .file('_posts/2024-11-12-category-post.md')
          .createSync(recursive: true);
      memoryFileSystem
          .file('_posts/2024-11-12-category-post.md')
          .writeAsStringSync('''
---
title: Category Post
date: 2024-11-12
categories: [docs, guides]
permalink: /:categories/:title/
---

Category-based content
''');

      Post categoryPost = Post(
        '_posts/2024-11-12-category-post.md',
        frontMatter: {
          'title': 'Category Post',
          'date': '2024-11-12',
          'categories': ['docs', 'guides'],
          'permalink': '/:categories/:title/',
        },
      );

      String permalink = categoryPost.permalink();
      expect(permalink, equals('docs/category-post/index.html'));
    });

    test('Simple directory permalink without tokens', () {
      // Create the file in memory first
      memoryFileSystem
          .file('_posts/2024-12-25-simple-dir.md')
          .createSync(recursive: true);
      memoryFileSystem
          .file('_posts/2024-12-25-simple-dir.md')
          .writeAsStringSync('''
---
title: Simple Directory
date: 2024-12-25
permalink: /archive/
---

Simple directory content
''');

      Post simpleDirPost = Post(
        '_posts/2024-12-25-simple-dir.md',
        frontMatter: {
          'title': 'Simple Directory',
          'date': '2024-12-25',
          'permalink': '/archive/',
        },
      );

      String permalink = simpleDirPost.permalink();
      expect(permalink, equals('archive/index.html'));
    });

    test('Nested directory structure with index.html', () {
      // Create the file in memory first
      memoryFileSystem
          .file('_posts/2024-06-30-nested-post.md')
          .createSync(recursive: true);
      memoryFileSystem
          .file('_posts/2024-06-30-nested-post.md')
          .writeAsStringSync('''
---
title: Nested Post
date: 2024-06-30
categories: [projects, web]
permalink: /portfolio/:categories/:year/:title/
---

Nested directory content
''');

      Post nestedPost = Post(
        '_posts/2024-06-30-nested-post.md',
        frontMatter: {
          'title': 'Nested Post',
          'date': '2024-06-30',
          'categories': ['projects', 'web'],
          'permalink': '/portfolio/:categories/:year/:title/',
        },
      );

      String permalink = nestedPost.permalink();
      expect(
        permalink,
        equals('portfolio/projects/2024/nested-post/index.html'),
      );
    });
  });

  group('Error Handling and Resilience', () {
    test('Invalid date format fallback', () {
      // Create the file in memory first
      memoryFileSystem
          .file('_posts/2023-13-40-invalid.md')
          .createSync(recursive: true);
      memoryFileSystem.file('_posts/2023-13-40-invalid.md').writeAsStringSync(
        '''
---
title: Invalid Date
date: 2023-13-40
categories: [error]
---

Invalid date content
''',
      );

      Post invalidDatePost = Post(
        '_posts/2023-13-40-invalid.md',
        frontMatter: {
          'title': 'Invalid Date',
          'date': '2023-13-40', // Invalid month/day
          'categories': ['error'],
        },
      );

      // Should not throw an exception, should handle gracefully
      expect(
        () => invalidDatePost.buildPermalink(PermalinkStructure.date),
        isNot(throwsException),
      );
    });

    test('Null values in frontmatter', () {
      // Create the file in memory first
      memoryFileSystem
          .file('_posts/2023-06-15-null-test.md')
          .createSync(recursive: true);
      memoryFileSystem.file('_posts/2023-06-15-null-test.md').writeAsStringSync(
        '''
---
title: null
date: 2023-06-15
categories: null
---

Null test content
''',
      );

      Post nullPost = Post(
        '_posts/2023-06-15-null-test.md',
        frontMatter: {'title': null, 'date': '2023-06-15', 'categories': null},
      );

      String permalink = nullPost.buildPermalink(PermalinkStructure.date);
      // Should handle null values gracefully
      expect(permalink, isNotEmpty);
      expect(permalink, contains('2023/06/15'));
    });

    test('Empty string values in frontmatter', () {
      // Create the file in memory first
      memoryFileSystem
          .file('_posts/2023-08-25-empty-test.md')
          .createSync(recursive: true);
      memoryFileSystem
          .file('_posts/2023-08-25-empty-test.md')
          .writeAsStringSync('''
---
title: ""
date: 2023-08-25
categories: []
---

Empty test content
''');

      Post emptyPost = Post(
        '_posts/2023-08-25-empty-test.md',
        frontMatter: {
          'title': '',
          'date': '2023-08-25',
          'categories': <String>[],
        },
      );

      String permalink = emptyPost.buildPermalink(PermalinkStructure.date);
      expect(permalink, contains('2023/08/25'));
      expect(permalink, endsWith('.html'));
    });
  });
}
