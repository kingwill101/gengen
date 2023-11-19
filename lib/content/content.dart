import 'package:gengen/utilities.dart';

class ContentTokenizer {
  final RegExp _frontMatterExp = RegExp(
      r'^\s*[+-]{3}\s*([\s\S]*?)\s[+-]{3}\s*\n*([\s\S]*)',
      dotAll: false);

  Content? parse(String content) {
    var matches = _frontMatterExp.firstMatch(content);
    if (matches != null && matches.groupCount >= 1) {
      var first = matches.group(1);
      var second = matches.group(2);
      return Content(first, second);
    }

    return Content(null, content);
  }
}

Content? toContent(String content) {
  var tokenizer = ContentTokenizer();
  var frontMatter = tokenizer.parse(content);
  return frontMatter;
}

class Content {
  String? _frontMatter;
  String? content;

  Content(this._frontMatter, this.content);

  Map<String, dynamic> get frontMatter => getFrontMatter(_frontMatter ?? "");
}
