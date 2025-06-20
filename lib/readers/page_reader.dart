import 'package:gengen/models/base.dart';
import 'package:gengen/models/page.dart';

class PageReader {
  List<Base> unfilteredContent = [];

  PageReader();

  List<Base> read(List<String> files) {
    unfilteredContent.clear(); // Clear any previous content
    
    for (var file in files) {
      final page = Page(file);
      unfilteredContent.add(page);
    }

    return unfilteredContent;
  }
}
