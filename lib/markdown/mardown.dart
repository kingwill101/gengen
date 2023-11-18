import 'package:yaml/yaml.dart';

class ContentTokenizer {
  final RegExp _frontMatterExp =
      RegExp(r'^\s*[+-]{3}\s*([\s\S]*?)\s[+-]{3}\s*\n*([\s\S]*)', dotAll: false);

  MarkdownContent? parse(String content) {
    var matches = _frontMatterExp.firstMatch(content);
    if (matches != null && matches.groupCount >= 1) {
      var first = matches.group(1);
      var second = matches.group(2);
      return MarkdownContent(first, second);
    }
    return null;
  }
}

MarkdownContent? markdownContent(String content) {
  var tokenizer = ContentTokenizer();
  var frontMatter = tokenizer.parse(content);
  return frontMatter;
}

class MarkdownContent {
  String? frontmatter;
  String? content;

  MarkdownContent(this.frontmatter, this.content);
}

YamlMap parseFrontMatter(String front) {
  return loadYaml(front);
}
