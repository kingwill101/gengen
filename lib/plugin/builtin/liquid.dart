import 'dart:async';

import 'package:collection/collection.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:gengen/liquid/template.dart';
import 'package:gengen/site.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/utilities.dart';

class LiquidPlugin extends BasePlugin {
  final root = ContentRoot();

  @override
  PluginMetadata get metadata => PluginMetadata(
        name: 'LiquidPlugin',
        version: '1.0.0',
        description: 'Processes Liquid templates in GenGen',
      );

  @override
  FutureOr<String> convert(String content, Base page) async {
    logger.info('(${metadata.name}) ${page.source}');

    if (!containsLiquid(content)) {
      return content;
    }

    logger.info('(${metadata.name}) converting ${page.source}');
    return await _renderWithLayout(content, page);
  }

  Future<String> _renderWithLayout(String content, Base page) async {
    content = await _renderLiquid(content, page);
    String? layoutName = page.config["layout"] as String?;

    while (layoutName != null) {
      var layoutPath = _findLayoutPath(layoutName);
      if (layoutPath == null) break;

      var layout = site.layouts[layoutPath];
      if (layout == null) break;

      content = await _renderLiquid(layout.content, page, {'content': content});
      layoutName = layout.data["layout"] as String?;
    }

    return content;
  }

  Future<String> _renderLiquid(String content, Base page,
      [Map<String, dynamic>? extraData]) async {
    var template = await GenGenTempate.r(
      content,
      data: {
        'page': page.to_liquid,
        'site': site.map,
        ...?extraData,
      },
      contentRoot: root,
    );
    return await safeRender(template);
  }

  Future<String> safeRender(GenGenTempate template) async {
    try {
      return await template.render();
    } catch (err, st) {
      log.severe("Error rendering template", err, st);
      return '';
    }
  }

  /// Finds the path to a layout file by name.
  ///
  /// Searches for the layout in both the site's layout directory and the theme's layout directory.
  /// Returns the first matching layout path found, or null if no layout is found.
  ///
  /// [layoutName] The name of the layout file to find (without extension).
  /// Returns the full path to the layout file, or null if not found.
  String? _findLayoutPath(String layoutName) {
    return site.layouts.containsKey(layoutName) ? layoutName : null;
  }
}
