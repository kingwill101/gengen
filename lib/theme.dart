import 'dart:io';

import 'package:gengen/configuration.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/path.dart';
import 'package:path/path.dart' as p;

class Theme extends Path {
  String name;
  bool loaded = false;
  String? location;

  Theme.load(
    this.name, {
    String? themePath = "_themes",
    required Configuration config,
  }) {
    this.configuration = config;
    decideLocation(themePath);
  }

  Future<void> decideLocation(String? themePath) async {
    log.fine("Theme: loading  $name");

    var locations = [
      p.join(themePath ?? "", name),
      p.join(p.current, config.get<String>("themes_dir"), name),
    ];

    for (var local in locations) {
      if (FileStat.statSync(local).type == FileSystemEntityType.notFound) {
        continue;
      } else {
        loaded = true;
        location = local;
        break;
      }
    }

    if (!loaded) {
      log.severe("Theme '$name' not found, tried: $locations");
      return;
    }

    var configFile = p.joinAll([location!, "config.yaml"]);
    
    log.info("Theme found in $location");

    if (FileStat.statSync(configFile).type == FileSystemEntityType.notFound) {
      return;
    }
    config.readConfigFile(configFile);
  }

  @override
  String get root => p.canonicalize(location ?? '');
}
