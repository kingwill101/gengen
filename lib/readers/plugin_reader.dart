import 'package:gengen/configuration.dart';
import 'package:gengen/exceptions.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/models/plugin_asset.dart' as plugin_static;
import 'package:gengen/path_extensions.dart';
import 'package:gengen/plugin/loader.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;
import 'package:glob/glob.dart';

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

  static Future<List<BasePlugin>> dirPlugins(
    Directory directory, {
    List<String> whitelist = const [],
  }) async {
    final config = Configuration();
    final safeMode = config.get<bool>('safe', defaultValue: false) ?? false;
    final allowlist = {
      ..._normalizeAllowlist(
        config.get('safe_plugins', defaultValue: const []),
      ),
      ...whitelist.map((entry) => entry.trim()).where((entry) => entry.isNotEmpty),
    };

    if (!directory.existsSync()) {
      return [];
    }

    var allEntities = directory.listSync(recursive: false, followLinks: false);

    final plugins = <BasePlugin>[];

    final directories = allEntities.whereType<Directory>().where(
      (d) => d.hasFile("config.yaml"),
    );

    for (final directory in directories) {
      final pluginConfigContent =
          readConfigFile(directory.file("config.yaml").path)
              as Map<String, dynamic>;

      final pluginDirName = p.basename(directory.path);
      final rawName = pluginConfigContent['name']?.toString() ?? '';
      final pluginConfigName =
          rawName.trim().isEmpty ? pluginDirName : rawName;
      pluginConfigContent['name'] = pluginConfigName;

      final entrypoint =
          pluginConfigContent['entrypoint']?.toString().trim() ?? '';

      if (safeMode &&
          isLuaEntrypoint(entrypoint) &&
          !allowlist.contains(pluginConfigName)) {
        log.warning(
          'Safe mode enabled: skipping Lua plugin "$pluginConfigName" at ${directory.path}.',
        );
        continue;
      }

      final pluginAssets = <PluginAsset>[];
      final pluginName = pluginDirName;

      // Check if files are explicitly listed in config
      final explicitFiles = pluginConfigContent['files'] as List<dynamic>?;

      if (explicitFiles != null) {
        // Use explicitly listed files from config
        for (final fileConfig in explicitFiles) {
          if (fileConfig is Map<String, dynamic>) {
            final fileName = fileConfig['name'] as String?;
            final filePath = fileConfig['path'] as String?;

            if (fileName != null && filePath != null) {
              final resolvedPaths = <String>[];

              void registerAsset(String assetPath, {String? overrideName}) {
                pluginAssets.add(
                  PluginAsset(
                    name: overrideName ?? p.basename(assetPath),
                    path: assetPath,
                  ),
                );

                if (!assetPath.endsWith('.dart') &&
                    !assetPath.endsWith('.lua')) {
                  final staticAsset = plugin_static.PluginStaticAsset(
                    assetPath,
                    pluginName,
                    name: overrideName ?? p.basename(assetPath),
                  );
                  Site.instance.staticFiles.add(staticAsset);
                }
              }

              try {
                final glob = Glob(filePath);
                final matches = await glob
                    .listFileSystem(fs, root: directory.path)
                    .toList();

                for (final match in matches) {
                  if (match is File) {
                    resolvedPaths.add(match.path);
                    registerAsset(match.path);
                  }
                }
              } on FormatException catch (e) {
                log.warning(
                  'Plugin $pluginName: Invalid glob pattern "$filePath" (${e.message}), falling back to literal lookup.',
                );
              }

              if (resolvedPaths.isEmpty) {
                final fullPath = p.join(directory.path, filePath);
                final file = fs.file(fullPath);
                if (file.existsSync()) {
                  resolvedPaths.add(fullPath);
                  registerAsset(fullPath, overrideName: fileName);
                }
              }

              if (resolvedPaths.isEmpty) {
                throw PluginException(
                  'Plugin "$pluginName" declared asset pattern "$filePath" '
                  'but no files were found in ${directory.path}.',
                );
              }
            }
          }
        }
      } else {
        // Fallback to auto-scanning directory files (legacy behavior)
        final pluginFiles = directory.listSync(recursive: true);

        for (var f in pluginFiles) {
          if (FileStat.statSync(f.path).type ==
              FileSystemEntityType.directory) {
            continue;
          }

          if (f.path.contains("config.yaml")) continue;

          // All plugin files need to be in the metadata for the loader
          pluginAssets.add(PluginAsset(name: p.basename(f.path), path: f.path));

          // Only add non-Dart files to static files for copying
          if (!f.path.endsWith('.dart') && !f.path.endsWith('.lua')) {
            final staticAsset = plugin_static.PluginStaticAsset(
              f.path,
              pluginName,
              name: p.basename(f.path),
            );
            Site.instance.staticFiles.add(staticAsset);
          }
        }
      }

      final config = {
        ...pluginConfigContent,
        "path": directory.path,
        "files": pluginAssets.map((a) => a.toJson()).toList(),
      };

      final plugin = PluginMetadata.fromJson(config);
      final loader = initializePlugin(plugin);
      if (loader != null) {
        plugins.add(loader);
      }
    }

    return plugins;
  }

  static Set<String> _normalizeAllowlist(Object? raw) {
    if (raw == null) return {};
    if (raw is String) {
      return raw
          .split(',')
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toSet();
    }
    if (raw is Iterable) {
      return raw
          .map((entry) => entry?.toString().trim() ?? '')
          .where((entry) => entry.isNotEmpty)
          .toSet();
    }
    return {};
  }
}
