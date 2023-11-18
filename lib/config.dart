import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

Future<YamlMap> loadConfig({String? directory}) async {
  String configPath = joinAll([directory ?? current, "config.yaml"]);

  var config = File(configPath);
  bool configExists = await config.exists();

  if (!configExists) {
    throw Exception("config.yaml not found in project directory");
  }

  var readConfig = await config.readAsString();
  return loadYaml(readConfig);
}
