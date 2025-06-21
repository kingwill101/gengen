import 'package:gengen/fs.dart';
import 'package:gengen/liquid/modules/data_module.dart';
import 'package:gengen/liquid/modules/url_module.dart';
import 'package:gengen/liquid/tags/avatar.dart';
import 'package:gengen/liquid/tags/feed_meta.dart';
import 'package:gengen/liquid/tags/highlight_tag.dart';
import 'package:gengen/liquid/tags/include.dart';
import 'package:gengen/liquid/tags/link.dart' as link;
import 'package:gengen/liquid/tags/plugin_assets.dart';
import 'package:gengen/liquid/tags/seo.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart';
import 'package:glob/glob.dart';
import 'package:liquify/liquify.dart' as liquid;
import 'package:path/path.dart' as p;

class GenGenTempate {
  String template;

  String child;

  Map<String, dynamic> data;

  liquid.Root contentRoot;

  GenGenTempate.r(
    this.template, {
    this.child = "",
    this.data = const {},
    this.contentRoot = const ContentRoot(),
  }) {
    liquid.TagRegistry.register(
        'highlight', (content, filters) => Highlight(content, filters));
    liquid.TagRegistry.register(
        'feed_meta', (content, filters) => Feed(content, filters));
    liquid.TagRegistry.register(
        'seo', (content, filters) => Seo(content, filters));
    liquid.TagRegistry.register(
        'avatar', (content, filters) => Avatar(content, filters));
    liquid.TagRegistry.register(
        'link', (content, filters) => link.Link(content, filters));

    liquid.TagRegistry.register(
        'include', (content, filters) => Include(content, filters));
    
    // Plugin asset injection tags
    liquid.TagRegistry.register(
        'plugin_head', (content, filters) => PluginHead(content, filters));
    liquid.TagRegistry.register(
        'plugin_body', (content, filters) => PluginBody(content, filters));
    liquid.FilterRegistry.registerModule('ur', UrlModule());
    liquid.FilterRegistry.registerModule('data', DataModule());
  }

  Future<String> render() async {
    if (child.isNotEmpty) {
      child = await liquid.Template.parse(
        template,
        root: contentRoot,
        data: {
          ...data,
        },
      ).renderAsync();
    }

    if (template.isEmpty) return template;

    try {
      return await liquid.Template.parse(
        template,
        root: contentRoot,
        data: {
          ...data,
          if (child.isNotEmpty) 'content': child,
        },
      ).renderAsync();
    } catch (e, s) {
      log.severe("($template) result", e, s);
      // Instead of returning empty string, return the original template
      // This preserves the content even if liquid processing fails
      return template;
    }
  }
}

class ContentRoot implements liquid.Root {
  const ContentRoot();

  @override
  liquid.Source resolve(String relPath) {
    var paths = [site.includesPath, site.theme.includesPath];
    for (var dirPath in paths) {
      var directory = fs.directory(dirPath);
      if (!directory.existsSync()) continue;

      var globPattern = Glob("*$relPath*");

      var fileSystemEntities = directory.listSync(recursive: true);

      for (var entity in fileSystemEntities) {
        if (entity is File &&
            globPattern.matches(p.relative(entity.path, from: dirPath))) {
          if (p.basenameWithoutExtension(entity.path) ==
              p.basenameWithoutExtension(relPath)) {
            var fileContent = readFileSafe(entity.path);
            fileContent = cleanUpContent(fileContent);

            return liquid.Source(null, fileContent, this);
          }
        }
      }
    }

    log.warning("Include: $relPath not found");

    return liquid.Source(null, '', this);
  }

  @override
  Future<liquid.Source> resolveAsync(String relPath) async {
    var paths = [site.includesPath, site.theme.includesPath];
    for (var dirPath in paths) {
      var directory = fs.directory(dirPath);
      if (!await directory.exists()) continue;

      var globPattern = Glob("*$relPath*");

      var fileSystemEntities = directory.list(recursive: true);

      await for (final entity in fileSystemEntities) {
        if (entity is File &&
            globPattern.matches(p.relative(entity.path, from: dirPath))) {
          if (p.basenameWithoutExtension(entity.path) ==
              p.basenameWithoutExtension(relPath)) {
            var fileContent = readFileSafe(entity.path);
            fileContent = cleanUpContent(fileContent);

            return liquid.Source(null, fileContent, this);
          }
        }
      }
    }

    log.warning("Include: $relPath not found");

    return liquid.Source(null, '', this);
  }
}
