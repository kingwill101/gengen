import 'package:liquify/parser.dart';

class Link extends AbstractTag with CustomTagParser {
  Link(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {}

  @override
  Parser parser() {
    return someTag("link");
  }
}
