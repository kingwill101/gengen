import 'package:gengen/models/page.dart';
import 'package:path/path.dart' as p;

class ThemePage extends Page {
  final String contentRoot;

  ThemePage(
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

  @override
  String get pathPlaceholder {
    final relativePath = p.relative(p.dirname(source), from: contentRoot);
    var normalized = relativePath.replaceAll(RegExp(r'\.*$'), '');
    return normalized == '.' ? '' : normalized;
  }
}
