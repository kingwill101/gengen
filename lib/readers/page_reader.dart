import 'package:gengen/models/base.dart';
import 'package:gengen/models/page.dart';
import 'package:gengen/site.dart';

class PageReader {
  final Site site;
  List<Base> unfilteredContent = [];

  PageReader(this.site);

  List<Base> read(List<String> files) {
    for (var file in files) {
      unfilteredContent.add(Page(file, site: site));
    }

    return unfilteredContent;
  }
}
