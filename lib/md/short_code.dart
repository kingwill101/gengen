import 'package:markdown/markdown.dart';

class Shortcode extends InlineSyntax {
  Shortcode()
      : super(
          r'''\[\s*shortcode\s+(?:\"([^\"]+)\"|'([^\']+)'|(\S+))((?:\s+\w+=(?:\"[^\"]+\"|'[^\']+'))*)\s*\]''',
        );

  @override
  bool onMatch(InlineParser parser, Match match) {
    var shortcodeName = match[1] ?? match[2] ?? match[3]!;
    var attributesString = match[4];

    var attributes = _parseAttributes(attributesString);

    var stringBuilder = StringBuffer("{%- render '$shortcodeName'");
    attributes.forEach((key, value) {
      stringBuilder.write(" ,\n$key: '$value'");
    });
    stringBuilder.write("\n-%}");

    var element = Text(stringBuilder.toString());
    parser.addNode(element);

    return true;
  }

  Map<String, String> _parseAttributes(String? attributesString) {
    var attributes = <String, String>{};

    if (attributesString != null) {
      var attrRegex = RegExp(r"(\w+)=(?:'([^']+)'|" "([^" "]+)" ")");

      for (var match in attrRegex.allMatches(attributesString)) {
        var value = match[2] ?? match[3]!;
        attributes[match[1]!] = value;
      }
    }

    return attributes;
  }
}
