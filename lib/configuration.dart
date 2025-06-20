import 'dart:convert';
import 'package:gengen/fs.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/utilities.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart'; // Import for YamlException

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
    "destination": 'public',
    "include": <String>[],
    "exclude": <String>['config.yaml'],
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
    "data": <String, dynamic>{},
    "date_format": "yyyy-MM-dd HH:mm:ss"
  };

  static void resetConfig() {
    _config = {..._defaults};
  }

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
    _config.putIfAbsent('exclude', () => <String>[]);
  }

  void _addDefaultIncludes() {
    _config.putIfAbsent('include', () => <String>[]);
  }

  Map<String, dynamic> _readConfigFile(
    String filePath, [
    Map<String, dynamic> overrides = const {},
  ]) {
    // Modify to not call exit(-1) for testability
    if (!fs.file(filePath).existsSync()) {
      log.warning("Config file '$filePath' not found. Skipping.");
      return {}; // Return empty map if file not found
    }

    dynamic yamlConfig;
    try {
      yamlConfig = parseConfig(readFileSafe(filePath));
    } on YamlException catch (e) {
      log.severe("Malformed config file '$filePath': ${e.message}");
      rethrow; // Re-throw YamlException for testability
    }

    final a = jsonDecode(jsonEncode(yamlConfig));

    _config = deepMerge(_config, a as Map<String, dynamic>);

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

    final configFilesList =
        get<List<String>>("config", overrides: overrides, defaultValue: []) ??
            [];

    for (var config in configFilesList) {
      if ((config.endsWith('.yaml') || config.endsWith('.yml'))) {
        var file = fs.file(join(source, config));
        if (file.existsSync()) {
          resolvedFiles.add(file.path);
          continue;
        }
        // Change from exit(-1) to logging warning for testability
        log.warning("Config '$config' not found. Skipping.");
      } else {
        // Change from exit(-1) to throwing FormatException for testability
        throw FormatException(
            "Invalid config '$config'. Configuration file must end with .yaml or .yml.");
      }
    }

    if (overrides.containsKey('config')) {
      overrides.remove("config");
    }
    
    _readConfigFiles(resolvedFiles);
    
    _config = deepMerge(_config, overrides);
    
    checkIncludeExclude(_config);

    _addDefaultIncludes();
    _addDefaultExcludes();

    if (isRelative(destination)) {
      _config["destination"] = join(source, destination);
    } else {
      _config["destination"] = destination;
    }
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
  // Catch YamlException here if needed, or let it propagate
  return loadYaml(content);
}