import 'package:gengen/models/static.dart';
import 'package:path/path.dart' as p;

class ThemeContentAsset extends Static {
  final String contentRoot;

  ThemeContentAsset(
    super.source, {
    required this.contentRoot,
    super.name,
    super.frontMatter,
    super.dirConfig,
    super.destination,
  });

  @override
  void read() {
    super.read();
    name = p.relative(source, from: contentRoot);
  }

  @override
  String get relativePath => p.relative(source, from: contentRoot);
}
