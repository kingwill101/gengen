import 'package:gengen/models/static.dart';
import 'package:path/path.dart';

class ThemeAsset extends Static {
  ThemeAsset(
    super.source, {
    super.site,
    super.name,
    super.frontMatter,
    super.dirConfig,
    super.destination,
  });

  @override
  String link() {
    name = relative(source, from: site?.theme.root);

    return name;
  }
}
