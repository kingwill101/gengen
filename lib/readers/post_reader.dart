import 'package:gengen/models/base.dart';
import 'package:gengen/models/page.dart';
import 'package:gengen/models/post.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart';

class PostReader {
  List<Base> unfilteredContent = [];

  PostReader();

  List<Base> readPosts(String dir) {
    unfilteredContent.clear(); // Clear any previous content
    
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
      
      // Check the filename to determine how to handle it
      String filename = withoutExtension(basename(entry));
      
      if (filename == '_index') {
        // _index.md files are for directory-level metadata only
        // Skip processing them as content files
        continue;
      } else if (filename == 'index') {
        // index.html files are special index pages that list posts
        var doc = Page(path);
        docs.add(doc);
      } else {
        // Regular posts
      var doc = Post(path);
      docs.add(doc);
      }
    }

    return docs.toList();
  }
}
