import 'package:gengen/models/base.dart';
import 'package:gengen/models/static.dart';
import 'package:gengen/site.dart';

class StaticReader {
  final Site site;
  List<Base> unfilteredContent = [];

  StaticReader(this.site);

  List<Base> read(List<String> files) {
    for (var file in files) {
      unfilteredContent.add(Static(file, site));
    }
    
    return unfilteredContent;
  }
}
