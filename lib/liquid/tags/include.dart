import 'package:liquify/parser.dart';

class Include extends AbstractTag with CustomTagParser {
  Include(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    final nodes = evaluator
        .resolveAndParseTemplate((content[0] as Literal).value.toString());
    evaluator.evaluateNodes(nodes);
  }

  @override
  dynamic evaluateAsync(Evaluator evaluator, Buffer buffer) async {
    final nodes = await evaluator
        .resolveAndParseTemplateAsync((content[0] as Literal).value.toString());
    await evaluator.evaluateNodesAsync(nodes);
  }

  @override
  Parser parser() {
    return someTag("include");
  }
}
