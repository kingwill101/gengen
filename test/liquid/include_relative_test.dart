import 'dart:io';

import 'package:file/file.dart' show FileSystem;
import 'package:file/local.dart';
import 'package:gengen/di.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/liquid/template.dart';
import 'package:gengen/site.dart';
import 'package:gengen/drops/document_drop.dart';
import 'package:gengen/models/base.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _BaseStub extends Base {
  _BaseStub(String source) : super('') {
    this.source = source;
  }
}

void main() {
  group('include_relative tag', () {
    late Directory tempDir;
    late Directory destDir;

    setUp(() {
      if (!getIt.isRegistered<FileSystem>()) {
        getIt.registerSingleton<FileSystem>(const LocalFileSystem());
      }
      gengen_fs.fs = const LocalFileSystem();
      tempDir = Directory.systemTemp.createTempSync('gengen-include-relative');
      destDir = Directory.systemTemp.createTempSync('gengen-include-dest');

      Site.resetInstance();
      Site.init(
        overrides: {'source': tempDir.path, 'destination': destDir.path},
      );
    });

    tearDown(() {
      Site.resetInstance();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      if (destDir.existsSync()) {
        destDir.deleteSync(recursive: true);
      }
    });

    test('loads include relative to site source by default', () async {
      final includePath = p.join(tempDir.path, 'partials', 'note.md');
      File(includePath)
        ..createSync(recursive: true)
        ..writeAsStringSync('''---
title: Note
---
Hello {{ site.title }}!
''');

      final template = GenGenTempate.r(
        '{% include_relative partials/note.md %}',
        data: {
          'site': {'title': 'GenGen'},
        },
      );

      final result = await template.render();
      expect(result, contains('Hello GenGen!'));
    });

    test('resolves includes relative to page path', () async {
      final pageDir = Directory(p.join(tempDir.path, 'guides'))
        ..createSync(recursive: true);
      final includePath = p.join(pageDir.path, 'snippet.html');
      File(includePath)
        ..createSync(recursive: true)
        ..writeAsStringSync('Guide snippet');

      final template = GenGenTempate.r(
        '{% include_relative snippet.html %}',
        data: {
          'page': {'path': 'guides/intro.md'},
        },
      );

      final result = await template.render();
      expect(result, contains('Guide snippet'));
    });

    test('uses DocumentDrop source when provided', () async {
      final docDir = Directory(p.join(tempDir.path, 'docs'))
        ..createSync(recursive: true);
      final includePath = p.join(docDir.path, 'doc-snippet.html');
      File(includePath)
        ..createSync(recursive: true)
        ..writeAsStringSync('Doc snippet');

      final stub = _BaseStub(p.join(docDir.path, 'index.md'));
      final template = GenGenTempate.r(
        '{% include_relative doc-snippet.html %}',
        data: {'page': DocumentDrop(stub)},
      );

      final result = await template.render();
      expect(result, contains('Doc snippet'));
    });
  });
}
