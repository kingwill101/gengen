import 'package:gengen/models/base.dart';
import 'package:gengen/models/static.dart';

class StaticReader {
  List<Base> unfilteredContent = [];

  StaticReader();

  List<Base> read(List<String> files) {
    unfilteredContent.clear(); // Clear any previous content

    for (var file in files) {
      final staticFile = Static(file);
      unfilteredContent.add(staticFile);
    }

    return unfilteredContent;
  }
}
