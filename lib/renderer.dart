import 'package:gengen/liquid/template.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/md/md.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/sass/sass.dart';
import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart';

class Renderer {
  Base base;
  late String content;

  Renderer(this.base) {
    content = base.content;
    if (containsMarkdown(content)) {
      content = renderMd(content);
    }
  }

  Future<void> resolve() async {
    if (containsLiquid(content) || containsMarkdown(content)) {
      await _renderLiquid();
      renderMd(content);
    }

    if (base.config.containsKey("layout")) {
      content = await _renderWithLayout(content);
    }
  }

  Future<String> render() async {
    if (base.isAsset) {
      try {
        var result = compileSass(
          base.source,
          importPaths: [Site.instance.sassPath, Site.instance.theme.sassPath],
        );
        return result.css;
      } catch (e) {
        log.severe(e.toString());
      }
      return "";
    }
    await resolve();

    return content;
  }

  Future<String> _renderWithLayout(String content,
      [String? initialLayoutName]) async {
    var layoutName = initialLayoutName ?? base.config["layout"] as String?;

    if (layoutName == null) {
      return content; // No layout specified, return original content
    }

    var layoutPath = _findLayoutPath(layoutName);

    if (layoutPath == null) {
      return content; // Layout not found, return original content
    }

    var tmpl = Site.instance.layouts[layoutPath];
    if (tmpl == null) {
      return content; // Template is null, return original content
    }

    // Add page data and site-wide data to the template's data
    tmpl.data.addAll({"page": base.to_liquid});
    tmpl.data.addAll(Site.instance.map);

    // Render the current layout with its content
    var template = Template.r(
      tmpl.content,
      child: content,
      // Pass the current content as the child content to be included in the layout
      data: tmpl.data,
      contentRoot: ContentRoot(),
    );

    var renderedContent = await safeRender(template);

    // Check if the current layout specifies another layout
    var nestedLayoutName = tmpl.data["layout"] as String?;
    if (nestedLayoutName != null) {
      // If there's a nested layout, recursively render the content with the nested layout
      return _renderWithLayout(renderedContent, nestedLayoutName);
    }

    return renderedContent;
  }

  Future<String> safeRender(Template template) async {
    try {
      return await template.render();
    } catch (err, st) {
      log.severe("Error rendering template: ${base.filePath}");
      log.severe(err);
      log.severe(st);
      return '';
    }
  }

  Future<void> _renderLiquid() async {
    var template = Template.r(
      content,
      data: {
        "page": base.to_liquid,
        ...Site.instance.map,
      },
      contentRoot: ContentRoot(),
    );

    content = await safeRender(template);
  }

  String? _findLayoutPath(String layoutName) {
    var layoutDir = Site.instance.config.get<String>("layout_dir");
    var themeLayoutDir = Site.instance.theme.config.get<String>("layout_dir");
    var possiblePaths = [
      "$layoutDir/$layoutName",
      "$themeLayoutDir/$layoutName",
    ];

    return Site.instance.layouts.keys.firstWhere(
      (k) => possiblePaths.contains(k),
      orElse: () => '',
    );
  }
}
