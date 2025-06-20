import 'dart:io';

import 'package:gengen/configuration.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart';

class DataReader {
  DataReader();

  Future<void> read() async {
    var files = await site.reader.filter(site.dataPath);

    final directoryStructure = <String, dynamic>{};
    final extensions = [".json", ".yaml", ".yml"];

    for (var file in files) {
      if (FileStat.statSync(file).type == FileSystemEntityType.directory) {
        continue;
      }
      if (!extensions.contains(extension(file).toLowerCase())) continue;

      final parts = withoutExtension(file)
          .split("_data")[1]
          .split("/")
          .where((p) => p.isNotEmpty)
          .toList();

      Map<String, dynamic> currentMap = directoryStructure;
      for (var i = 0; i < parts.length; i++) {
        if (i == parts.length - 1) {
          currentMap[parts[i]] = readConfigFile(file);
        } else {
          if (!currentMap.containsKey(parts[i])) {
            currentMap[parts[i]] = <String, dynamic>{};
          }
          currentMap = currentMap[parts[i]] as Map<String, dynamic>;
        }
      }
    }
    site.config.add("data", directoryStructure);
  }
}
