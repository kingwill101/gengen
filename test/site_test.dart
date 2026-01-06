import 'package:file/memory.dart';
import 'package:gengen/site.dart';
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

    // Create a basic site structure
    final sourcePath = p.join(projectRoot, 'source');
    final sourceDir = memoryFileSystem.directory(sourcePath);
    sourceDir.createSync(recursive: true);

    final layoutsPath = p.join(sourcePath, '_layouts');
    memoryFileSystem.directory(layoutsPath).createSync(recursive: true);
    memoryFileSystem
        .file(p.join(layoutsPath, 'default.html'))
        .writeAsStringSync('''
<!DOCTYPE html>
<html>
<head>
  <title>{{ page.title }}</title>
</head>
<body>
  <h1>{{ page.title }}</h1>
  {{ content }}
</body>
</html>
''');

    final postsPath = p.join(sourcePath, '_posts');
    memoryFileSystem.directory(postsPath).createSync();
    memoryFileSystem
        .file(p.join(postsPath, '2024-01-01-my-post.md'))
        .writeAsStringSync('''
---
title: My First Post
layout: default
date: 2024-01-01
slug: my-post
---
This is my **{{ page.title }}**.
''');

    final assetsPath = p.join(sourcePath, 'assets');
    memoryFileSystem.directory(assetsPath).createSync();
    memoryFileSystem
        .file(p.join(assetsPath, 'style.css'))
        .writeAsStringSync('body { color: red; }');
  });

  group('Site Tests', () {
    tearDown(() {
      memoryFileSystem.directory(projectRoot).deleteSync(recursive: true);
      Configuration.resetConfig();
    });

    test('should initialize and process a basic site', () async {
      Site.init(
        overrides: {
          'source': p.join(projectRoot, 'source'),
          'destination': p.join(projectRoot, 'public'),
          'permalink': 'pretty',
        },
      );

      await Site.instance.process();

      final publicDir = memoryFileSystem.directory(
        p.join(projectRoot, 'public'),
      );
      expect(publicDir.existsSync(), isTrue);
      final files = publicDir.listSync(recursive: true);
      for (var file in files) {
        print(file.path);
      }

      final postFile = memoryFileSystem.file(
        p.join(
          publicDir.path,
          'posts',
          '2024',
          '01',
          '01',
          'my-post',
          'index.html',
        ),
      );
      expect(postFile.existsSync(), isTrue);

      final postContent = postFile.readAsStringSync();
      expect(postContent, contains('<h1>My First Post</h1>'));
      expect(
        postContent,
        contains('<p>This is my <strong>My First Post</strong>.</p>'),
      );

      final cssFile = memoryFileSystem.file(
        p.join(publicDir.path, 'assets', 'style.css'),
      );
      expect(cssFile.existsSync(), isTrue);
      expect(cssFile.readAsStringSync(), 'body { color: red; }');
    });

    test('clean option should remove existing destination directory', () async {
      final publicPath = p.join(projectRoot, 'public');
      final publicDir = memoryFileSystem.directory(publicPath);
      publicDir.createSync();
      final dummyFile = memoryFileSystem.file(p.join(publicPath, 'stale.html'));
      dummyFile.writeAsStringSync('I should be deleted');
      expect(
        dummyFile.existsSync(),
        isTrue,
        reason: 'Dummy file should exist before process',
      );

      Site.init(
        overrides: {
          'source': p.join(projectRoot, 'source'),
          'destination': publicPath,
          'clean': true,
        },
      );

      await Site.instance.process();

      expect(
        dummyFile.existsSync(),
        isFalse,
        reason: 'Dummy file should be deleted after clean process',
      );

      final newCssFile = memoryFileSystem.file(
        p.join(publicPath, 'assets', 'style.css'),
      );
      expect(
        newCssFile.existsSync(),
        isTrue,
        reason: 'Newly generated files should exist',
      );
    });

    test('exclude option should prevent files from being copied', () async {
      // Create a file that should be excluded
      memoryFileSystem
          .directory(p.join(projectRoot, 'source', 'secret'))
          .createSync();
      memoryFileSystem
          .file(p.join(projectRoot, 'source', 'secret', 'file.txt'))
          .writeAsStringSync('this is a secret');

      Site.init(
        overrides: {
          'source': p.join(projectRoot, 'source'),
          'destination': p.join(projectRoot, 'public'),
          'exclude': ['secret'],
        },
      );

      await Site.instance.process();

      final excludedFile = memoryFileSystem.file(
        p.join(projectRoot, 'public', 'secret', 'file.txt'),
      );
      expect(
        excludedFile.existsSync(),
        isFalse,
        reason: 'Excluded file should not be in the destination',
      );

      final cssFile = memoryFileSystem.file(
        p.join(projectRoot, 'public', 'assets', 'style.css'),
      );
      expect(
        cssFile.existsSync(),
        isTrue,
        reason: 'Other files should still be processed',
      );
    });
  });
}
