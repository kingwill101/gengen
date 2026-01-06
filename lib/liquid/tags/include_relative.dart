import 'package:gengen/drops/document_drop.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart';
import 'package:liquify/liquify.dart' as liquid;
import 'package:liquify/parser.dart';
import 'package:path/path.dart' as p;

class IncludeRelative extends AbstractTag with CustomTagParser, AsyncTag {
  IncludeRelative(super.content, super.filters);

  @override
  Parser parser() {
    return (tagStart() &
            string('include_relative').trim() &
            any().starLazy(tagEnd()).flatten() &
            tagEnd())
        .map((values) {
          final raw = (values[2] as String).trim();
          if (raw.isEmpty) {
            return Tag('include_relative', []);
          }
          return Tag('include_relative', [TextNode(raw)]);
        });
  }

  @override
  dynamic evaluateWithContext(Evaluator evaluator, Buffer buffer) {
    final includeName = _resolveIncludeName(evaluator);
    final baseDir = _resolveBaseDir(evaluator);
    final filePath = p.normalize(p.join(baseDir, includeName));

    if (!fs.file(filePath).existsSync()) {
      throw liquid.TemplateNotFoundException(includeName);
    }

    final fileContent = cleanUpContent(readFileSafe(filePath));
    final root = evaluator.context.getRoot();
    final template = liquid.Template.parse(
      fileContent,
      root: root,
      environment: evaluator.context,
    );
    buffer.write(template.render());
  }

  @override
  Future<dynamic> evaluateWithContextAsync(
    Evaluator evaluator,
    Buffer buffer,
  ) async {
    final includeName = _resolveIncludeName(evaluator);
    final baseDir = _resolveBaseDir(evaluator);
    final filePath = p.normalize(p.join(baseDir, includeName));

    if (!await fs.file(filePath).exists()) {
      throw liquid.TemplateNotFoundException(includeName);
    }

    final fileContent = cleanUpContent(readFileSafe(filePath));
    final root = evaluator.context.getRoot();
    final template = liquid.Template.parse(
      fileContent,
      root: root,
      environment: evaluator.context,
    );
    buffer.write(await template.renderAsync());
  }

  String _resolveIncludeName(Evaluator evaluator) {
    if (content.isEmpty) return '';
    final parts = <String>[];

    for (final node in content) {
      final resolved = _renderNode(node);
      if (resolved != null) {
        parts.add(resolved);
      }
    }

    return parts.join();
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
      final segments = node.members
          .map(_renderNode)
          .whereType<String>()
          .toList();
      if (segments.isEmpty) return base;
      return ([base, ...segments]).join('.');
    }
    return null;
  }

  String _resolveBaseDir(Evaluator evaluator) {
    final page = evaluator.context.getVariable('page');
    if (page is DocumentDrop) {
      return p.dirname(page.content.source);
    }
    if (page is Map && page['path'] != null) {
      final pagePath = page['path'].toString();
      if (page['collection'] != null) {
        return p.dirname(
          site.inSourceDir(p.join(site.collectionsDir, pagePath)),
        );
      }
      return p.dirname(site.inSourceDir(pagePath));
    }
    return site.config.source;
  }
}
