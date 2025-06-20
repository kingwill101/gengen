import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/site.dart';
import 'package:gengen/sass/sass.dart';
import 'package:gengen/logging.dart';

class SassPlugin extends BasePlugin {
  @override
  PluginMetadata get metadata => PluginMetadata(
        name: 'SassPlugin',
        version: '1.0.0',
        description: 'Compiles SASS/SCSS files in GenGen',
      );

  @override
  String convert(String content, Base page) {
    logger.info('(${metadata.name}) ${page.source}');

    if (page.isAsset && (page.ext == '.scss' || page.ext == '.sass')) {
      logger.info('(${metadata.name}) converting ${page.source}');

      try {
        var result = compileSass(
          page.source,
          importPaths: [site.sassPath, site.theme.sassPath],
        );
        return result.css;
      } catch (e, s) {
        log.severe(
            '(${metadata.name})  Error compiling SASS for ${page.source}:',
            e,
            s);
        return '';
      }
    }
    logger
        .warning('(${metadata.name}) no saas content detected ${page.source}');

    return content;
  }

  @override
  void beforeRender() {
    // This hook can be used to prepare any necessary SASS variables or settings
    log.info('Preparing to compile SASS files...');
  }

  @override
  void afterRender() {
    // This hook can be used for any post-compilation tasks
    log.info('SASS compilation completed.');
  }
}
