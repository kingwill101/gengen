import 'dart:io';

import 'package:gengen/logging.dart';
import 'package:gengen/utilities.dart';
import 'package:path/path.dart';

class Configuration {
  Configuration.read(Map<String, dynamic> cfg) {
    read(cfg);
  }

  Configuration();

  Map<String, dynamic> _config = {..._defaults};

  static final Map<String, dynamic> _defaults = {
    "title": "My GenGen Site",
    "url": "http://gengen.local",
    "theme": "default",
    "source": current,
    "destination": joinAll([current, 'public']),
    "post_dir": "_posts",
    "themes_dir": "_themes",
    "layout_dir": "_layouts",
    "sass_dir": "_sass",
    "data_dir": "_data",
    "asset_dir": "assets",
    "template_dir": "_templates",
    "include_dir": "_includes",
    "block_list": <String>[],
    "markdown_extensions": <String>[],
    'permalink': "date",
    'show_drafts': false,
    "config": ["config.yaml"],
    "output": {"posts_dir": "posts"},
  };

  static const List<String> defaultExcludes = ['node_modules', ''];

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

  String get source => get("source") as String;

  String get destination {
    if (_config.containsKey("destination")) {
      var theDestination = get<String>("destination") as String;

      if (isRelative(theDestination)) {
        return join(source, theDestination);
      }

      return theDestination;
    }

    return _defaults["destination"] as String;
  }

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

  void addDefaultExcludes() {
    _config.putIfAbsent('excludes', () => <String>[]);
  }

  void addDefaultIncludes() {
    _config.putIfAbsent('includes', () => <String>[]);
  }

  Map<String, dynamic> readConfigFile(
    String filePath, [
    Map<String, dynamic> overrides = const {},
  ]) {
    var yamlConfig = parseYaml(readFileSafe(filePath));

    _config = {..._config, ...yamlConfig, ...overrides};

    return _config;
  }

  void readConfigFiles(
    List<String> files, [
    Map<String, dynamic> overrides = const {},
  ]) {
    for (var file in files) {
      readConfigFile(file, overrides);
    }
  }

  void read([Map<String, dynamic> overrides = const {}]) {
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
      if (isRelative(overrides["destination"] as String)) {
        _config["destination"] = absolute(siteDestination);
      } else {
        _config["destination"] = siteDestination;
      }
      overrides.remove("destination");
    }

    if (hasConfig) {
      List<String> configFiles = get<List<String>>("config") ?? [];

      for (var config in configFiles) {
        var file = File(join(source, config));
        if ((file.path.endsWith('.yaml') || file.path.endsWith('.yml'))) {
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
    readConfigFiles(resolvedFiles);
    overrides["config"] = resolvedFiles;
    _config.addAll(overrides);
  }
}

Configuration configuration(Map<String, dynamic> overrides) {
  var config = Configuration();
  config.read(overrides);

  return config;
}
