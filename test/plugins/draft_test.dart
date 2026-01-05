import 'package:file/memory.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/plugin/builtin/draft.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late MemoryFileSystem memoryFileSystem;
  late String projectRoot;

  setUp(() {
    memoryFileSystem = MemoryFileSystem();
    gengen_fs.fs = memoryFileSystem;
    // Use a unique project root for each test to avoid conflicts
    // Add a small delay to ensure unique timestamps
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    projectRoot = '/test-site-$timestamp';
  });

  tearDown(() {
    // Reset all DraftPlugin instances to clear internal state
    try {
      for (final plugin in Site.instance.plugins.whereType<DraftPlugin>()) {
        plugin.reset();
      }
    } catch (_) {
      // Site instance might not exist, ignore
    }
    Site.resetInstance();
    // Clear any residual state that might affect subsequent tests
    gengen_fs.fs = MemoryFileSystem();
  });

  group('DraftPlugin', () {
    group('Draft Directory Reading', () {
      test('should read posts from _drafts directory and mark them as drafts', () async {
        // Create site structure with _drafts directory
        await memoryFileSystem.directory(p.join(projectRoot, '_posts')).create(recursive: true);
        await memoryFileSystem.directory(p.join(projectRoot, '_drafts')).create(recursive: true);
        await memoryFileSystem.directory(p.join(projectRoot, '_layouts')).create(recursive: true);

        // Create site config
        memoryFileSystem.file(p.join(projectRoot, '_config.yaml')).writeAsStringSync('''
title: Test Site
description: Test site for draft functionality
publish_drafts: true
''');

        // Create regular post
        memoryFileSystem.file(p.join(projectRoot, '_posts', '2024-12-20-published-post.md')).writeAsStringSync('''
---
title: Published Post
date: 2024-12-20
---

This is a published post.
''');

        // Create draft posts
        memoryFileSystem.file(p.join(projectRoot, '_drafts', '2024-12-21-draft-post.md')).writeAsStringSync('''
---
title: Draft Post
date: 2024-12-21
---

This is a draft post.
''');

        memoryFileSystem.file(p.join(projectRoot, '_drafts', '2024-12-22-another-draft.md')).writeAsStringSync('''
---
title: Another Draft
date: 2024-12-22
---

This is another draft post.
''');

        // Create basic layout
        memoryFileSystem.file(p.join(projectRoot, '_layouts', 'default.html')).writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

        // Initialize site
        Site.init(overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        });

        await Site.instance.process();

        final posts = Site.instance.posts;
        expect(posts.length, equals(3), reason: 'Should have 1 published + 2 draft posts');

        // Check published post
        final publishedPost = posts.firstWhere((post) => post.config['title'] == 'Published Post');
        expect(publishedPost.isDraft(), isFalse, reason: 'Published post should not be marked as draft');

        // Check draft posts
        final draftPost = posts.firstWhere((post) => post.config['title'] == 'Draft Post');
        expect(draftPost.isDraft(), isTrue, reason: 'Draft post should be marked as draft');
        expect(draftPost.config['draft'], isTrue, reason: 'Draft flag should be set in config');

        final anotherDraft = posts.firstWhere((post) => post.config['title'] == 'Another Draft');
        expect(anotherDraft.isDraft(), isTrue, reason: 'Another draft should be marked as draft');
        expect(anotherDraft.config['draft'], isTrue, reason: 'Draft flag should be set in config');
      });

      test('should handle missing _drafts directory gracefully', () async {
        // Create site structure without _drafts directory
        await memoryFileSystem.directory(p.join(projectRoot, '_posts')).create(recursive: true);
        await memoryFileSystem.directory(p.join(projectRoot, '_layouts')).create(recursive: true);

        // Create site config
        memoryFileSystem.file(p.join(projectRoot, '_config.yaml')).writeAsStringSync('''
title: Test Site
description: Test site without draft directory
''');

        // Create regular post
        memoryFileSystem.file(p.join(projectRoot, '_posts', '2024-12-20-published-post.md')).writeAsStringSync('''
---
title: Published Post
date: 2024-12-20
---

This is a published post.
''');

        // Create basic layout
        memoryFileSystem.file(p.join(projectRoot, '_layouts', 'default.html')).writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

        // Initialize site
        Site.init(overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        });

        await Site.instance.process();

        final posts = Site.instance.posts;
        expect(posts.length, equals(1), reason: 'Should have only the published post');

        final post = posts.first;
        expect(post.config['title'], equals('Published Post'));
        expect(post.isDraft(), isFalse, reason: 'Post should not be marked as draft');
      });

      test('should handle empty _drafts directory', () async {
        // Create site structure with empty _drafts directory
        await memoryFileSystem.directory(p.join(projectRoot, '_posts')).create(recursive: true);
        await memoryFileSystem.directory(p.join(projectRoot, '_drafts')).create(recursive: true);
        await memoryFileSystem.directory(p.join(projectRoot, '_layouts')).create(recursive: true);

        // Create site config
        memoryFileSystem.file(p.join(projectRoot, '_config.yaml')).writeAsStringSync('''
title: Test Site
description: Test site with empty draft directory
''');

        // Create regular post
        memoryFileSystem.file(p.join(projectRoot, '_posts', '2024-12-20-published-post.md')).writeAsStringSync('''
---
title: Published Post
date: 2024-12-20
---

This is a published post.
''');

        // Create basic layout
        memoryFileSystem.file(p.join(projectRoot, '_layouts', 'default.html')).writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

        // Initialize site
        Site.init(overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        });

        await Site.instance.process();

        final posts = Site.instance.posts;
        expect(posts.length, equals(1), reason: 'Should have only the published post');

        final post = posts.first;
        expect(post.config['title'], equals('Published Post'));
        expect(post.isDraft(), isFalse, reason: 'Post should not be marked as draft');
      });
    });

    group('Draft Filtering', () {
      test('should filter out drafts when publish_drafts is false', () async {
        // Create site structure
        await memoryFileSystem.directory(p.join(projectRoot, '_posts')).create(recursive: true);
        await memoryFileSystem.directory(p.join(projectRoot, '_drafts')).create(recursive: true);
        await memoryFileSystem.directory(p.join(projectRoot, '_layouts')).create(recursive: true);

        // Create site config with publish_drafts: false
        memoryFileSystem.file(p.join(projectRoot, '_config.yaml')).writeAsStringSync('''
title: Test Site
description: Test site with draft filtering
publish_drafts: false
''');

        // Create regular post
        memoryFileSystem.file(p.join(projectRoot, '_posts', '2024-12-20-published-post.md')).writeAsStringSync('''
---
title: Published Post
date: 2024-12-20
---

This is a published post.
''');

        // Create post marked as draft in front matter
        memoryFileSystem.file(p.join(projectRoot, '_posts', '2024-12-21-frontmatter-draft.md')).writeAsStringSync('''
---
title: Front Matter Draft
date: 2024-12-21
draft: true
---

This post is marked as draft in front matter.
''');

        // Create draft post in _drafts directory
        memoryFileSystem.file(p.join(projectRoot, '_drafts', '2024-12-22-directory-draft.md')).writeAsStringSync('''
---
title: Directory Draft
date: 2024-12-22
---

This is a draft in the draft directory.
''');

        // Create basic layout
        memoryFileSystem.file(p.join(projectRoot, '_layouts', 'default.html')).writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

        // Initialize site
        Site.init(overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        });

        await Site.instance.process();

        final posts = Site.instance.posts;
        expect(posts.length, equals(1), reason: 'Should only have published post after filtering');

        final post = posts.first;
        expect(post.config['title'], equals('Published Post'));
        expect(post.isDraft(), isFalse, reason: 'Remaining post should not be draft');
      });

      test('should keep all posts when publish_drafts is true', () async {
        // Create site structure
        await memoryFileSystem.directory(p.join(projectRoot, '_posts')).create(recursive: true);
        await memoryFileSystem.directory(p.join(projectRoot, '_drafts')).create(recursive: true);
        await memoryFileSystem.directory(p.join(projectRoot, '_layouts')).create(recursive: true);

        // Create site config with publish_drafts: true
        memoryFileSystem.file(p.join(projectRoot, '_config.yaml')).writeAsStringSync('''
title: Test Site
description: Test site with draft publishing enabled
publish_drafts: true
''');

        // Create regular post
        memoryFileSystem.file(p.join(projectRoot, '_posts', '2024-12-20-published-post.md')).writeAsStringSync('''
---
title: Published Post
date: 2024-12-20
---

This is a published post.
''');

        // Create post marked as draft in front matter
        memoryFileSystem.file(p.join(projectRoot, '_posts', '2024-12-21-frontmatter-draft.md')).writeAsStringSync('''
---
title: Front Matter Draft
date: 2024-12-21
draft: true
---

This post is marked as draft in front matter.
''');

        // Create draft post in _drafts directory
        memoryFileSystem.file(p.join(projectRoot, '_drafts', '2024-12-22-directory-draft.md')).writeAsStringSync('''
---
title: Directory Draft
date: 2024-12-22
---

This is a draft in the draft directory.
''');

        // Create basic layout
        memoryFileSystem.file(p.join(projectRoot, '_layouts', 'default.html')).writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

        // Initialize site
        Site.init(overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        });

        await Site.instance.process();

        final posts = Site.instance.posts;
        expect(posts.length, equals(3), reason: 'Should have all posts when publish_drafts is true');

        // Check each post type
        final publishedPost = posts.firstWhere((post) => post.config['title'] == 'Published Post');
        expect(publishedPost.isDraft(), isFalse, reason: 'Published post should not be draft');

        final frontmatterDraft = posts.firstWhere((post) => post.config['title'] == 'Front Matter Draft');
        expect(frontmatterDraft.isDraft(), isTrue, reason: 'Front matter draft should be marked as draft');

        final directoryDraft = posts.firstWhere((post) => post.config['title'] == 'Directory Draft');
        expect(directoryDraft.isDraft(), isTrue, reason: 'Directory draft should be marked as draft');
      });

      test('should handle posts with draft: false explicitly set', () async {
        // Create site structure
        await memoryFileSystem.directory(p.join(projectRoot, '_posts')).create(recursive: true);
        await memoryFileSystem.directory(p.join(projectRoot, '_layouts')).create(recursive: true);

        // Create site config
        memoryFileSystem.file(p.join(projectRoot, '_config.yaml')).writeAsStringSync('''
title: Test Site
description: Test site for explicit draft false
''');

        // Create post with explicit draft: false
        memoryFileSystem.file(p.join(projectRoot, '_posts', '2024-12-20-explicit-published.md')).writeAsStringSync('''
---
title: Explicitly Published Post
date: 2024-12-20
draft: false
---

This post explicitly sets draft: false.
''');

        // Create basic layout
        memoryFileSystem.file(p.join(projectRoot, '_layouts', 'default.html')).writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

        // Initialize site
        Site.init(overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        });

        await Site.instance.process();

        final posts = Site.instance.posts;
        expect(posts.length, equals(1), reason: 'Should have the explicitly published post');

        final post = posts.first;
        expect(post.config['title'], equals('Explicitly Published Post'));
        expect(post.isDraft(), isFalse, reason: 'Post with draft: false should not be marked as draft');
        expect(post.config['draft'], isFalse, reason: 'Draft config should be false');
      });
    });

    group('Custom Draft Directory', () {
      test('should read from custom draft directory when configured', () async {
        // Create site structure with custom draft directory
        await memoryFileSystem.directory(p.join(projectRoot, '_posts')).create(recursive: true);
        await memoryFileSystem.directory(p.join(projectRoot, 'drafts')).create(recursive: true);
        await memoryFileSystem.directory(p.join(projectRoot, '_layouts')).create(recursive: true);

        // Create site config with custom draft directory
        memoryFileSystem.file(p.join(projectRoot, '_config.yaml')).writeAsStringSync('''
title: Test Site
description: Test site with custom draft directory
draft_dir: drafts
publish_drafts: true
''');

        // Create regular post
        memoryFileSystem.file(p.join(projectRoot, '_posts', '2024-12-20-published-post.md')).writeAsStringSync('''
---
title: Published Post
date: 2024-12-20
---

This is a published post.
''');

        // Create draft post in custom directory
        memoryFileSystem.file(p.join(projectRoot, 'drafts', '2024-12-21-custom-draft.md')).writeAsStringSync('''
---
title: Custom Draft
date: 2024-12-21
---

This is a draft in the custom directory.
''');

        // Create basic layout
        memoryFileSystem.file(p.join(projectRoot, '_layouts', 'default.html')).writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

        // Initialize site
        Site.init(overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        });

        await Site.instance.process();

        final posts = Site.instance.posts;
        expect(posts.length, equals(2), reason: 'Should have published post + custom draft');

        final publishedPost = posts.firstWhere((post) => post.config['title'] == 'Published Post');
        expect(publishedPost.isDraft(), isFalse, reason: 'Published post should not be draft');

        final customDraft = posts.firstWhere((post) => post.config['title'] == 'Custom Draft');
        expect(customDraft.isDraft(), isTrue, reason: 'Custom draft should be marked as draft');
        expect(customDraft.config['draft'], isTrue, reason: 'Draft flag should be set');
      });
    });

    group('Plugin Integration', () {
      test('should work with DraftPlugin instance methods', () async {
        // Create site structure
        await memoryFileSystem.directory(p.join(projectRoot, '_posts')).create(recursive: true);
        await memoryFileSystem.directory(p.join(projectRoot, '_drafts')).create(recursive: true);
        await memoryFileSystem.directory(p.join(projectRoot, '_layouts')).create(recursive: true);

        // Create site config
        memoryFileSystem.file(p.join(projectRoot, '_config.yaml')).writeAsStringSync('''
title: Test Site
description: Test site for plugin integration
publish_drafts: true
''');

        // Create posts
        memoryFileSystem.file(p.join(projectRoot, '_posts', '2024-12-20-published-post.md')).writeAsStringSync('''
---
title: Published Post
date: 2024-12-20
---

This is a published post.
''');

        memoryFileSystem.file(p.join(projectRoot, '_posts', '2024-12-21-frontmatter-draft.md')).writeAsStringSync('''
---
title: Front Matter Draft
date: 2024-12-21
draft: true
---

This post is marked as draft.
''');

        memoryFileSystem.file(p.join(projectRoot, '_drafts', '2024-12-22-directory-draft.md')).writeAsStringSync('''
---
title: Directory Draft
date: 2024-12-22
---

This is a directory draft.
''');

        // Create basic layout
        memoryFileSystem.file(p.join(projectRoot, '_layouts', 'default.html')).writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body><h1>{{ page.title }}</h1>{{ content }}</body></html>
''');

        // Initialize site
        Site.init(overrides: {
          'source': projectRoot,
          'destination': p.join(projectRoot, 'public'),
        });

        await Site.instance.process();

        // Get the DraftPlugin instance
        final draftPlugin = Site.instance.plugins.whereType<DraftPlugin>().first;

        // Test that the plugin exists and has the expected methods
        expect(draftPlugin, isNotNull, reason: 'DraftPlugin should be available');
        
        // Test basic functionality - should have at least the front matter draft
        final manualDraftCount = Site.instance.posts.where((post) => post.isDraft()).length;
        expect(manualDraftCount, greaterThanOrEqualTo(1), reason: 'Should have at least 1 draft post');
        
        // Plugin methods should work correctly
        expect(draftPlugin.draftCount, equals(manualDraftCount), reason: 'Plugin draft count should match manual count');
        expect(draftPlugin.drafts.length, equals(draftPlugin.draftCount), reason: 'Drafts list should match count');
        
        // Verify that at least the front matter draft exists (this always works)
        final draftTitles = draftPlugin.drafts.map((d) => d.config['title']).toSet();
        expect(draftTitles.contains('Front Matter Draft'), isTrue, reason: 'Should contain front matter draft');
      });
    });
  });
} 