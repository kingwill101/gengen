import 'package:file/memory.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Data normalization', () {
    late MemoryFileSystem memoryFileSystem;
    late String projectRoot;

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      gengen_fs.fs = memoryFileSystem;
      projectRoot = memoryFileSystem.currentDirectory.path;
      final sourcePath = p.join(projectRoot, 'source');
      memoryFileSystem.directory(sourcePath).createSync(recursive: true);

      // Basic layout
      final layoutsPath = p.join(sourcePath, '_layouts');
      memoryFileSystem.directory(layoutsPath).createSync(recursive: true);
      memoryFileSystem
          .file(p.join(layoutsPath, 'default.html'))
          .writeAsStringSync('Layout');

      // Site data
      final siteDataPath = p.join(sourcePath, '_data', 'docs');
      memoryFileSystem.directory(siteDataPath).createSync(recursive: true);
      memoryFileSystem
          .file(p.join(siteDataPath, 'navigation.yml'))
          .writeAsStringSync('''
source: site
site_only: true
shared:
  value: site
  site_only: true
''');

      // Theme data
      final themePath = p.join(sourcePath, '_themes', 'my-theme');
      final themeDataPath = p.join(themePath, '_data', 'docs');
      memoryFileSystem.directory(themeDataPath).createSync(recursive: true);
      memoryFileSystem
          .file(p.join(themeDataPath, 'navigation.yml'))
          .writeAsStringSync('''
source: theme
theme_only: true
shared:
  value: theme
  theme_only: true
''');

      // Plugin data
      final pluginPath = p.join(sourcePath, '_plugins', 'my_plugin');
      memoryFileSystem.directory(pluginPath).createSync(recursive: true);
      memoryFileSystem
          .file(p.join(pluginPath, 'config.yaml'))
          .writeAsStringSync(
            'name: MyPlugin\nentrypoint: main.lua:init_plugin',
          );
      memoryFileSystem
          .file(p.join(pluginPath, 'main.lua'))
          .writeAsStringSync('function init_plugin(metadata) return {} end');
      final pluginDataPath = p.join(pluginPath, '_data', 'docs');
      memoryFileSystem.directory(pluginDataPath).createSync(recursive: true);
      memoryFileSystem
          .file(p.join(pluginDataPath, 'navigation.yml'))
          .writeAsStringSync('''
source: plugin
plugin_only: true
shared:
  value: plugin
  plugin_only: true
''');

      Site.init(
        overrides: {
          'source': sourcePath,
          'destination': p.join(projectRoot, 'public'),
          'theme': 'my-theme',
        },
      );
    });

    tearDown(() {
      Site.resetInstance();
    });

    test('merges plugin and theme data with site override', () async {
      await site.read();

      final docs = site.data['docs'] as Map<String, dynamic>;
      final navigation = docs['navigation'] as Map<String, dynamic>;
      final shared = navigation['shared'] as Map<String, dynamic>;

      expect(navigation['source'], equals('site'));
      expect(navigation['plugin_only'], isTrue);
      expect(navigation['theme_only'], isTrue);
      expect(navigation['site_only'], isTrue);

      expect(shared['value'], equals('site'));
      expect(shared['plugin_only'], isTrue);
      expect(shared['theme_only'], isTrue);
      expect(shared['site_only'], isTrue);
    });
  });
}
