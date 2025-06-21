import 'package:liquify/parser.dart';

class Feed extends AbstractTag {
  Feed(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {}
}
