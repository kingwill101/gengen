import 'package:liquify/parser.dart';

class Include extends AbstractTag with CustomTagParser {
  Include(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    final includeName = _resolveIncludeName(evaluator);
    final nodes = evaluator.resolveAndParseTemplate(includeName);
    evaluator.evaluateNodes(nodes);
  }

  @override
  dynamic evaluateAsync(Evaluator evaluator, Buffer buffer) async {
    final includeName = _resolveIncludeName(evaluator);
    final nodes = await evaluator.resolveAndParseTemplateAsync(includeName);
    await evaluator.evaluateNodesAsync(nodes);
  }

  @override
  Parser parser() {
    return someTag("include");
  }

  String _resolveIncludeName(Evaluator evaluator) {
    if (content.isEmpty) return '';
    final parts = <String>[];

    for (final node in content) {
      final resolved = _resolveNodeValue(evaluator, node);
      if (resolved != null) {
        parts.add(resolved);
      }
    }

    return parts.join();
  }

  String? _resolveNodeValue(Evaluator evaluator, ASTNode node) {
    if (node is Literal) return node.value?.toString();
    if (node is Identifier) {
      final value = evaluator.context.getVariable(node.name);
      if (value == null) return node.name;
      return value.toString();
    }
    if (node is MemberAccess) {
      final object = node.object;
      if (object is Identifier &&
          evaluator.context.getVariable(object.name) == null) {
        return _renderNode(node);
      }
    }

    final evaluated = evaluator.evaluate(node);
    if (evaluated != null) {
      return evaluated.toString();
    }

    return _renderNode(node);
  }

  String? _renderNode(ASTNode node) {
    if (node is Literal) return node.value?.toString();
    if (node is Identifier) return node.name;
    if (node is TextNode) return node.text;
    if (node is ArrayAccess) {
      final base = _renderNode(node.array) ?? '';
      final key = _renderNode(node.key) ?? '';
      return '$base[$key]';
    }
    if (node is MemberAccess) {
      final base = _renderNode(node.object) ?? '';
      if (node.members.isEmpty) return base;
      final segments = node.members.map(_renderNode).whereType<String>().toList();
      if (segments.isEmpty) return base;
      return ([base, ...segments]).join('.');
    }
    return null;
  }
}
