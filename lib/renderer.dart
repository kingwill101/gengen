import 'package:gengen/liquid/template.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/sass/sass.dart';
import 'package:markdown/markdown.dart';

class Renderer {
  Base base;

  late String content;

  Renderer(this.base);

  Future<String> render() async {
    content = base.content;

    if (base.isMarkdown) {
      _renderMd();
    }

    if (base.isAsset) {
      var result = compileSass(
        base.source,
        importPaths: [base.site.sassPath, base.site.theme.sassPath],
      );

      return result.css;
    }

    if (base.config.containsKey("layout")) {
      if (base.hasLiquid) {
        await _renderLiquid();
      }

      var layouts = base.site.layouts;

      String? tmplKeyIndex;
      for (var key in layouts.keys) {
        if (key.startsWith(
              "${base.site.config.get<String>("layout_dir")}/${base.layout}",
            ) ||
            key.startsWith(
              "${base.site.theme.config.get<String>("layout_dir")}/${base.layout}",
            )) {
          tmplKeyIndex = key;
        }
      }

      if (tmplKeyIndex == null) return "";
      var tmpl = layouts[tmplKeyIndex];

      tmpl?.data.addAll(base.data);
      tmpl?.data.addAll(base.site.data);

      var template = Template.r(
        tmpl!.content,
        child: await _renderLiquid(),
        data: tmpl.data,
        contentRoot: ContentRoot(base.site),
      );

      return await template.render();
    }

    if (base.hasLiquid) {
      content = await _renderLiquid();
    }

    return content;
  }

  void _renderMd() {
    content = markdownToHtml(content);
  }

  Future<String> _renderLiquid() async {
    var template = Template.r(
      content,
      data: {
        ...base.data,
        ...base.site.data,
      },
      contentRoot: ContentRoot(base.site),
    );

    return await template.render();
  }
}
