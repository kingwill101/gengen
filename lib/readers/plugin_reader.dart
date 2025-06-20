import 'package:gengen/configuration.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/path_extensions.dart';
import 'package:gengen/plugin/loader.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;

class PluginReader {
  PluginReader();

  Future<List<BasePlugin>> read() async {
    final plugins = <BasePlugin>[];
    final sitePlugins = fs.directory(Site.instance.pluginPath);

    plugins.addAll(await dirPlugins(sitePlugins));
    log.info("Plugins loaded: SITE plugins action");

    if (site.theme.loaded) {
      final themePlugins = fs.directory(site.theme.pluginPath);
      plugins.addAll(await dirPlugins(themePlugins));
      log.info("Plugins loaded: THEME plugins action");
    }

    return plugins;
  }

  static Future<List<BasePlugin>> dirPlugins(Directory directory,
      {List<String> whitelist = const []}) async {
    if (!directory.existsSync()) {
      return [];
    }

    var allEntities = directory.listSync(
      recursive: false,
      followLinks: false,
    );

    final plugins = <BasePlugin>[];

    final directories = allEntities
        .whereType<Directory>()
        .where((d) => d.hasFile("config.yaml"));

    for (final directory in directories) {
      final pluginConfigContent =
          readConfigFile(directory.file("config.yaml").path)
              as Map<String, dynamic>;

      final pluginFiles = directory.listSync(recursive: true);
      final pluginAssets = <PluginAsset>[];

      for (var f in pluginFiles) {
        if (FileStat.statSync(f.path).type == FileSystemEntityType.directory) {
          continue;
        }

        if (f.path.contains("config.yaml")) continue;

        //TODO filter out files that are not in the whitelist
        //TODO plugin assets that will end up in the final build
        // should be tagged as Static and added to site static list
        pluginAssets.add(
          PluginAsset(
            name: p.basename(f.path),
            path: f.path,
          ),
        );
      }

      final config = {
        ...pluginConfigContent,
        "path": directory.path,
        "files": pluginAssets.map((a) => a.toJson()).toList(),
      };

      final plugin = PluginMetadata.fromJson(
        config,
      );
      final loader = initializePlugin(plugin);
      plugins.add(loader);
    }

    return plugins;
  }
}
