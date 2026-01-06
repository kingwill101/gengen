import 'package:file/memory.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/logging.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  initLog();

  group('Collections', () {
    late MemoryFileSystem memoryFileSystem;
    late String projectRoot;
    late String sourcePath;

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      gengen_fs.fs = memoryFileSystem;
      projectRoot = memoryFileSystem.currentDirectory.path;
      sourcePath = p.join(projectRoot, 'source');
      memoryFileSystem.directory(sourcePath).createSync(recursive: true);

      // Minimal theme/layout structure
      final themeLayoutsPath = p.join(
        sourcePath,
        '_themes',
        'default',
        '_layouts',
      );
      memoryFileSystem.directory(themeLayoutsPath).createSync(recursive: true);
      memoryFileSystem
          .file(p.join(themeLayoutsPath, 'default.html'))
          .writeAsStringSync('{{ content }}');

      // Collection content
      final docsPath = p.join(sourcePath, '_docs');
      memoryFileSystem.directory(docsPath).createSync(recursive: true);
      memoryFileSystem.file(p.join(docsPath, 'intro.md')).writeAsStringSync(
        '''---
title: Intro
---
Welcome to the docs.''',
      );
    });

    tearDown(() {
      Site.resetInstance();
    });

    test('reads configured collections and exposes Liquid data', () async {
      Site.init(
        overrides: {
          'source': sourcePath,
          'destination': p.join(projectRoot, 'public'),
          'theme': 'default',
          'collections': {
            'docs': {'output': true, 'permalink': '/:collection/:path/'},
          },
          'defaults': [
            {
              'scope': {'type': 'docs'},
              'values': {'layout': 'doc'},
            },
          ],
        },
      );

      final site = Site.instance;
      await site.read();

      expect(site.collections.containsKey('docs'), isTrue);
      final docs = site.collections['docs']!;
      expect(docs.docs.length, equals(1));

      final item = docs.docs.first;
      expect(item.config['title'], equals('Intro'));
      expect(item.config['layout'], equals('doc'));
      expect(item.link(), equals('docs/intro/index.html'));

      final context = site.map;
      final collections = context['collections'] as List;
      final docsList = context['docs'] as List;
      expect(docsList.first.invoke(const Symbol('title')), equals('Intro'));
      expect(collections.length, equals(1));
      final alias = context['docs'] as List;
      expect(alias.length, equals(1));
    });

    test('does not write output when collection output is false', () async {
      Site.init(
        overrides: {
          'source': sourcePath,
          'destination': p.join(projectRoot, 'public'),
          'theme': 'default',
          'collections': {
            'docs': {'output': false, 'permalink': '/:collection/:path/'},
          },
        },
      );

      final site = Site.instance;
      await site.process();

      final docs = site.collections['docs']!;
      expect(docs.docs.length, equals(1));
      final item = docs.docs.first;
      final outputPath = p.join(site.destination.path, item.link());
      expect(memoryFileSystem.file(outputPath).existsSync(), isFalse);
    });
  });
}
