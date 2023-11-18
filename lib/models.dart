import 'package:yaml/yaml.dart';

class Post {
  String? author;
  String? title;
  String? description;
  String? date;
  late bool draft;
  late List<dynamic> tags;

  late String source;

  late String content;

  Post.fromYaml(Map<String, dynamic> frontMatter, this.source, this.content) {

    author = frontMatter["author"] ?? "";
    title = frontMatter["title"] ?? "";
    description = frontMatter["description"] ?? "";
    date = frontMatter["date"] ?? "";
    draft = frontMatter["draft"] ?? false;
    tags =
        frontMatter["tags"] != null ? frontMatter["tags"].cast<String>() : [];
  }
}

class Page {}
