import 'dart:io';

class Post {
  String? author;
  String? title;
  String? description;
  String? date;
  String? permalink;
  late bool draft;
  late List<dynamic> tags;
  Directory? destination;

  final Map<String, dynamic> dirConfig;

  late String source;

  late String content;

  Post.fromYaml(Map<String, dynamic> frontMatter, this.source, this.content,
      [this.dirConfig = const {}, this.destination]) {
    author = frontMatter["author"] ?? "";
    title = frontMatter["title"] ?? "";
    description = frontMatter["description"] ?? "";
    permalink = frontMatter["permalink"] ?? "";
    date = frontMatter["date"] ?? "";
    draft = frontMatter["draft"] ?? false;
    tags =
        frontMatter["tags"] != null ? frontMatter["tags"].cast<String>() : [];
  }
}

class Page {}

class PermalinkStructure {
  final String date = "/:categories/:year/:month/:day/:title:output_ext";
  final String pretty = "/:categories/:year/:month/:day/:title/";

  final String ordinal = "/:categories/:year/:y_day/:title:output_ext";
  final String weekdate =
      "/:categories/:year/W:week/:short_day/:title:output_ext";
  final String none = "/:categories/:title:output_ext";
}
