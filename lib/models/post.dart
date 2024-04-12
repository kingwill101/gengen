import 'package:gengen/models/base.dart';
import 'package:gengen/models/permalink_structure.dart';
import 'package:gengen/site.dart';
import 'package:more/collection.dart';
import 'package:path/path.dart';

class Post extends Base {
  @override
  bool get isPost => true;

  Post(
    super.source, {
    super.name,
    super.frontMatter,
    super.dirConfig,
    super.destination,
  }) {
    defaultMatter.addAll({"permalink": PermalinkStructure.post});
  }

  @override
  String get name => source.removePrefix(join(Site.instance.root) + separator);

  @override
  String link() {
    return permalink().replaceFirst("_posts", "posts");
  }
}
