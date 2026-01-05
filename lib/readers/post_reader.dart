import 'package:gengen/models/base.dart';
import 'package:gengen/models/page.dart';
import 'package:gengen/models/post.dart';
import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart';
import 'package:path/path.dart';

class PostReader {
  List<Base> unfilteredContent = [];

  static final RegExp _postMatcher =
      RegExp(r'^(?:.+/)*?[^/]+\.[^.]+$');
  static final RegExp _draftMatcher = RegExp(r'^(?:.+/)*?[^/]+\.[^.]+$');

  PostReader();

  List<Base> readPosts(String dir) {
    unfilteredContent.clear(); // Clear any previous content
    
    var docs = readContent(dir, _postMatcher);
    unfilteredContent.addAll(docs);

    return unfilteredContent;
  }

  List<Base> readDrafts(String dir) {
    unfilteredContent.clear();

    var docs = readContent(dir, _draftMatcher);
    unfilteredContent.addAll(docs);

    return unfilteredContent;
  }

  List<Base> readContent(String dir, RegExp matcher) {
    var entries = Site.instance.reader.getEntries(dir);
    var docs = <Base>[];
    for (var entry in entries) {
      if (!matcher.hasMatch(entry)) continue;

      var path = Site.instance.inSourceDir(join(dir, entry));

      final strictFrontMatter = Site.instance.config
              .get<bool>('strict_front_matter', defaultValue: false) ==
          true;
      if (strictFrontMatter && !hasYamlHeader(path)) {
        continue;
      }
      
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
