import 'package:file/local.dart';
import 'package:gengen/commands/command_runner.dart';
import 'package:gengen/commands/new.dart';
import 'package:gengen/di.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  setUp(() async {
    initLog();
    if (!getIt.isRegistered<FileSystem>()) {
      getIt.registerLazySingleton<FileSystem>(() => LocalFileSystem());
    }
    tempDir = fs.directory(".site_test")..createSync();
  });

  tearDown(() async {
    tempDir.deleteSync(recursive: true);
  });

  group('Command Tests', () {
    group("New Command", () {
      test('New Site Command (default theme)', () async {
        final dirPath = join(tempDir.path, 'test_site');
        await handle_command(['new', 'site', '-d', dirPath]);

        final config = fs.file(join(dirPath, 'config.yaml'));
        expect(config.existsSync(), isTrue);
        final themeDir = fs.directory(join(dirPath, '_themes', 'default'));
        expect(themeDir.existsSync(), isTrue);
      });

      test('New Site Command with Aurora theme', () async {
        final dirPath = join(tempDir.path, 'test_site_aurora');
        await handle_command(['new', 'site', '-d', dirPath, '--theme=aurora']);

        final config = fs.file(join(dirPath, 'config.yaml'));
        final content = config.readAsStringSync();
        expect(content.contains('theme: "aurora"'), isTrue);
        final themeDir = fs.directory(join(dirPath, '_themes', 'aurora'));
        expect(themeDir.existsSync(), isTrue);
      });

      test('New Theme Command', () async {
        final dirPath = join(tempDir.path, 'test_theme');
        await handle_command(['new', 'theme', '-d', dirPath]);
        // assert(fs.directory(dirPath).existsSync());
      });

      test('New Docs Command', () async {
        final dirPath = join(tempDir.path, 'test_docs');
        await handle_command(['new', 'docs', '-d', dirPath]);
      });

      test("create from bundle", () async {
        final dirPath = join(tempDir.path, 'bundles');
        final bundles = [
          "site_template",
          "blank_template",
          "theme_template",
          "theme_default",
          "theme_aurora",
          "docs_template",
        ];
        for (var bundle in bundles) {
          final bundlePath = join(dirPath, bundle);
          createFromBundle(bundlePath, bundle);
          assert(fs.directory(bundlePath).existsSync());
        }
      });
    });

    test('Build Command', () async {
      final dirPath = join(tempDir.path, 'build_site');
      await handle_command(['new', 'site', '-d', dirPath]);

      Site.init(
        overrides: {
          'source': dirPath,
          'destination': join(dirPath, 'public'),
          'config': ['config.yaml'],
        },
      );

      await Site.instance.process();

      final buildDir = fs.directory(join(dirPath, 'public'));
      assert(buildDir.existsSync());
    });
  });
}
