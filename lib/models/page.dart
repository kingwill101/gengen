import 'package:gengen/models/base.dart';
import 'package:gengen/models/permalink_structure.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;

class Page extends Base {
  @override
  bool get isPage => true;

  Page(
    super.source, {
    super.name,
    super.frontMatter,
    super.dirConfig,
    super.destination,
  }) {
    defaultMatter.addAll({"permalink": PermalinkStructure.post});
  }

  @override
  String get pathPlaceholder {
    final relativePath = p.relative(
      p.dirname(source),
      from: site.config.source,
    );
    var normalized = relativePath.replaceAll(RegExp(r'\.*$'), '');
    return normalized == '.' ? '' : normalized;
  }

  @override
  String link() {
    // Special handling for pages in _posts directory (like _posts/index.html)
    if (name.startsWith('_posts/')) {
      return permalink().replaceFirst("_posts", "posts");
    }
    return permalink();
  }
}
