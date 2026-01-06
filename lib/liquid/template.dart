import 'package:gengen/fs.dart';
import 'package:gengen/liquid/modules/data_module.dart';
import 'package:gengen/liquid/modules/url_module.dart';
import 'package:gengen/liquid/tags/avatar.dart';
import 'package:gengen/liquid/tags/feed_meta.dart';
import 'package:gengen/liquid/tags/highlight_tag.dart';
import 'package:gengen/liquid/tags/include.dart';
import 'package:gengen/liquid/tags/include_relative.dart';
import 'package:gengen/liquid/tags/link.dart' as link;
import 'package:gengen/liquid/tags/plugin_assets.dart';
import 'package:gengen/liquid/tags/seo.dart';
import 'package:gengen/liquid/tags/shortcode.dart';
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

  final String? templateName;

  GenGenTempate.r(
    this.template, {
    this.child = "",
    this.data = const {},
    this.contentRoot = const ContentRoot(),
    this.templateName,
  }) {
    liquid.TagRegistry.register(
      'highlight',
      (content, filters) => Highlight(content, filters),
    );
    liquid.TagRegistry.register(
      'feed_meta',
      (content, filters) => Feed(content, filters),
    );
    liquid.TagRegistry.register(
      'seo',
      (content, filters) => Seo(content, filters),
    );
    liquid.TagRegistry.register(
      'avatar',
      (content, filters) => Avatar(content, filters),
    );
    liquid.TagRegistry.register(
      'link',
      (content, filters) => link.Link(content, filters),
    );

    liquid.TagRegistry.register(
      'include',
      (content, filters) => Include(content, filters),
    );
    liquid.TagRegistry.register(
      'include_relative',
      (content, filters) => IncludeRelative(content, filters),
    );
    liquid.TagRegistry.register(
      'shortcode',
      (content, filters) => ShortcodeTag(content, filters),
    );

    // Plugin asset injection tags
    liquid.TagRegistry.register(
      'plugin_head',
      (content, filters) => PluginHead(content, filters),
    );
    liquid.TagRegistry.register(
      'plugin_body',
      (content, filters) => PluginBody(content, filters),
    );
    liquid.FilterRegistry.registerModule('ur', UrlModule());
    liquid.FilterRegistry.registerModule('data', DataModule());

    for (final plugin in site.plugins) {
      final filters = plugin.getLiquidFilters();
      if (filters.isEmpty) continue;
      for (final entry in filters.entries) {
        liquid.FilterRegistry.register(entry.key, entry.value);
      }
    }
  }

  Future<String> render() async {
    if (child.isNotEmpty) {
      child = await liquid.Template.parse(
        template,
        root: contentRoot,
        data: {...data},
      ).renderAsync();
    }

    if (template.isEmpty) return template;

    return await liquid.Template.parse(
      template,
      root: contentRoot,
      data: {...data, if (child.isNotEmpty) 'content': child},
    ).renderAsync();
  }
}

class ContentRoot implements liquid.Root {
  const ContentRoot();

  @override
  liquid.Source resolve(String relPath) {
    final include = _resolveIncludeSync(relPath);
    return liquid.Source(null, include, this);
  }

  @override
  Future<liquid.Source> resolveAsync(String relPath) async {
    final include = await _resolveIncludeAsync(relPath);
    return liquid.Source(null, include, this);
  }

  String _resolveIncludeSync(String relPath) {
    final paths = [site.includesPath, site.theme.includesPath];
    for (final dirPath in paths) {
      final directory = fs.directory(dirPath);
      if (!directory.existsSync()) continue;

      final fileContent = _findIncludeInDirectory(directory, relPath);
      if (fileContent != null) {
        return fileContent;
      }
    }

    throw liquid.TemplateNotFoundException(relPath);
  }

  Future<String> _resolveIncludeAsync(String relPath) async {
    final paths = [site.includesPath, site.theme.includesPath];
    for (final dirPath in paths) {
      final directory = fs.directory(dirPath);
      if (!await directory.exists()) continue;

      final fileContent = await _findIncludeInDirectoryAsync(
        directory,
        relPath,
      );
      if (fileContent != null) {
        return fileContent;
      }
    }

    throw liquid.TemplateNotFoundException(relPath);
  }

  String? _findIncludeInDirectory(Directory directory, String relPath) {
    final globPattern = Glob("*$relPath*");

    final fileSystemEntities = directory.listSync(recursive: true);
    for (final entity in fileSystemEntities) {
      if (entity is File &&
          globPattern.matches(p.relative(entity.path, from: directory.path))) {
        if (p.basenameWithoutExtension(entity.path) ==
            p.basenameWithoutExtension(relPath)) {
          var fileContent = readFileSafe(entity.path);
          return cleanUpContent(fileContent);
        }
      }
    }

    return null;
  }

  Future<String?> _findIncludeInDirectoryAsync(
    Directory directory,
    String relPath,
  ) async {
    final globPattern = Glob("*$relPath*");
    final fileSystemEntities = directory.list(recursive: true);

    await for (final entity in fileSystemEntities) {
      if (entity is File &&
          globPattern.matches(p.relative(entity.path, from: directory.path))) {
        if (p.basenameWithoutExtension(entity.path) ==
            p.basenameWithoutExtension(relPath)) {
          var fileContent = readFileSafe(entity.path);
          return cleanUpContent(fileContent);
        }
      }
    }

    return null;
  }
}
