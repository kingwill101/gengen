import 'package:gengen/shortcodes.dart';
import 'package:liquify/liquify.dart' as liquid;
import 'package:liquify/parser.dart';

class ShortcodeTag extends AbstractTag with CustomTagParser, AsyncTag {
  ShortcodeTag(super.content, super.filters);

  @override
  Parser parser() {
    return (tagStart() &
            string('shortcode').trim() &
            any().starLazy(tagEnd()).flatten() &
            tagEnd())
        .map((values) {
          final raw = (values[2] as String).trim();
          if (raw.isEmpty) {
            return Tag('shortcode', []);
          }
          return Tag('shortcode', [TextNode(raw)]);
        });
  }

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final raw = _rawArgs();
    if (raw.isEmpty) return null;
    final parts = parseShortcodeArgs(raw);
    final renderTag = buildRenderTag(parts.name, parts.attributes);

    final template = liquid.Template.parse(
      renderTag,
      root: evaluator.context.getRoot(),
      environment: evaluator.context,
    );
    buffer.write(template.render());
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final raw = _rawArgs();
    if (raw.isEmpty) return null;
    final parts = parseShortcodeArgs(raw);
    final renderTag = buildRenderTag(parts.name, parts.attributes);

    final template = liquid.Template.parse(
      renderTag,
      root: evaluator.context.getRoot(),
      environment: evaluator.context,
    );
    buffer.write(await template.renderAsync());
  }

  String _rawArgs() {
    if (content.isEmpty) return '';
    final node = content.first;
    if (node is TextNode) return node.text.trim();
    return node.toString();
  }
}
