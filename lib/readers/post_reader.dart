import 'package:gengen/models/base.dart';
import 'package:gengen/models/post.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart';

class PostReader {
  final Site site;
  List<Base> unfilteredContent = [];

  PostReader(this.site);

  List<Base> readPosts(String dir) {
    var docs = readContent(dir, RegExp(r'^[a-zA-Z0-9\-_]*'));
    unfilteredContent.addAll(docs);

    return unfilteredContent;
  }

  List<Base> readContent(String dir, RegExp matcher) {
    var entries = site.reader.getEntries(dir);
    var docs = <Base>[];
    for (var entry in entries) {
      if (!matcher.hasMatch(entry)) continue;

      var path = site.inSourceDir(join(dir, entry));
      var doc = Post(path, site: site);
      docs.add(doc);
    }

    return docs.toList();
  }
}
