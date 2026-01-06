import 'dart:io';

import 'package:file/file.dart' show FileSystem;
import 'package:file/local.dart';
import 'package:gengen/di.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/models/theme_content_asset.dart';
import 'package:gengen/models/theme_page.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Theme content models', () {
    late Directory tempDir;

    setUp(() {
      if (!getIt.isRegistered<FileSystem>()) {
        getIt.registerSingleton<FileSystem>(const LocalFileSystem());
      }
      gengen_fs.fs = const LocalFileSystem();
      tempDir = Directory.systemTemp.createTempSync('gengen-theme-content');
      Site.resetInstance();
      Site.init(
        overrides: {
          'source': tempDir.path,
          'destination': p.join(tempDir.path, 'public'),
        },
      );
    });

    tearDown(() {
      Site.resetInstance();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('ThemeContentAsset uses contentRoot-relative paths', () {
      final assetPath = p.join(tempDir.path, 'assets', 'logo.txt');
      File(assetPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('logo');

      final asset = ThemeContentAsset(assetPath, contentRoot: tempDir.path);

      expect(asset.name, 'assets/logo.txt');
      expect(asset.relativePath, 'assets/logo.txt');
    });

    test('ThemePage normalizes pathPlaceholder for nested pages', () {
      final pagePath = p.join(tempDir.path, 'guides', 'index.md');
      File(pagePath)
        ..createSync(recursive: true)
        ..writeAsStringSync('''---
title: Guide
---
Hello
''');

      final page = ThemePage(pagePath, contentRoot: tempDir.path);

      expect(page.name, 'guides/index.md');
      expect(page.relativePath, 'guides/index.md');
      expect(page.pathPlaceholder, 'guides');
    });

    test('ThemePage pathPlaceholder is empty for root index', () {
      final pagePath = p.join(tempDir.path, 'index.md');
      File(pagePath)
        ..createSync(recursive: true)
        ..writeAsStringSync('''---
title: Home
---
Hi
''');

      final page = ThemePage(pagePath, contentRoot: tempDir.path);

      expect(page.pathPlaceholder, '');
    });
  });
}
