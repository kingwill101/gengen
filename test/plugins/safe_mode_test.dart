import 'dart:async';

import 'package:file/memory.dart';
import 'package:gengen/configuration.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/plugin/lua/lua_plugin.dart';
import 'package:gengen/readers/plugin_reader.dart';
import 'package:gengen/site.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Safe mode', () {
    late MemoryFileSystem fs;
    late String projectRoot;
    late String sourcePath;
    late StreamSubscription<LogRecord> logSubscription;
    late List<LogRecord> records;

    setUp(() {
      Site.resetInstance();
      Configuration.resetConfig();

      fs = MemoryFileSystem();
      gengen_fs.fs = fs;

      projectRoot = fs.currentDirectory.path;
      sourcePath = p.join(projectRoot, 'site');

      fs.directory(sourcePath).createSync(recursive: true);
      fs.directory(p.join(sourcePath, '_plugins')).createSync(recursive: true);
      fs
          .directory(p.join(sourcePath, '_themes', 'default', '_plugins'))
          .createSync(recursive: true);

      records = [];
      Logger.root.level = Level.ALL;
      logSubscription = Logger.root.onRecord.listen(records.add);
    });

    tearDown(() async {
      await logSubscription.cancel();
      Site.resetInstance();
      Configuration.resetConfig();
    });

    void writeLuaPlugin({
      required String dirName,
      required String pluginName,
      bool theme = false,
    }) {
      final basePath = theme
          ? p.join(sourcePath, '_themes', 'default', '_plugins')
          : p.join(sourcePath, '_plugins');
      final pluginDir = p.join(basePath, dirName);
      fs.directory(pluginDir).createSync(recursive: true);

      fs
          .file(p.join(pluginDir, 'config.yaml'))
          .writeAsStringSync(
            'name: $pluginName\nentrypoint: main.lua:init_plugin\n',
          );
      fs
          .file(p.join(pluginDir, 'main.lua'))
          .writeAsStringSync('function init_plugin(metadata) return {} end');
    }

    test('skips lua plugins when safe mode enabled', () async {
      writeLuaPlugin(dirName: 'site-plugin', pluginName: 'site-plugin');
      writeLuaPlugin(
        dirName: 'theme-plugin',
        pluginName: 'theme-plugin',
        theme: true,
      );

      Site.init(
        overrides: {
          'source': sourcePath,
          'destination': p.join(projectRoot, 'public'),
          'theme': 'default',
          'safe': true,
        },
      );

      final plugins = await PluginReader().read();
      expect(plugins.whereType<LuaPlugin>(), isEmpty);

      final safeWarnings = records.where(
        (record) =>
            record.level == Level.WARNING &&
            record.message.contains('Safe mode enabled'),
      );
      expect(safeWarnings.length, equals(2));
      expect(
        safeWarnings.any((record) => record.message.contains('site-plugin')),
        isTrue,
      );
      expect(
        safeWarnings.any((record) => record.message.contains('theme-plugin')),
        isTrue,
      );
    });

    test('allowlisted lua plugins run in safe mode', () async {
      writeLuaPlugin(dirName: 'allowed', pluginName: 'allowed');
      writeLuaPlugin(dirName: 'blocked', pluginName: 'blocked');

      Site.init(
        overrides: {
          'source': sourcePath,
          'destination': p.join(projectRoot, 'public'),
          'theme': 'default',
          'safe': true,
          'safe_plugins': ['allowed'],
        },
      );

      final plugins = await PluginReader.dirPlugins(
        fs.directory(p.join(sourcePath, '_plugins')),
      );

      expect(
        plugins.any((plugin) => plugin.metadata.name == 'allowed'),
        isTrue,
      );
      expect(
        plugins.any((plugin) => plugin.metadata.name == 'blocked'),
        isFalse,
      );
    });
  });
}
