import 'package:file/file.dart' show FileSystem;
import 'package:file/memory.dart';
import 'package:gengen/di.dart';
import 'package:gengen/front_matter_defaults.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/site.dart';
import 'package:test/test.dart';

void main() {
  group('FrontMatterDefaults', () {
    setUp(() {
      if (!getIt.isRegistered<FileSystem>()) {
        getIt.registerSingleton<FileSystem>(MemoryFileSystem());
      }
      gengen_fs.fs = MemoryFileSystem();
      Site.resetInstance();
      Site.init(
        overrides: {
          'source': '/site',
          'destination': '/site/public',
          'collections_dir': 'collections',
        },
      );
    });

    tearDown(() {
      Site.resetInstance();
    });

    test('resolves defaults by path and type with glob support', () {
      final defaults = FrontMatterDefaults([
        {
          'scope': {'path': '', 'type': 'pages'},
          'values': {'layout': 'page'},
        },
        {
          'scope': {'path': 'guides', 'type': 'pages'},
          'values': {'section': 'guides'},
        },
        {
          'scope': {'path': 'guides/*'},
          'values': {'tag': 'guide'},
        },
      ]);

      final resolved = defaults.resolve(
        paths: ['guides/intro.md', 'guides/intro'],
        type: 'pages',
      );

      expect(resolved['layout'], 'page');
      expect(resolved['section'], 'guides');
      expect(resolved['tag'], 'guide');
    });

    test('respects collections_dir when matching scoped paths', () {
      final defaults = FrontMatterDefaults([
        {
          'scope': {'path': 'collections/tutorials', 'type': 'tutorials'},
          'values': {'layout': 'tutorial'},
        },
      ]);

      final resolved = defaults.resolve(
        paths: ['tutorials/intro.md', 'intro'],
        type: 'tutorials',
      );

      expect(resolved['layout'], 'tutorial');
    });

    test('ignores mismatched types', () {
      final defaults = FrontMatterDefaults([
        {
          'scope': {'path': 'guides', 'type': 'posts'},
          'values': {'layout': 'post'},
        },
      ]);

      final resolved = defaults.resolve(
        paths: ['guides/intro.md'],
        type: 'pages',
      );

      expect(resolved, isEmpty);
    });
  });
}
