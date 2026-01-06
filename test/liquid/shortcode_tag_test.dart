import 'dart:io';

import 'package:file/file.dart' show FileSystem;
import 'package:file/local.dart';
import 'package:gengen/di.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/liquid/template.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('ShortcodeTag', () {
    late Directory tempDir;

    setUp(() {
      if (!getIt.isRegistered<FileSystem>()) {
        getIt.registerSingleton<FileSystem>(const LocalFileSystem());
      }
      gengen_fs.fs = const LocalFileSystem();
      tempDir = Directory.systemTemp.createTempSync('gengen-shortcode-tag');

      Site.resetInstance();
      Site.init(
        overrides: {
          'source': tempDir.path,
          'destination': p.join(tempDir.path, 'public'),
        },
      );

      final includesDir = Directory(
        p.join(tempDir.path, '_includes', 'shortcodes'),
      )..createSync(recursive: true);
      File(
        p.join(includesDir.path, 'card.html'),
      ).writeAsStringSync('Card {{ title }}');
    });

    tearDown(() {
      Site.resetInstance();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('renders shortcode via render tag', () async {
      final template = GenGenTempate.r(
        "{% shortcode 'shortcodes/card.html' title='Hello' %}",
      );

      final result = await template.render();
      expect(result.trim(), 'Card Hello');
    });
  });
}
