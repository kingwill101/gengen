import 'dart:async';

import 'package:highlight/highlight.dart';
import 'package:liquify/parser.dart';

class Highlight extends AbstractTag with CustomTagParser {
  Highlight(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    String highlightContent = '';
    final language = args.isEmpty ? 'text' : args[0].name;

    for (final node in body) {
      highlightContent += evaluator.evaluate(node).toString();
    }

    buffer
        .write(highlight.parse(highlightContent, language: language).toHtml());
  }

  @override
  FutureOr evaluateAsync(Evaluator evaluator, Buffer buffer) {
    return evaluate(evaluator, buffer);
  }

  @override
  Parser parser() {
    return someTagWithEnd("highlight");
  }
}

Parser<Tag> someTagWithEnd(String name) {
  return (someTag(name) &
          (tag() | text()).plusLazy(someEndTag(name)) &
          someEndTag(name))
      .map((v) {
    return (v[0] as Tag)
        .copyWith(body: (v[1] as List).map((e) => e as ASTNode).toList());
  });
}

Parser<Tag> someEndTag(String name) {
  final tagName = name.startsWith("end") ? name : "end$name";
  var parser = ((tagStart()) & string(tagName).trim() & (tagEnd()));
  return parser.map((values) {
    return Tag(tagName, []);
  }).labeled('someEndTag');
}
