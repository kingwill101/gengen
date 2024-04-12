import 'package:gengen/models/base.dart';
import 'package:gengen/models/page.dart';

class PageReader {
  List<Base> unfilteredContent = [];

  PageReader();

  List<Base> read(List<String> files) {
    for (var file in files) {
      unfilteredContent.add(Page(file, ));
    }

    return unfilteredContent;
  }
}
