import 'package:gengen/models/base.dart';
import 'package:gengen/plugin/builtin/liquid.dart';
import 'package:gengen/site.dart';

class Renderer {
  Base base;
  late String content;

  Renderer(this.base) {
    content = base.content;
  }

  Future<String> render() async {
    final liquidPlugin = site.plugins.whereType<LiquidPlugin>().firstOrNull;
    if (liquidPlugin != null) {
      content = await liquidPlugin.renderContent(content, base);
    }

    for (final plugin in site.plugins) {
      if (plugin is LiquidPlugin) continue;
      content = await plugin.convert(content, base);
    }

    if (liquidPlugin != null) {
      content = await liquidPlugin.renderLayouts(content, base);
    }

    return content;
  }
}
