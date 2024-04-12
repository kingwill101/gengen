import 'package:gengen/models/static.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart';

class ThemeAsset extends Static {
  ThemeAsset(
    super.source, {
    super.name,
    super.frontMatter,
    super.dirConfig,
    super.destination,
  });

  @override
  String link() {
    name = relative(source, from: Site.instance.theme.root);

    return name;
  }
}
