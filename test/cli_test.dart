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
      test('New Site Command', () async {
        final dirPath = join(tempDir.path, 'test_site');
        await handle_command(['new', 'site', '-d $dirPath']);
      });

      test('New Theme Command', () async {
        final dirPath = join(tempDir.path, 'test_theme');
        await handle_command(['new', 'theme', '-d $dirPath']);
        // assert(fs.directory(dirPath).existsSync());
      });

      test("create from bundle", () async {
        final dirPath = join(tempDir.path, 'bundles');
        final bundles = ["site_template", "blank_template", "theme_template"];
        for (var bundle in bundles) {
          final bundlePath = join(dirPath, bundle);
          createFromBundle(bundlePath, bundle);
          assert(fs.directory(bundlePath).existsSync());
        }
      });
    });

    test('Build Command', () async {
      final String templDir = 'bundle/site_template';
      Site.init(overrides: {
        'source': templDir,
        'destination': 'build',
        'config': ['_config.yml']
      });

      await Site.instance.process();

      final buildDir = fs.directory('$templDir/build');
      assert(buildDir.existsSync());
    });
  });
}
