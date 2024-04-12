import 'package:gengen/content/tokenizer.dart';
import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart';
import 'package:gengen/watcher.dart';
import 'package:path/path.dart';

class Layout with WatcherMixin {
  String content;
  Map<String, dynamic> data = {};
  String ext;
  String name;
  String path;
  String relativePath;

  Layout(
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

  @override
  void onFileChange() {
    parse();
    Site.instance.notifyFileChange(path);
  }

  @override
  String get source => path;
}
