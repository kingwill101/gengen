import 'package:file/memory.dart';
import 'package:gengen/exceptions.dart';
import 'package:gengen/site.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/configuration.dart';
import 'package:test/test.dart';

void main() {
  group('Liquid Content in Posts', () {
    late MemoryFileSystem fs;
    late Site site;

    tearDown(() {
      Site.resetInstance();
      Configuration.resetConfig();
    });

    setUp(() async {
      fs = MemoryFileSystem();
      gengen_fs.fs = fs;

      final projectRoot = fs.currentDirectory.path;

      // Create test site structure
      await fs.directory('$projectRoot/test_site').create(recursive: true);
      await fs
          .directory('$projectRoot/test_site/_posts')
          .create(recursive: true);
      await fs
          .directory('$projectRoot/test_site/_includes')
          .create(recursive: true);
      await fs
          .directory('$projectRoot/test_site/_themes')
          .create(recursive: true);
      await fs
          .directory('$projectRoot/test_site/_themes/default')
          .create(recursive: true);
      await fs
          .directory('$projectRoot/test_site/_themes/default/_layouts')
          .create(recursive: true);
      await fs
          .directory('$projectRoot/test_site/_themes/default/_includes')
          .create(recursive: true);
      await fs
          .directory('$projectRoot/test_site/public')
          .create(recursive: true);

      // Create config
      await fs.file('$projectRoot/test_site/_config.yaml').writeAsString('''
title: "Test Site"
source: $projectRoot/test_site
destination: $projectRoot/test_site/public
permalink: "posts/:title/"
pagination:
  enabled: false
''');

      // Create theme config
      await fs
          .file('$projectRoot/test_site/_themes/default/config.yaml')
          .writeAsString('''
name: default
version: 1.0.0
''');

      // Initialize site
      Site.init(
        overrides: {
          'source': '$projectRoot/test_site',
          'destination': '$projectRoot/test_site/public',
          'permalink': 'posts/:title/',
          'pagination': {'enabled': false},
        },
      );
      site = Site.instance;
    });

    test('reports template context when Liquid parsing fails', () async {
      final projectRoot = fs.currentDirectory.path;
      final postPath =
          '$projectRoot/test_site/_posts/2024-01-12-invalid-liquid.md';

      await fs
          .file('$projectRoot/test_site/_themes/default/_layouts/broken.html')
          .writeAsString('''
{% for entry in page %}
  {{ entry }}
{% endfor %}
''');

      await fs.file(postPath).writeAsString('''
---
title: "Invalid Liquid"
date: 2024-01-12
layout: broken
---

Content.
''');

      expect(
        () async => await site.process(),
        throwsA(
          predicate((error) {
            if (error is! PluginException) {
              return false;
            }

            return error.message.contains('Liquid render failed') &&
                error.message.contains('broken') &&
                error.message.contains('invalid-liquid.md') &&
                error.message.contains('type');
          }),
        ),
      );
    });

    test('fails fast when includes are missing', () async {
      final projectRoot = fs.currentDirectory.path;

      await fs
          .file('$projectRoot/test_site/_themes/default/_layouts/post.html')
          .writeAsString('''
{% render 'partials/post_card' %}
{{ content }}
''');

      await fs
          .file('$projectRoot/test_site/_posts/2024-01-15-missing-include.md')
          .writeAsString('''
---
title: "Needs Include"
date: 2024-01-15
layout: post
---

Content.
''');

      expect(
        () async => await site.process(),
        throwsA(
          predicate((error) {
            if (error is! PluginException) {
              return false;
            }

            return error.message.contains('Include "partials/post_card"') &&
                error.message.contains('post') &&
                error.message.contains('Checked');
          }),
        ),
      );
    });

    test('should handle posts with Liquid template syntax in content', () async {
      // Create a post with Liquid syntax that can't be resolved
      await fs
          .file(
            '${fs.currentDirectory.path}/test_site/_posts/2024-01-10-liquid-content.md',
          )
          .writeAsString('''
---
title: "Post With Liquid Content"
date: 2024-01-10
---

# Post with Liquid Template Content

This post contains Liquid template syntax:

```liquid
{% for post in site.paginate.items %}
  <article>
    <h2><a href="{{ post.url }}">{{ post.title }}</a></h2>
    <time>{{ post.date | date: '%B %d, %Y' }}</time>
    <p>{{ post.excerpt }}</p>
  </article>
{% endfor %}
```

And some variables that don't exist:
- {{ site.paginate.current_page }}
- {{ site.paginate.total_pages }}

This should still render properly even though these variables don't exist.
''');

      await site.process();

      final post = site.posts.firstWhere(
        (post) => post.config["title"] == "Post With Liquid Content",
      );

      print('=== LIQUID CONTENT TEST ===');
      print('Post title: "${post.config["title"]}"');
      print('Has Liquid: ${post.hasLiquid}');
      print('Content length: ${post.content.length}');
      print('Rendered content length: ${post.renderer.content.length}');
      print('Rendered content preview:');
      print(
        post.renderer.content.substring(
          0,
          post.renderer.content.length > 500
              ? 500
              : post.renderer.content.length,
        ),
      );
      print('...');

      // Check that content was rendered
      expect(
        post.renderer.content.isNotEmpty,
        true,
        reason: 'Post with Liquid content should still render',
      );

      expect(
        post.renderer.content.length,
        greaterThan(50),
        reason: 'Post should have substantial content despite Liquid syntax',
      );

      // Check the output file
      final outputFile = fs.file(post.filePath);
      expect(
        await outputFile.exists(),
        true,
        reason: 'Output file should be created',
      );

      final fileContent = await outputFile.readAsString();
      expect(
        fileContent.isNotEmpty,
        true,
        reason: 'Output file should not be empty',
      );
      expect(
        fileContent.length,
        greaterThan(50),
        reason: 'Output should have substantial content',
      );

      print('\nOutput file size: ${fileContent.length} bytes');
    });

    test('should compare simple content vs Liquid content', () async {
      // Create two posts - one simple, one with Liquid
      await fs
          .file(
            '${fs.currentDirectory.path}/test_site/_posts/2024-01-10-simple-content.md',
          )
          .writeAsString('''
---
title: "Simple Content Post"
date: 2024-01-10
---

# Simple Post

This is just regular markdown with no Liquid syntax.

**Bold text** and regular content.
''');

      await fs
          .file(
            '${fs.currentDirectory.path}/test_site/_posts/2024-01-11-liquid-content.md',
          )
          .writeAsString('''
---
title: "Liquid Content Post"
date: 2024-01-11
---

# Liquid Post

This post has Liquid syntax: {{ site.nonexistent.variable }}

```liquid
{% for item in site.missing.collection %}
  {{ item.title }}
{% endfor %}
```

Regular content mixed with Liquid.
''');

      await site.process();

      final simplePost = site.posts.firstWhere(
        (post) => post.config["title"] == "Simple Content Post",
      );
      final liquidPost = site.posts.firstWhere(
        (post) => post.config["title"] == "Liquid Content Post",
      );

      print('\n=== COMPARISON ===');
      print('SIMPLE POST:');
      print('  Has Liquid: ${simplePost.hasLiquid}');
      print('  Rendered length: ${simplePost.renderer.content.length}');
      print(
        '  Preview: ${simplePost.renderer.content.substring(0, simplePost.renderer.content.length > 100 ? 100 : simplePost.renderer.content.length)}...',
      );

      print('\nLIQUID POST:');
      print('  Has Liquid: ${liquidPost.hasLiquid}');
      print('  Rendered length: ${liquidPost.renderer.content.length}');
      print(
        '  Preview: ${liquidPost.renderer.content.substring(0, liquidPost.renderer.content.length > 100 ? 100 : liquidPost.renderer.content.length)}...',
      );

      // Both should have content
      expect(
        simplePost.renderer.content.isNotEmpty,
        true,
        reason: 'Simple post should have content',
      );
      expect(
        liquidPost.renderer.content.isNotEmpty,
        true,
        reason: 'Liquid post should also have content',
      );

      // Both should have substantial content (not just 1 byte)
      expect(simplePost.renderer.content.length, greaterThan(50));
      expect(liquidPost.renderer.content.length, greaterThan(50));
    });
  });
}
