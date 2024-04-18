import 'package:highlight/highlight.dart' show highlight;
import 'package:liquid_engine/liquid_engine.dart';

class Highlight extends Block {
  final String? highlightType;

  Highlight(this.highlightType, super.children);

  @override
  Stream<String> render(RenderContext context) async* {
    var result = super.render(context);
    var source = await result.join();
    var parsed = highlight.parse(
      source,
      language: highlightType ?? 'plaintext',
    );
    yield parsed.toHtml();
  }

  static SimpleBlockFactory get factory => (tokens, children) {
        String? type;
        var parser = TagParser.from(tokens);

        if (tokens.isNotEmpty) {
            type = parser.current.value;
        }

        return Highlight(type, children);
      };
}
