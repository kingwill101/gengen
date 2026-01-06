import 'package:gengen/configuration.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/path_extensions.dart';
import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart';
import 'package:path/path.dart' as p;

class DataReader {
  DataReader();

  Future<void> read() async {
    final data = await readFrom(site.dataPath);
    site.config.add("data", data);
  }

  Future<Map<String, dynamic>> readFrom(String dataRoot) async {
    final directoryStructure = <String, dynamic>{};
    final extensions = [".json", ".yaml", ".yml"];

    if (dataRoot.isEmpty) {
      return directoryStructure;
    }

    final rootDir = fs.directory(dataRoot);
    if (!rootDir.existsSync()) {
      return directoryStructure;
    }

    final entries = rootDir.listSync(recursive: true);
    for (final entry in entries) {
      if (entry is! File) {
        continue;
      }

      final filePath = entry.path;
      if (!extensions.contains(p.extension(filePath).toLowerCase())) {
        continue;
      }

      final relativePath = p.relative(
        p.withoutExtension(filePath),
        from: dataRoot,
      );
      final parts = p
          .split(relativePath)
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.isEmpty) {
        continue;
      }

      Map<String, dynamic> currentMap = directoryStructure;
      for (var i = 0; i < parts.length; i++) {
        if (i == parts.length - 1) {
          currentMap[parts[i]] = readConfigFile(filePath);
        } else {
          if (!currentMap.containsKey(parts[i])) {
            currentMap[parts[i]] = <String, dynamic>{};
          }
          currentMap = currentMap[parts[i]] as Map<String, dynamic>;
        }
      }
    }

    return directoryStructure;
  }

  Future<Map<String, dynamic>> readPluginData(String pluginRoot) async {
    final data = <String, dynamic>{};
    if (pluginRoot.isEmpty) {
      return data;
    }

    final pluginsDir = fs.directory(pluginRoot);
    if (!pluginsDir.existsSync()) {
      return data;
    }

    final dataDirName =
        site.config.get<String>('data_dir', defaultValue: '_data') ?? '_data';
    final pluginDirs =
        pluginsDir
            .listSync(recursive: false)
            .whereType<Directory>()
            .where((dir) => dir.hasFile('config.yaml'))
            .toList()
          ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

    var merged = <String, dynamic>{};
    for (final pluginDir in pluginDirs) {
      final dataRoot = p.join(pluginDir.path, dataDirName);
      if (!fs.directory(dataRoot).existsSync()) {
        continue;
      }

      final pluginData = await readFrom(dataRoot);
      merged = deepMerge(merged, pluginData);
    }

    return merged;
  }
}
