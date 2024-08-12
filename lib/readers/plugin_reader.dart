import 'package:gengen/configuration.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/path_extensions.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;

class PluginReader {
  List<Base> unfilteredContent = [];

  PluginReader();

  List<PluginMetadata> read() {
    final plugins = <PluginMetadata>[];

    final sitePlugins = fs.directory(Site.instance.pluginPath);
    plugins.addAll(dirPlugins(sitePlugins));

    if (site.theme.loaded) {
      final themePlugins = fs.directory(site.theme.pluginPath);
      plugins.addAll(dirPlugins(themePlugins));
    }

    return plugins;
  }

  static List<PluginMetadata> dirPlugins(Directory directory,
      {List<String> whitelist = const []}) {
    if (!directory.existsSync()) {
      return [];
    }

    var allEntities = directory.listSync(
      recursive: false,
      followLinks: false,
    );

    final plugins = <PluginMetadata>[];

    final directories = allEntities
        .whereType<Directory>()
        .where((d) => d.hasFile("config.yaml"));

    for (final directory in directories) {
      final pluginConfigContent =
          directory.file("config.yaml").readAsStringSync();

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
        ...parseConfig(pluginConfigContent),
        "path": directory.path,
        "files": pluginAssets.map((a) => a.toJson()).toList(),
      };

      final plugin = PluginMetadata.fromJson(
        config,
      );
      plugins.add(plugin);
    }

    return plugins;
  }
}
