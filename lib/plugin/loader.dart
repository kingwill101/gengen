import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:gengen/plugin/eval/eval_loader.dart' as eval;
import 'package:path/path.dart' as p;

abstract class PluginLoader {
  final PluginMetadata metadata;

  PluginLoader(this.metadata);

  List<PluginAsset> get langFiles;

  List<PluginAsset> get assets;

  Map<String, String> imports();

  bool get isConverter;

  bool get isGenerator;

  BasePlugin wrap();
}



BasePlugin initializePlugin(PluginMetadata metadata) {
  final fileTypes = metadata.files.map((f) => p.extension(f.path));
  if (fileTypes.contains('.dart')) {
    return eval.EvalLoader(metadata).wrap();
  }
  throw Exception("Unknown plugin type");
}
