import 'package:file/memory.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Aliases Tests', () {
    late MemoryFileSystem memoryFileSystem;
    late String projectRoot;
    late Site site;

    setUpAll(() {
      // Reset the Site singleton before this test group starts
      Site.resetInstance();
    });

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      gengen_fs.fs = memoryFileSystem;
      projectRoot = memoryFileSystem.currentDirectory.path;
      final sourcePath = p.join(projectRoot, 'source');
      final publicPath = p.join(projectRoot, 'public');
      
      memoryFileSystem.directory(sourcePath).createSync(recursive: true);
      memoryFileSystem.directory(publicPath).createSync(recursive: true);

      // Create basic layout
      final layoutsPath = p.join(sourcePath, '_layouts');
      memoryFileSystem.directory(layoutsPath).createSync(recursive: true);
      memoryFileSystem
          .file(p.join(layoutsPath, 'default.html'))
          .writeAsStringSync('<!DOCTYPE html><html><body>{{ content }}</body></html>');

      Site.init(overrides: {
        'source': sourcePath,
        'destination': publicPath,
      });
      site = Site.instance;
    });

    tearDown(() {
      Site.resetInstance();
    });

    test('should create alias files for pages with single alias', () async {
      // Create a page with one alias
      final aboutPath = p.join(site.config.source, 'about.md');
      memoryFileSystem.file(aboutPath).writeAsStringSync('''---
title: About Us
layout: default
permalink: /about/
aliases: [company-info.html]
---

# About Our Company
This is our about page.
''');

      await site.process();
      await site.write();

      // Check main page exists
      final mainPagePath = p.join(site.destination.path, 'about', 'index.html');
      expect(memoryFileSystem.file(mainPagePath).existsSync(), isTrue);

      // Check alias file exists
      final aliasPath = p.join(site.destination.path, 'company-info.html');
      expect(memoryFileSystem.file(aliasPath).existsSync(), isTrue);

      // Check content is identical
      final mainContent = memoryFileSystem.file(mainPagePath).readAsStringSync();
      final aliasContent = memoryFileSystem.file(aliasPath).readAsStringSync();
      expect(aliasContent, equals(mainContent));
      
      // Check content includes the processed markdown
      expect(mainContent, contains('<h1 id="about-our-company">About Our Company</h1>'));
      expect(mainContent, contains('This is our about page.'));
    });

    test('should create multiple alias files for pages with multiple aliases', () async {
      // Create a page with multiple aliases
      final contactPath = p.join(site.config.source, 'contact.md');
      memoryFileSystem.file(contactPath).writeAsStringSync('''---
title: Contact Us
layout: default
permalink: /contact/
aliases:
  - contact-us.html
  - get-in-touch.html
  - support.html
---

# Contact Information
Get in touch with us!
''');

      await site.process();
      await site.write();

      // Check main page exists
      final mainPagePath = p.join(site.destination.path, 'contact', 'index.html');
      expect(memoryFileSystem.file(mainPagePath).existsSync(), isTrue);

      // Check all alias files exist
      final aliases = ['contact-us.html', 'get-in-touch.html', 'support.html'];
      final mainContent = memoryFileSystem.file(mainPagePath).readAsStringSync();
      
      for (final alias in aliases) {
        final aliasPath = p.join(site.destination.path, alias);
        expect(memoryFileSystem.file(aliasPath).existsSync(), isTrue, 
               reason: 'Alias file $alias should exist');
        
        final aliasContent = memoryFileSystem.file(aliasPath).readAsStringSync();
        expect(aliasContent, equals(mainContent),
               reason: 'Alias $alias should have identical content to main page');
      }
    });

    test('should create alias files with directory structure', () async {
      // Create a page with aliases that include directory paths
      final servicesPath = p.join(site.config.source, 'services.md');
      memoryFileSystem.file(servicesPath).writeAsStringSync('''---
title: Our Services
layout: default
permalink: /services/
aliases:
  - old-site/services.html
  - company/what-we-do.html
  - info/services-offered.html
---

# Our Services
We offer various services.
''');

      await site.process();
      await site.write();

      // Check main page exists
      final mainPagePath = p.join(site.destination.path, 'services', 'index.html');
      expect(memoryFileSystem.file(mainPagePath).existsSync(), isTrue);

      // Check alias files with directory structure exist
      final aliases = [
        'old-site/services.html',
        'company/what-we-do.html', 
        'info/services-offered.html'
      ];
      
      final mainContent = memoryFileSystem.file(mainPagePath).readAsStringSync();
      
      for (final alias in aliases) {
        final aliasPath = p.join(site.destination.path, alias);
        expect(memoryFileSystem.file(aliasPath).existsSync(), isTrue,
               reason: 'Alias file $alias should exist');
        
        final aliasContent = memoryFileSystem.file(aliasPath).readAsStringSync();
        expect(aliasContent, equals(mainContent),
               reason: 'Alias $alias should have identical content to main page');
      }
    });

    test('should create alias files for posts', () async {
      // Create posts directory
      final postsPath = p.join(site.config.source, '_posts');
      memoryFileSystem.directory(postsPath).createSync(recursive: true);
      
      // Create a post with aliases
      final postPath = p.join(postsPath, '2024-01-15-my-post.md');
      memoryFileSystem.file(postPath).writeAsStringSync('''---
title: My Awesome Post
date: 2024-01-15
layout: default
permalink: /blog/my-awesome-post/
aliases:
  - 2024/01/15/my-post.html
  - old-blog/awesome-post.html
---

# My Awesome Post
This is a great blog post!
''');

      await site.process();
      await site.write();

      // Check main post exists
      final mainPostPath = p.join(site.destination.path, 'blog', 'my-awesome-post', 'index.html');
      expect(memoryFileSystem.file(mainPostPath).existsSync(), isTrue);

      // Check alias files exist
      final aliases = [
        '2024/01/15/my-post.html',
        'old-blog/awesome-post.html'
      ];
      
      final mainContent = memoryFileSystem.file(mainPostPath).readAsStringSync();
      
      for (final alias in aliases) {
        final aliasPath = p.join(site.destination.path, alias);
        expect(memoryFileSystem.file(aliasPath).existsSync(), isTrue,
               reason: 'Post alias file $alias should exist');
        
        final aliasContent = memoryFileSystem.file(aliasPath).readAsStringSync();
        expect(aliasContent, equals(mainContent),
               reason: 'Post alias $alias should have identical content to main post');
      }
    });

    test('should handle aliases with leading slashes', () async {
      // Create a page with aliases that have leading slashes
      final teamPath = p.join(site.config.source, 'team.md');
      memoryFileSystem.file(teamPath).writeAsStringSync('''---
title: Our Team
layout: default
permalink: /team/
aliases:
  - /about-us/team.html
  - /company/people.html
---

# Our Team
Meet our amazing team!
''');

      await site.process();
      await site.write();

      // Check main page exists
      final mainPagePath = p.join(site.destination.path, 'team', 'index.html');
      expect(memoryFileSystem.file(mainPagePath).existsSync(), isTrue);

      // Check alias files exist (leading slashes should be removed)
      final aliases = [
        'about-us/team.html',
        'company/people.html'
      ];
      
      final mainContent = memoryFileSystem.file(mainPagePath).readAsStringSync();
      
      for (final alias in aliases) {
        final aliasPath = p.join(site.destination.path, alias);
        expect(memoryFileSystem.file(aliasPath).existsSync(), isTrue,
               reason: 'Alias file $alias should exist (leading slash removed)');
        
        final aliasContent = memoryFileSystem.file(aliasPath).readAsStringSync();
        expect(aliasContent, equals(mainContent),
               reason: 'Alias $alias should have identical content to main page');
      }
    });

    test('should handle pages without aliases gracefully', () async {
      // Create a page without aliases
      final noAliasPath = p.join(site.config.source, 'no-alias.md');
      memoryFileSystem.file(noAliasPath).writeAsStringSync('''---
title: No Alias Page
layout: default
permalink: /no-alias/
---

# No Alias Page
This page has no aliases.
''');

      await site.process();
      await site.write();

      // Check main page exists
      final mainPagePath = p.join(site.destination.path, 'no-alias', 'index.html');
      expect(memoryFileSystem.file(mainPagePath).existsSync(), isTrue);

      // Check content is processed correctly
      final content = memoryFileSystem.file(mainPagePath).readAsStringSync();
      expect(content, contains('<h1 id="no-alias-page">No Alias Page</h1>'));
      expect(content, contains('This page has no aliases.'));
    });

         test('should use html extension for alias files', () async {
       // Create a page with various alias file extensions
       // Note: GenGen automatically sets alias extensions to match the source file (.html)
       final extensionsPath = p.join(site.config.source, 'extensions.md');
       memoryFileSystem.file(extensionsPath).writeAsStringSync('''---
title: Extension Test
layout: default
permalink: /extensions/
aliases:
  - old-page.html
  - legacy.htm
  - backup.php
---

# Extension Test
Testing different file extensions in aliases.
''');

       await site.process();
       await site.write();

       // Check main page exists
       final mainPagePath = p.join(site.destination.path, 'extensions', 'index.html');
       expect(memoryFileSystem.file(mainPagePath).existsSync(), isTrue);

       // Check alias files - GenGen converts all to .html extension to match source
       final aliases = [
         'old-page.html',
         'legacy.html',  // .htm becomes .html
         'backup.html'   // .php becomes .html
       ];
       
       final mainContent = memoryFileSystem.file(mainPagePath).readAsStringSync();
       
       for (final alias in aliases) {
         final aliasPath = p.join(site.destination.path, alias);
         expect(memoryFileSystem.file(aliasPath).existsSync(), isTrue,
                reason: 'Alias file $alias should exist with .html extension');
         
         final aliasContent = memoryFileSystem.file(aliasPath).readAsStringSync();
         expect(aliasContent, equals(mainContent),
                reason: 'Alias $alias should have identical content to main page');
       }
     });

    test('should handle empty aliases array', () async {
      // Create a page with empty aliases array
      final emptyAliasPath = p.join(site.config.source, 'empty-alias.md');
      memoryFileSystem.file(emptyAliasPath).writeAsStringSync('''---
title: Empty Alias Test
layout: default
permalink: /empty-alias/
aliases: []
---

# Empty Alias Test
This page has an empty aliases array.
''');

      await site.process();
      await site.write();

      // Check main page exists
      final mainPagePath = p.join(site.destination.path, 'empty-alias', 'index.html');
      expect(memoryFileSystem.file(mainPagePath).existsSync(), isTrue);

      // Check content is processed correctly
      final content = memoryFileSystem.file(mainPagePath).readAsStringSync();
      expect(content, contains('<h1 id="empty-alias-test">Empty Alias Test</h1>'));
    });
  });
} 