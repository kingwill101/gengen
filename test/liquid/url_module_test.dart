import 'dart:io';

import 'package:file/file.dart' show FileSystem;
import 'package:file/local.dart';
import 'package:gengen/di.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/liquid/modules/url_module.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('UrlModule filters', () {
    late Directory tempDir;
    late Directory destDir;
    late UrlModule module;

    setUp(() {
      if (!getIt.isRegistered<FileSystem>()) {
        getIt.registerSingleton<FileSystem>(const LocalFileSystem());
      }
      gengen_fs.fs = const LocalFileSystem();
      tempDir = Directory.systemTemp.createTempSync('gengen-url-module');
      destDir = Directory(p.join(tempDir.path, 'public'))..createSync();

      Site.resetInstance();
      Site.init(
        overrides: {'source': tempDir.path, 'destination': destDir.path},
      );

      module = UrlModule()..register();
    });

    tearDown(() {
      Site.resetInstance();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('relative_url returns path relative to destination', () {
      final filter = module.filters['relative_url'] as dynamic;
      final input = p.join(destDir.path, 'assets', 'main.css');
      final result = filter(input, const <dynamic>[], <String, dynamic>{});
      expect(result, 'assets/main.css');
    });

    test('absolute_url resolves against destination', () {
      final filter = module.filters['absolute_url'] as dynamic;
      final result = filter(
        'assets/main.css',
        const <dynamic>[],
        <String, dynamic>{},
      );
      expect(result, p.join(destDir.path, 'assets', 'main.css'));
    });

    test('asset_url preserves absolute URLs and normalizes relative paths', () {
      final assetUrl = module.filters['asset_url'] as dynamic;
      expect(
        assetUrl(
          'https://example.com/logo.png',
          const <dynamic>[],
          <String, dynamic>{},
        ),
        'https://example.com/logo.png',
      );

      final result = assetUrl(
        'assets/logo.png',
        const <dynamic>[],
        <String, dynamic>{},
      );
      expect(result, '/assets/logo.png');
    });
  });
}
