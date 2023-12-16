import 'package:gengen/models/base.dart';

class Static extends Base {
  Static(
    super.source, {
    super.site,
    super.name,
    super.frontMatter,
    super.dirConfig,
    super.destination,
  });

  @override
  bool get isStatic => true;

  @override
  String link() {
    return name;
  }
}
