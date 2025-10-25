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
    String permalinkResult = permalink();
    
    // Only replace _posts with posts for certain permalink formats
    // The 'post' format should preserve the original path structure
    String permalinkFormat = config["permalink"] as String? ?? "";
    
    // Check if using the 'post' format or a pattern that includes :path
    if (permalinkFormat == "post" || permalinkFormat == PermalinkStructure.post) {
      // For 'post' format, preserve the original path structure
      return permalinkResult;
    }
    
    // For other formats (date, pretty, etc.), replace _posts with posts
    return permalinkResult.replaceFirst("_posts", "posts");
  }
}
