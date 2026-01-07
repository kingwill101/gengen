import 'package:file/file.dart' show FileSystem;
import 'package:file/memory.dart';
import 'package:gengen/di.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/layout.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Layout', () {
    late MemoryFileSystem memoryFileSystem;
    late String rootPath;

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      if (!getIt.isRegistered<FileSystem>()) {
        getIt.registerSingleton<FileSystem>(memoryFileSystem);
      }
      gengen_fs.fs = memoryFileSystem;
      rootPath = '/site';
      memoryFileSystem.directory(rootPath).createSync(recursive: true);

      Site.resetInstance();
      Site.init(
        overrides: {
          'source': rootPath,
          'destination': p.join(rootPath, 'public'),
        },
      );
    });

    tearDown(() {
      Site.resetInstance();
    });

    test('parses front matter and content', () {
      final layoutPath = p.join(rootPath, '_layouts', 'default.html');
      memoryFileSystem
          .directory(p.dirname(layoutPath))
          .createSync(recursive: true);
      memoryFileSystem.file(layoutPath).writeAsStringSync('''---
title: Base Layout
---
<div>{{ content }}</div>
''');

      final layout = Layout(layoutPath, 'default.html');

      expect(layout.ext, '.html');
      expect(layout.content.trim(), '<div>{{ content }}</div>');
      expect(layout.data['title'], 'Base Layout');
    });

    test('onFileChange refreshes content', () {
      final layoutPath = p.join(rootPath, '_layouts', 'post.html');
      memoryFileSystem
          .directory(p.dirname(layoutPath))
          .createSync(recursive: true);
      final file = memoryFileSystem.file(layoutPath)
        ..writeAsStringSync('<div>Old</div>');

      final layout = Layout(layoutPath, 'post.html');
      expect(layout.content.trim(), '<div>Old</div>');

      file.writeAsStringSync('<div>New</div>');
      layout.parse(); // Re-parse to pick up changes

      expect(layout.content.trim(), '<div>New</div>');
    });

    test('toString includes path info', () {
      final layoutPath = p.join(rootPath, '_layouts', 'header.html');
      memoryFileSystem
          .directory(p.dirname(layoutPath))
          .createSync(recursive: true);
      memoryFileSystem.file(layoutPath).writeAsStringSync('<header>H</header>');

      final layout = Layout(layoutPath, 'header.html');
      expect(layout.toString(), contains(layoutPath));
    });
  });
}
