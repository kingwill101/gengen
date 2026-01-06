import 'package:file/memory.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('CollectionReader', () {
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
    });

    tearDown(() {
      Site.resetInstance();
    });

    test(
      'loads collections from list config and skips special labels',
      () async {
        final docsPath = p.join(sourcePath, '_docs');
        memoryFileSystem.directory(docsPath).createSync(recursive: true);
        memoryFileSystem.file(p.join(docsPath, 'intro.md')).writeAsStringSync(
          '''---
title: Intro
---
Hello''',
        );

        Site.init(
          overrides: {
            'source': sourcePath,
            'destination': p.join(projectRoot, 'public'),
            'theme': 'default',
            'collections': ['docs', 'posts', 'data', ''],
          },
        );

        await Site.instance.read();

        expect(Site.instance.collections.keys, contains('docs'));
        expect(Site.instance.collections.keys, isNot(contains('posts')));
        expect(Site.instance.collections.keys, isNot(contains('data')));
        expect(Site.instance.collections.length, equals(1));
      },
    );

    test('skips _index files and separates docs from static files', () async {
      final guidesPath = p.join(sourcePath, '_guides');
      memoryFileSystem.directory(guidesPath).createSync(recursive: true);
      memoryFileSystem.file(p.join(guidesPath, '_index.md')).writeAsStringSync(
        '''---
title: Index
---
Skip me''',
      );
      memoryFileSystem.file(p.join(guidesPath, 'intro.md')).writeAsStringSync(
        '''---
title: Intro
---
Welcome''',
      );
      memoryFileSystem
          .file(p.join(guidesPath, 'asset.txt'))
          .writeAsStringSync('Static asset');

      Site.init(
        overrides: {
          'source': sourcePath,
          'destination': p.join(projectRoot, 'public'),
          'theme': 'default',
          'collections': {
            'guides': {'output': true},
          },
        },
      );

      await Site.instance.read();

      final guides = Site.instance.collections['guides']!;
      expect(guides.docs.length, equals(1));
      expect(guides.docs.first.config['title'], equals('Intro'));
      expect(guides.files.length, equals(1));
      expect(guides.files.first.name, endsWith('asset.txt'));
    });

    test('respects published flag for collection docs', () async {
      final docsPath = p.join(sourcePath, '_docs');
      memoryFileSystem.directory(docsPath).createSync(recursive: true);
      memoryFileSystem.file(p.join(docsPath, 'draft.md')).writeAsStringSync(
        '''---
title: Draft
published: false
---
Hidden''',
      );
      memoryFileSystem.file(p.join(docsPath, 'public.md')).writeAsStringSync(
        '''---
title: Public
---
Visible''',
      );

      Site.init(
        overrides: {
          'source': sourcePath,
          'destination': p.join(projectRoot, 'public'),
          'theme': 'default',
          'collections': {
            'docs': {'output': true},
          },
          'unpublished': false,
        },
      );

      await Site.instance.read();

      final docs = Site.instance.collections['docs']!;
      expect(docs.docs.length, equals(1));
      expect(docs.docs.first.config['title'], equals('Public'));

      Site.resetInstance();
      Site.init(
        overrides: {
          'source': sourcePath,
          'destination': p.join(projectRoot, 'public'),
          'theme': 'default',
          'collections': {
            'docs': {'output': true},
          },
          'unpublished': true,
        },
      );

      await Site.instance.read();

      final docsWithUnpublished = Site.instance.collections['docs']!;
      expect(docsWithUnpublished.docs.length, equals(2));
    });
  });
}
