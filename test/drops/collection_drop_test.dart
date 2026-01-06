import 'dart:io';

import 'package:file/file.dart' show FileSystem;
import 'package:file/local.dart';
import 'package:gengen/di.dart';
import 'package:gengen/drops/collection_drop.dart';
import 'package:gengen/drops/static_file_drop.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/models/base.dart';
import 'package:gengen/models/collection.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _FakeBase extends Base {
  _FakeBase({
    required String sourcePath,
    required this.fakeLink,
    required this.fakeRelativePath,
    required this.fakeCollectionLabel,
  }) : super('') {
    source = sourcePath;
  }

  final String fakeLink;
  final String fakeRelativePath;
  final String fakeCollectionLabel;

  @override
  String link() => fakeLink;

  @override
  String get relativePath => fakeRelativePath;

  @override
  String get collectionLabel => fakeCollectionLabel;
}

void main() {
  group('CollectionDrop', () {
    late Directory tempDir;

    setUp(() {
      if (!getIt.isRegistered<FileSystem>()) {
        getIt.registerSingleton<FileSystem>(const LocalFileSystem());
      }
      gengen_fs.fs = const LocalFileSystem();
      tempDir = Directory.systemTemp.createTempSync('gengen-collection-drop');
      Site.resetInstance();
      Site.init(overrides: {'source': tempDir.path});
    });

    tearDown(() {
      Site.resetInstance();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('exposes collection metadata, docs, and files', () {
      final doc = _FakeBase(
        sourcePath: p.join(tempDir.path, '_guides', 'intro.md'),
        fakeLink: 'guides/intro/index.html',
        fakeRelativePath: '_guides/intro.md',
        fakeCollectionLabel: 'guides',
      );
      final file = _FakeBase(
        sourcePath: p.join(tempDir.path, '_guides', 'snippet.html'),
        fakeLink: 'guides/snippet.html',
        fakeRelativePath: '_guides/snippet.html',
        fakeCollectionLabel: 'guides',
      );

      final collection = ContentCollection(
        label: 'guides',
        metadata: {'output': true, 'description': 'Guide pages'},
        docs: [doc],
        files: [file],
      );

      final drop = CollectionDrop(collection);
      expect(drop.label, 'guides');
      expect(drop.attrs['output'], isTrue);
      expect(drop.attrs['description'], 'Guide pages');
      expect((drop.attrs['docs'] as List).length, 1);
      expect((drop.attrs['files'] as List).length, 1);
      expect(drop.attrs['relative_directory'], '_guides');
      expect(drop.attrs['directory'], p.join(tempDir.path, '_guides'));
    });
  });

  group('StaticFileDrop', () {
    test('normalizes urls for index files', () {
      final base = _FakeBase(
        sourcePath: '/tmp/assets/index.html',
        fakeLink: 'assets/index.html',
        fakeRelativePath: 'assets/index.html',
        fakeCollectionLabel: '',
      );

      final drop = StaticFileDrop(base);
      expect(drop.attrs['url'], '/assets/');
      expect(drop.attrs['basename'], 'index');
      expect(drop.attrs['extname'], '.html');
    });

    test('returns url for non-index files', () {
      final base = _FakeBase(
        sourcePath: '/tmp/images/logo.png',
        fakeLink: 'images/logo.png',
        fakeRelativePath: 'images/logo.png',
        fakeCollectionLabel: '',
      );

      final drop = StaticFileDrop(base);
      expect(drop.attrs['url'], '/images/logo.png');
    });
  });
}
