import 'package:gengen/models/base.dart';
import 'package:gengen/models/post.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart';

class PostReader {
  List<Base> unfilteredContent = [];

  PostReader();

  List<Base> readPosts(String dir) {
    var docs = readContent(dir, RegExp(r'^[a-zA-Z0-9\-_]*'));
    unfilteredContent.addAll(docs);

    return unfilteredContent;
  }

  List<Base> readContent(String dir, RegExp matcher) {
    var entries = Site.instance.reader.getEntries(dir);
    var docs = <Base>[];
    for (var entry in entries) {
      if (!matcher.hasMatch(entry)) continue;

      var path = Site.instance.inSourceDir(join(dir, entry));
      var doc = Post(
        path,
      );
      docs.add(doc);
    }

    return docs.toList();
  }
}
