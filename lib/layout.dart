import 'package:gengen/content/tokenizer.dart';
import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart';
import 'package:path/path.dart';

class Layout {
  String content;
  Map<String, dynamic> data = {};
  String ext;
  String name;
  String path;
  Site site;
  String relativePath;

  Layout(
    this.site,
    this.path,
    this.name, {
    this.content = "",
    this.data = const {},
    this.relativePath = "",
    this.ext = "",
  }) {
    if (ext.isEmpty) {
      ext = extension(name);
    }
    parse();
  }

  void parse() {
    var file = readFileSafe(path);
    var readContent = toContent(file);
    content = readContent.content;
    data = {...data, ...readContent.frontMatter};
  }

  @override
  String toString() {
    return "<$runtimeType @path=$path>";
  }
}
