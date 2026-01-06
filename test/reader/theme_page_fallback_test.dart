import 'package:file/memory.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/models/theme_page.dart';
import 'package:gengen/reader.dart';
import 'package:gengen/site.dart';
import 'package:gengen/configuration.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Theme page fallback', () {
    late MemoryFileSystem fs;
    late String projectRoot;
    late String sourcePath;

    setUp(() {
      Site.resetInstance();
      Configuration.resetConfig();

      fs = MemoryFileSystem();
      gengen_fs.fs = fs;

      projectRoot = fs.currentDirectory.path;
      sourcePath = p.join(projectRoot, 'site');
      fs.directory(sourcePath).createSync(recursive: true);
      fs
          .directory(p.join(sourcePath, '_themes', 'default'))
          .createSync(recursive: true);
    });

    tearDown(() {
      Site.resetInstance();
      Configuration.resetConfig();
    });

    test('theme index renders when site has no index', () async {
      final themeIndex = p.join(
        sourcePath,
        '_themes',
        'default',
        'content',
        'index.html',
      );
      fs.directory(p.dirname(themeIndex)).createSync(recursive: true);
      fs.file(themeIndex).writeAsStringSync(
        '''---\nlayout: default\n---\nTheme Home''',
      );

      Site.init(
        overrides: {
          'source': sourcePath,
          'destination': p.join(projectRoot, 'public'),
          'theme': 'default',
        },
      );

      final reader = Reader();
      await reader.read();

      expect(
        Site.instance.pages.any((page) => page.source == themeIndex),
        isTrue,
      );
      expect(Site.instance.pages.whereType<ThemePage>().length, equals(1));
    });

    test('site index overrides theme index', () async {
      final themeIndex = p.join(
        sourcePath,
        '_themes',
        'default',
        'content',
        'index.html',
      );
      fs.directory(p.dirname(themeIndex)).createSync(recursive: true);
      fs.file(themeIndex).writeAsStringSync(
        '''---\nlayout: default\n---\nTheme Home''',
      );

      final siteIndex = p.join(sourcePath, 'index.html');
      fs.file(siteIndex).writeAsStringSync(
        '''---\nlayout: default\n---\nSite Home''',
      );

      Site.init(
        overrides: {
          'source': sourcePath,
          'destination': p.join(projectRoot, 'public'),
          'theme': 'default',
        },
      );

      final reader = Reader();
      await reader.read();

      expect(
        Site.instance.pages.any((page) => page.source == siteIndex),
        isTrue,
      );
      expect(
        Site.instance.pages.any((page) => page.source == themeIndex),
        isFalse,
      );
    });

    test('site assets override theme assets with same relative path', () async {
      final themeAsset = p.join(
        sourcePath,
        '_themes',
        'default',
        'assets',
        'css',
        'theme.css',
      );
      fs.directory(p.dirname(themeAsset)).createSync(recursive: true);
      fs.file(themeAsset).writeAsStringSync('body { color: red; }');

      final siteAsset = p.join(sourcePath, 'assets', 'css', 'theme.css');
      fs.directory(p.dirname(siteAsset)).createSync(recursive: true);
      fs.file(siteAsset).writeAsStringSync('body { color: blue; }');

      Site.init(
        overrides: {
          'source': sourcePath,
          'destination': p.join(projectRoot, 'public'),
          'theme': 'default',
        },
      );

      final reader = Reader();
      await reader.read();

      expect(
        Site.instance.staticFiles.any((file) => file.source == siteAsset),
        isTrue,
      );
      expect(
        Site.instance.staticFiles.any((file) => file.source == themeAsset),
        isFalse,
      );
    });
  });
}
