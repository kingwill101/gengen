import 'package:gengen/models/base.dart';
import 'package:gengen/models/permalink_structure.dart';
import 'package:more/collection.dart';
import 'package:path/path.dart';

class Post extends Base {
  @override
  bool get isPost => true;

  bool isDraft() {
    if (config.containsKey("draft") && config["draft"] is bool) {
      return config["draft"] as bool;
    }

    return false;
  }

  Post(
    super.source, {
    super.site,
    super.name,
    super.frontMatter,
    super.dirConfig,
    super.destination,
  }) {
    defaultMatter.addAll({"permalink": PermalinkStructure.post});
  }

  @override
  String get name => source.removePrefix(join(site!.root) + separator);

  @override
  String link() {
    return permalink().replaceFirst("_posts", "posts");
  }
}
