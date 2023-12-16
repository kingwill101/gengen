
import 'package:gengen/models/base.dart';
import 'package:gengen/models/permalink_structure.dart';

class Page extends Base {

  @override
  bool get isPage => true;

  Page(
    super.source, {
    super.site,
    super.name,
    super.frontMatter,
    super.dirConfig,
    super.destination,
  }) {
    defaultMatter.addAll({"permalink": PermalinkStructure.post});
  }

}
