import 'dart:io';

import 'package:file/local.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/plugin/builtin/tailwind.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('TailwindPlugin integration', () {
    late Directory tempDir;

    setUp(() {
      gengen_fs.fs = LocalFileSystem();
      tempDir = Directory.systemTemp.createTempSync('gengen-tailwind-');
    });

    tearDown(() {
      Site.resetInstance();
      gengen_fs.fs = LocalFileSystem();
      tempDir.deleteSync(recursive: true);
    });

    test('generates output when input and executable exist', () async {
      final source = tempDir.path;
      final inputPath = p.join(source, 'assets', 'css', 'tailwind.css');
      final outputPath = p.join(
        source,
        'public',
        'assets',
        'css',
        'styles.css',
      );
      final execPath = p.join(source, 'tailwindcss');

      Directory(p.dirname(inputPath)).createSync(recursive: true);
      File(inputPath).writeAsStringSync('@tailwind utilities;');

      File(execPath).writeAsStringSync('''#!/usr/bin/env sh
output=""
while [ "\$#" -gt 0 ]; do
  case "\$1" in
    -i) shift 2;;
    -o) output="\$2"; shift 2;;
    *) shift;;
  esac
done
if [ -n "\$output" ]; then
  echo "/* generated */" > "\$output"
fi
''');
      Process.runSync('chmod', ['+x', execPath]);

      Site.init(
        overrides: {'source': source, 'destination': p.join(source, 'public')},
      );

      final plugin = TailwindPlugin(tailwindPath: execPath);
      await plugin.afterRender();

      final outputFile = File(outputPath);
      expect(outputFile.existsSync(), isTrue);
      expect(outputFile.readAsStringSync(), contains('generated'));
    });

    test('skips when input file is missing', () async {
      final source = tempDir.path;
      final outputPath = p.join(
        source,
        'public',
        'assets',
        'css',
        'styles.css',
      );
      final execPath = p.join(source, 'tailwindcss');

      File(execPath).writeAsStringSync('#!/usr/bin/env sh\nexit 0');
      Process.runSync('chmod', ['+x', execPath]);

      Site.init(
        overrides: {'source': source, 'destination': p.join(source, 'public')},
      );

      final plugin = TailwindPlugin(tailwindPath: execPath);
      await plugin.afterRender();

      expect(File(outputPath).existsSync(), isFalse);
    });

    test('skips when executable is missing', () async {
      final source = tempDir.path;
      final inputPath = p.join(source, 'assets', 'css', 'tailwind.css');
      final outputPath = p.join(
        source,
        'public',
        'assets',
        'css',
        'styles.css',
      );

      Directory(p.dirname(inputPath)).createSync(recursive: true);
      File(inputPath).writeAsStringSync('@tailwind utilities;');

      Site.init(
        overrides: {'source': source, 'destination': p.join(source, 'public')},
      );

      final plugin = TailwindPlugin(tailwindPath: p.join(source, 'missing'));
      await plugin.afterRender();

      expect(File(outputPath).existsSync(), isFalse);
    });
  });
}
