import 'package:gengen/configuration.dart';
import 'package:gengen/logging.dart';
import 'package:dot_prop/dot_prop.dart';
import 'package:path/path.dart';

mixin PathMixin {
  Configuration _configuration = Configuration();

  Configuration get config => _configuration;

  late String root;

  set configuration(Configuration configuration) {
    _configuration = configuration;
  }

  List<Object?> path(String notation) {
    final value = getProperty(config.all, notation);
    if (value is List<Object?>) {
      return value;
    } else if (value is List) {
      return value.cast<Object?>();
    } else {
      throw Exception("Property at '$notation' is not a List<Object?>");
    }
  }

  String pathFor(String folder) {
    String folderPath = join(root, folder);
    try {
      return canonicalize(folderPath);
    } catch (e) {
      log.info("Error accessing directory '$folder': $e");

      return "";
    }
  }

  String relativeToRoot(String path) => relative(path, from: root);

  String get includesPath => pathFor(config.get<String>("include_dir") ?? "");

  String get layoutsPath => pathFor(config.get<String>("layout_dir") ?? "");

  String get sassPath => pathFor(config.get<String>("sass_dir") ?? "");

  String get assetsPath => pathFor(config.get<String>("asset_dir") ?? "");

  String get postPath => pathFor(config.get<String>("post_dir") ?? "");

  String get dataPath => pathFor(config.get<String>("data_dir") ?? "");

  String get pluginPath => pathFor(config.get<String>("plugin_dir") ?? "");

  String get themesDir => pathFor(config.get<String>("themes_dir") ?? "");

  Map<String, dynamic> get output =>
      config.get<Map<String, dynamic>?>("output", defaultValue: null) ?? {};

  String get postOutputPath {
    if (output.containsKey("posts_dir")) {
      return output["posts_dir"] as String;
    }

    return "posts";
  }

  Map<String, dynamic> toJson() => {
        "includesPath": includesPath,
        "layoutsPath": layoutsPath,
        "sassPath": sassPath,
        "assetsPath": assetsPath,
        "postPath": postPath,
        "dataPath": dataPath,
        "pluginPath: ": pluginPath,
        "themesDir": themesDir,
        "output": output,
        "postOutputPath": postOutputPath,
      };
}
