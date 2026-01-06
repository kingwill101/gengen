import 'package:gengen/md/short_code.dart';
import 'package:gengen/utilities.dart';
import 'package:html/parser.dart' as parser;
import 'package:markdown/markdown.dart';

class EmptyLineBlockSyntax extends BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^[ \t][ \t]+$');

  const EmptyLineBlockSyntax();

  @override
  Node parse(BlockParser parser) {
    parser.encounteredBlankLine = true;
    parser.advance();

    return Element('p', [Element.empty('br')]);
  }
}

String renderMd(String content) {
  var renderedContent = markdownToHtml(
    content,
    extensionSet: ExtensionSet.gitHubWeb,
    blockSyntaxes: [EmptyLineBlockSyntax()],
    inlineSyntaxes: [Shortcode()],
  );

  return cleanUpContent(renderedContent);
}

String stripEmptyTags(String htmlContent) {
  // Parse the HTML content
  var document = parser.parse(htmlContent);

  // Regex to match <p> tags with only whitespace content
  RegExp regex = RegExp(r'<p\s*([^>]*)>\s*</p>', multiLine: true);

  // Replace all matches with an empty string
  String modifiedHtml = document.body!.outerHtml.replaceAll(regex, '');

  return modifiedHtml;
}
