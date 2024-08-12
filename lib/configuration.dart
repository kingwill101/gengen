import 'dart:convert';
import 'dart:io';

import 'package:gengen/fs.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/utilities.dart';
import 'package:path/path.dart';

class Configuration {
  Configuration.read(Map<String, dynamic> cfg) {
    read(cfg);
  }

  const Configuration();

  static Map<String, dynamic> _config = {..._defaults};

  static final Map<String, dynamic> _defaults = {
    "title": "My GenGen Site",
    "url": "http://gengen.local",
    "theme": "default",
    "source": current,
    "destination": joinAll([current, 'public']),
    "include": <String>[],
    "exclude": <String>[],
    "post_dir": "_posts",
    "draft_dir": "_draft",
    "themes_dir": "_themes",
    "layout_dir": "_layouts",
    "plugin_dir": "_plugins",
    "sass_dir": "_sass",
    "data_dir": "_data",
    "asset_dir": "assets",
    "template_dir": "_templates",
    "include_dir": "_includes",
    "block_list": <String>[],
    "markdown_extensions": <String>[],
    'permalink': "date",
    'publish_drafts': false,
    "config": ["_config.yaml"],
    "output": {"posts_dir": "posts"},
    "data": <String, dynamic>{}
  };

  T? get<T>(
    String key, {
    Map<String, dynamic> overrides = const {},
    T? defaultValue,
  }) {
    var entry =
        (overrides[key] ?? _config[key] ?? _defaults[key] ?? defaultValue);

    return entry as T?;
  }

  Map<String, dynamic> get all => _config;

  void add(String key, Map<String, dynamic> value) {
    if (_config[key] is Map) {
      _config[key] = {...(_config[key] as Map<String, dynamic>), ...value};
    } else {
      _config[key] = value;
    }
  }

  String get source => get("source") as String;

  String get destination => get<String>("destination") as String;

  T? call<T>(String config) {
    return get<T>(config);
  }

  void checkIncludeExclude(Map<String, dynamic> config) {
    for (var option in ['include', 'exclude']) {
      if (!config.containsKey(option)) continue;
      if (config[option] is List) continue;

      throw FormatException(
        "'$option' should be set as an array, but was: ${config[option]}.",
      );
    }
  }

  void _addDefaultExcludes() {
    _config.putIfAbsent('excludes', () => <String>[]);
  }

  void _addDefaultIncludes() {
    _config.putIfAbsent('includes', () => <String>[]);
  }

  Map<String, dynamic> _readConfigFile(
    String filePath, [
    Map<String, dynamic> overrides = const {},
  ]) {
    _config = {
      ..._config,
      ...readConfigFile(filePath, overrides) as Map<String, dynamic>
    };

    return _config;
  }

  void _readConfigFiles(
    List<String> files, [
    Map<String, dynamic> overrides = const {},
  ]) {
    for (var file in files) {
      _readConfigFile(file, overrides);
    }
  }

  void read([Map<String, dynamic> configOverride = const {}]) {
    var overrides = {...configOverride};
    List<String> resolvedFiles = [];

    bool hasConfig = overrides.containsKey("config");

    String? siteSource = overrides["source"] as String?;

    if (overrides.containsKey('source') && siteSource != null) {
      if (isRelative(overrides["source"] as String)) {
        _config["source"] = absolute(siteSource);
      } else {
        _config["source"] = siteSource;
      }
      overrides.remove("source");
    }

    String? siteDestination = overrides["destination"] as String?;
    if (overrides.containsKey('destination') && siteDestination != null) {
      if (isRelative(siteDestination)) {
        _config["destination"] = join(source, siteDestination);
      } else {
        _config["destination"] = siteDestination;
      }
      overrides.remove("destination");
    }

    if (hasConfig) {
      List<String> configFiles =
          get<List<String>>("config", overrides: overrides, defaultValue: []) ??
              [];

      for (var config in configFiles) {
        if ((config.endsWith('.yaml') || config.endsWith('.yml'))) {
          var file = fs.file(join(source, config));
          if (file.existsSync()) {
            resolvedFiles.add(file.path);
            continue;
          }
          log.severe("Config $config not found");
          exit(-1);
        } else {
          log.severe("Invalid config $config");
          exit(-1);
        }
      }
    }

    hasConfig ? overrides.remove("config") : ();
    _readConfigFiles(resolvedFiles);
    overrides["config"] = resolvedFiles;
    _config.addAll(overrides);
    _addDefaultIncludes();
    _addDefaultExcludes();
  }
}

Configuration configuration(Map<String, dynamic> overrides) {
  var config = Configuration();
  config.read(overrides);

  return config;
}

dynamic readConfigFile(
  String filePath, [
  Map<String, dynamic> overrides = const {},
]) {
  var yamlConfig = parseConfig(readFileSafe(filePath));
  final a = jsonDecode(jsonEncode(yamlConfig));

  return a;
}

dynamic parseConfig(String content) {
  return parseYaml(content);
}
