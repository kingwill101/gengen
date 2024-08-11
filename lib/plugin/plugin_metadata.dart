import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/path_extensions.dart';
import 'package:gengen/plugin/analyzer.dart';
import 'package:gengen/plugin/context.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:path/path.dart';

part 'plugin.freezed.dart';
part 'plugin_metadata.g.dart';

@freezed
class PluginMetadata with _$PluginMetadata {
  const factory PluginMetadata({
    required String name,
    @Default("plugin:Plugin") String entrypoint,
    String? url,
    String? path,
    String? description,
    String? author,
    String? authorUrl,
    String? license,
    String? version,
    @Default([]) List<String> include,
    @Default([]) List<PluginAsset> files,
  }) = _PluginMetadata;

  factory PluginMetadata.fromJson(Map<String, Object?> json) =>
      _$PluginMetadataFromJson(json);
}

@freezed
class PluginAsset with _$PluginAsset {
  const factory PluginAsset({
    required String name,
    required String path,
  }) = _PluginAsset;

  factory PluginAsset.fromJson(Map<String, Object?> json) =>
      _$PluginAssetFromJson(json);
}

enum PluginType { unknown, generator, converter }

extension PluginMetadataX on PluginMetadata {
  String get id => name.replaceAll(RegExp(r'[^a-z0-9]'), '_');

  List<PluginAsset> get dartFiles =>
      files.where((e) => e.path.endsWith('.dart')).toList();

  String get className {
    try {
      return entrypoint.split(":")[1];
    } catch (e) {
      return "";
    }
  }

  String get classFilePath => "${entrypoint.split(":")[0]}.dart";

  String? _checkEntrypoint() {
    final ep = entrypoint.split(":");

    if (ep.length != 2) {
      log.severe("Plugin($name): Entrypoint $entrypoint is invalid");
      return null;
    }

    final mainFile =
        dartFiles.where((e) => e.name == "${ep[0]}.dart").firstOrNull;

    if (mainFile == null) {
      log.severe("Plugin($name): Entrypoint $entrypoint does not exist");
      return null;
    }

    final mainContent = mainFile.path.openFile().readAsStringSync();
    final classDef = RegExp(r"class[\W]*" + ep[1]).firstMatch(mainContent);

    if (classDef == null) {
      log.severe("Plugin($name): Entrypoint $entrypoint does not exist");
      return null;
    }
    return mainContent;
  }

  Map<String, String> imports() {
    final importMap = <String, String>{};

    for (var asset in dartFiles) {
      final f = asset.path.openFile();
      final relativePath = relative(f.path, from: path);

      if (!f.existsSync()) {
        log.warning("Plugin($name): File $relativePath does not exist");
        continue;
      }
      final content = f.readAsStringSync();
      importMap[relativePath] = content;
    }

    return importMap;
  }

  bool doesExtend(String className, String superclassName) {
    DartAnalyzer analyzer = DartAnalyzer(_checkEntrypoint() ?? "");
    return analyzer.doesExtend(className, superclassName);
  }

  bool get isConverter => doesExtend(className, "Converter");

  bool get isGenerator => doesExtend(className, "Generator");

  APlugin? _initializePlugin() {
    String source = '''
    import 'package:plugin/$classFilePath' show $className;
    $className setup() {
      final plugin = $className();
      return plugin;
    }
    ''';
    final context = PluginContext.create(source: {
      ...imports(),
      "main.dart": source,
    }, name: "plugin");

    try {
      final plugin = context.run("setup");
      return plugin as APlugin;
    } catch (e, stack) {
      log.severe("Plugin($name): error initializing plugin");
      log.severe(stack);
      return null;
    }
  }

  String convert(String content) {
    assert(isConverter);

    final plugin = _initializePlugin();
    if (plugin != null) {
      return (plugin as Converter).convert(content);
    }
    return content;
  }

  void generate() {
    if (!isGenerator) {
      log.severe("Plugin($name): is not a generator");
      return;
    }

    final plugin = _initializePlugin();
    if (plugin != null) {
      (plugin as Generator).generate();
    }
  }
}
