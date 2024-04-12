import 'package:gengen/models/base.dart';
import 'package:gengen/models/static.dart';

class StaticReader {
  List<Base> unfilteredContent = [];

  StaticReader();

  List<Base> read(List<String> files) {
    for (var file in files) {
      unfilteredContent.add(Static(file));
    }
    
    return unfilteredContent;
  }
}
