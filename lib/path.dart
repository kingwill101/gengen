import 'package:gengen/configuration.dart';
import 'package:gengen/logging.dart';
import 'package:path/path.dart';

abstract class Path {
  late Configuration configuration;

  Configuration get config => configuration;

  late String root;

  Path([this.configuration = const Configuration()]);

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
  String get themesDir => pathFor(config.get<String>("themes_dir") ?? "");

  Map<String, dynamic> get output =>
      config.get<Map<String, dynamic>?>("output", defaultValue: null) ?? {};

  String get postOutputPath {
    if (output.containsKey("posts_dir")) {
      return output["posts_dir"] as String;
    }

    return "posts";
  }
}
