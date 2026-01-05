import 'package:gengen/shortcodes.dart';
import 'package:markdown/markdown.dart';

class Shortcode extends InlineSyntax {
  Shortcode()
      : super(
          r'''\[\s*shortcode\s+(?:\"([^\"]+)\"|'([^\']+)'|(\S+))((?:\s+[\w-]+\s*(?:=|:)\s*(?:\"[^\"]*\"|'[^\']*'|[^\s\]]+))*)\s*\]''',
        );

  @override
  bool onMatch(InlineParser parser, Match match) {
    var shortcodeName = match[1] ?? match[2] ?? match[3]!;
    var attributesString = match[4];

    var attributes = parseShortcodeAttributes(attributesString);

    var stringBuilder = StringBuffer(
      buildShortcodeTag(shortcodeName, attributes),
    );

    var element = Text(stringBuilder.toString());
    parser.addNode(element);

    return true;
  }

}
