import 'package:gengen/md/md.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:gengen/utilities.dart';

class MarkdownPlugin extends BasePlugin {
  @override
  PluginMetadata get metadata => PluginMetadata(
        name: 'MarkdownPlugin',
        version: '1.0.0',
        description: 'Converts Markdown content to HTML in GenGen',
      );

  @override
  String convert(String content, Base page) {
    logger.info('(markdown) ${page.source}');
    if (page.isMarkdown) {
      logger.info('(markdown) converting ${page.source}');
      return renderMd(content);
    }
    logger.warning('(markdown) no markdown content detected ${page.source}');
    return content;
  }
}
