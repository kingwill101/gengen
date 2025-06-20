import 'package:gengen/logging.dart';
import 'package:gengen/path_extensions.dart';
import 'package:gengen/plugin/eval/analyzer.dart';
import 'package:gengen/plugin/eval/context.dart';
import 'package:gengen/plugin/eval/wrapper.dart';
import 'package:gengen/plugin/loader.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:path/path.dart';

class  EvalLoader extends PluginLoader {
  EvalLoader(super.metadata);

  @override
  List<PluginAsset> get langFiles =>
      metadata.files.where((e) => e.path.endsWith('.dart')).toList();

  @override
  List<PluginAsset> get assets =>
      metadata.files.where((e) => !e.path.endsWith('.dart')).toList();

  String get className {
    try {
      return metadata.entrypoint.split(":")[1];
    } catch (e) {
      return "";
    }
  }

  String get classFilePath => "${metadata.entrypoint.split(":")[0]}.dart";

  String? _checkEntrypoint() {
    final ep = metadata.entrypoint.split(":");

    if (ep.length != 2) {
      log.severe("Plugin($metadata.name): Entrypoint ${metadata.entrypoint} is invalid");
      return null;
    }

    final mainFile =
        langFiles.where((e) => e.name == "${ep[0]}.dart").firstOrNull;

    if (mainFile == null) {
      log.severe("Plugin(${metadata.name}): Entrypoint ${metadata.entrypoint} does not exist");
      return null;
    }

    final mainContent = mainFile.path.openFile().readAsStringSync();
    final classDef = RegExp(r"class[\W]*" + ep[1]).firstMatch(mainContent);

    if (classDef == null) {
      log.severe("Plugin(${metadata.name}): Entrypoint ${metadata.entrypoint} does not exist");
      return null;
    }
    return mainContent;
  }

  @override
  Map<String, String> imports() {
    final importMap = <String, String>{};

    for (var asset in langFiles) {
      final f = asset.path.openFile();
      final relativePath = relative(f.path, from: metadata.path);

      if (!f.existsSync()) {
        log.warning("Plugin($metadata.name): File $relativePath does not exist");
        continue;
      }
      final content = f.readAsStringSync();
      importMap[relativePath] = content;
    }

    return importMap;
  }

  bool doesExtend(String superclassName) {
    DartAnalyzer analyzer = DartAnalyzer(_checkEntrypoint() ?? "");
    return analyzer.doesExtend(className, superclassName);
  }

  bool overridesMethod(String methodName) {
    DartAnalyzer analyzer = DartAnalyzer(_checkEntrypoint() ?? "");
    return analyzer.doesOverrideMethod(className, methodName);
  }

  @override
  bool get isConverter => doesExtend("Converter");

  @override
  bool get isGenerator => doesExtend("Generator");

  BasePlugin? _initializePlugin() {
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
      return plugin as BasePlugin;
    } catch (e, stack) {
      log.severe("Plugin(${metadata.name}): error initializing plugin");
      log.severe(e);
      log.severe(stack);
      return null;
    }
  }

  @override
  BasePlugin wrap() {
    final pluginInstance = _initializePlugin();
    if (pluginInstance != null) {
      return DartEvalPluginWrapper(metadata, pluginInstance);
    }
    throw Exception('Failed to initialize plugin: ${metadata.name}');
  }

  BasePlugin initializeEvalPlugin() {
    final pluginInstance = _initializePlugin();
    if (pluginInstance != null) {
      return DartEvalPluginWrapper(metadata, pluginInstance);
    }
    throw Exception('Failed to initialize plugin: ${metadata.name}');
  }
}
