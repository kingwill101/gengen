import 'package:file/memory.dart';
import 'package:gengen/site.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/configuration.dart';
import 'package:test/test.dart';

void main() {
  group('Missing Layout Behavior', () {
    late MemoryFileSystem fs;
    late Site site;

    tearDown(() {
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
          .directory('$projectRoot/test_site/_themes')
          .create(recursive: true);
      await fs
          .directory('$projectRoot/test_site/_themes/default')
          .create(recursive: true);
      await fs
          .directory('$projectRoot/test_site/_themes/default/_layouts')
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
''');

      // Create layouts
      await fs
          .file('$projectRoot/test_site/_themes/default/_layouts/default.html')
          .writeAsString('''
<!DOCTYPE html>
<html>
<head>
  <title>{{ page.title | default: site.title }}</title>
</head>
<body>
  <h1>{{ page.title }}</h1>
  <div class="content">
    {{ content }}
  </div>
</body>
</html>
''');

      await fs
          .file('$projectRoot/test_site/_themes/default/_layouts/post.html')
          .writeAsString('''
---
layout: default
---
<article>
  <header>
    <h1>{{ page.title }}</h1>
    <time>{{ page.date | date: '%B %d, %Y' }}</time>
  </header>
  <div class="post-content">
    {{ content }}
  </div>
</article>
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
        },
      );
      site = Site.instance;
    });

    test('should render content without layout when layout is missing', () async {
      // Create a post WITHOUT layout specified
      await fs
          .file(
            '${fs.currentDirectory.path}/test_site/_posts/2024-01-10-no-layout.md',
          )
          .writeAsString('''
---
title: "Post Without Layout"
date: 2024-01-10
---

# This is a post without layout

This post should still render its content even without a layout specified.

## Markdown should work

- Bullet points
- Should render
- Properly

**Bold text** and *italic text* should work too.
''');

      await site.process();

      final post = site.posts.firstWhere(
        (post) => post.config["title"] == "Post Without Layout",
      );

      print('=== MISSING LAYOUT TEST ===');
      print('Post title: "${post.config["title"]}"');
      print('Post layout: "${post.layout}"');
      print('Content length: ${post.content.length}');
      print('Rendered content length: ${post.renderer.content.length}');
      print(
        'Rendered content preview: ${post.renderer.content.substring(0, post.renderer.content.length > 200 ? 200 : post.renderer.content.length)}...',
      );

      // Check that content was rendered
      expect(
        post.renderer.content.isNotEmpty,
        true,
        reason: 'Post should render content even without layout',
      );

      // The content should contain the markdown converted to HTML
      expect(
        post.renderer.content,
        contains('<h1'),
        reason: 'Markdown should be converted to HTML',
      );
      expect(
        post.renderer.content,
        contains('This is a post without layout'),
        reason: 'Post content should be present',
      );
      expect(
        post.renderer.content,
        contains('<strong>Bold text</strong>'),
        reason: 'Markdown formatting should work',
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
        greaterThan(100),
        reason: 'Output should have substantial content',
      );

      print('Output file size: ${fileContent.length} bytes');
      print(
        'Output file preview: ${fileContent.substring(0, fileContent.length > 200 ? 200 : fileContent.length)}...',
      );
    });

    test('should compare behavior between post with layout vs without layout', () async {
      // Create two posts - one with layout, one without
      await fs
          .file(
            '${fs.currentDirectory.path}/test_site/_posts/2024-01-10-with-layout.md',
          )
          .writeAsString('''
---
title: "Post With Layout"
date: 2024-01-10
layout: post
---

# This is a post with layout

This post has a layout specified.
''');

      await fs
          .file(
            '${fs.currentDirectory.path}/test_site/_posts/2024-01-11-without-layout.md',
          )
          .writeAsString('''
---
title: "Post Without Layout"
date: 2024-01-11
---

# This is a post without layout

This post has no layout specified.
''');

      await site.process();

      final postWithLayout = site.posts.firstWhere(
        (post) => post.config["title"] == "Post With Layout",
      );
      final postWithoutLayout = site.posts.firstWhere(
        (post) => post.config["title"] == "Post Without Layout",
      );

      print('\n=== COMPARISON ===');
      print('WITH LAYOUT:');
      print('  Layout: "${postWithLayout.layout}"');
      print('  Rendered length: ${postWithLayout.renderer.content.length}');
      print(
        '  Preview: ${postWithLayout.renderer.content.substring(0, postWithLayout.renderer.content.length > 100 ? 100 : postWithLayout.renderer.content.length)}...',
      );

      print('\nWITHOUT LAYOUT:');
      print('  Layout: "${postWithoutLayout.layout}"');
      print('  Rendered length: ${postWithoutLayout.renderer.content.length}');
      print(
        '  Preview: ${postWithoutLayout.renderer.content.substring(0, postWithoutLayout.renderer.content.length > 100 ? 100 : postWithoutLayout.renderer.content.length)}...',
      );

      // Both should have content
      expect(
        postWithLayout.renderer.content.isNotEmpty,
        true,
        reason: 'Post with layout should have content',
      );
      expect(
        postWithoutLayout.renderer.content.isNotEmpty,
        true,
        reason: 'Post without layout should also have content',
      );

      // Both should have substantial content (not just 1 byte)
      expect(postWithLayout.renderer.content.length, greaterThan(50));
      expect(postWithoutLayout.renderer.content.length, greaterThan(50));

      // The difference should be that one has layout wrapper HTML, the other just markdown->HTML
      if (postWithLayout.renderer.content.contains('<!DOCTYPE html>')) {
        print('Post with layout has full HTML structure');
      }
      if (postWithoutLayout.renderer.content.contains('<!DOCTYPE html>')) {
        print('Post without layout also has HTML structure (unexpected?)');
      } else {
        print('Post without layout has just converted markdown (expected)');
      }
    });
  });
}
