import 'package:gengen/models/static.dart';
import 'package:path/path.dart' as p;

class PluginStaticAsset extends Static {
  final String pluginName;

  PluginStaticAsset(
    super.source,
    this.pluginName, {
    super.name,
    super.frontMatter,
    super.dirConfig,
    super.destination,
  });

  @override
  String link() {
    final normalizedPath = p.posix.basename(source);
    return 'assets/plugins/$pluginName/$normalizedPath';
  }
}
