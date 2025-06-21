import 'package:liquify/parser.dart';

class Avatar extends AbstractTag {
  Avatar(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {}
}
