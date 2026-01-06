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
  group('include tag', () {
    late Directory tempDir;

    setUp(() {
      if (!getIt.isRegistered<FileSystem>()) {
        getIt.registerSingleton<FileSystem>(const LocalFileSystem());
      }
      gengen_fs.fs = const LocalFileSystem();
      tempDir = Directory.systemTemp.createTempSync('gengen-include');

      final source = tempDir.path;
      final destination = p.join(source, 'public');
      Site.resetInstance();
      Site.init(overrides: {'source': source, 'destination': destination});

      final includesDir = Directory(p.join(source, '_includes'))
        ..createSync(recursive: true);
      File(
        p.join(includesDir.path, 'snippet.html'),
      ).writeAsStringSync('Hello {{ include.name }} {{ include.age }}');
      File(p.join(includesDir.path, 'header')).writeAsStringSync('Top Nav');
    });

    tearDown(() {
      Site.resetInstance();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('include resolves variable name and passes args', () async {
      final template = GenGenTempate.r(
        "{% include 'snippet.html' name='GenGen' age='3' %}",
      );

      final result = await template.render();
      expect(result, 'Hello GenGen 3');
    });

    test('include supports unquoted identifiers', () async {
      final template = GenGenTempate.r('{% include header %}');

      final result = await template.render();
      expect(result, 'Top Nav');
    });
  });
}
