import 'dart:async';

import 'package:gengen/exceptions.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:gengen/liquid/template.dart';
import 'package:gengen/site.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/utilities.dart';
import 'package:liquify/liquify.dart' as liquify show TemplateNotFoundException;
import 'package:liquify/src/grammar/shared.dart'
    as liquify_shared
    show ParsingException;

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

    final layoutName = page.config['layout'] as String?;
    final requiresLiquid = containsLiquid(content) || layoutName != null;

    if (!requiresLiquid) {
      return content;
    }

    logger.info('(${metadata.name}) converting ${page.source}');
    return await _renderWithLayout(content, page, layoutName);
  }

  Future<String> _renderWithLayout(
    String content,
    Base page,
    String? initialLayout,
  ) async {
    content = await _renderLiquid(content, page, templateName: page.source);
    page.renderer.content = content;
    String? layoutName = initialLayout;

    while (layoutName != null) {
      var layoutPath = _findLayoutPath(layoutName);
      if (layoutPath == null) break;

      var layout = site.layouts[layoutPath];
      if (layout == null) break;

      content = await _renderLiquid(
        layout.content,
        page,
        extraData: {'content': content},
        templateName: layoutPath,
      );
      page.renderer.content = content;
      layoutName = layout.data["layout"] as String?;
    }

    return content;
  }

  Future<String> _renderLiquid(
    String content,
    Base page, {
    Map<String, dynamic>? extraData,
    String? templateName,
  }) async {
    var template = await GenGenTempate.r(
      content,
      data: {'page': page.to_liquid, 'site': site.map, ...?extraData},
      contentRoot: root,
      templateName: templateName,
    );
    return await _safeRender(template, page, templateName ?? page.source);
  }

  Future<String> _safeRender(
    GenGenTempate template,
    Base page,
    String templateName,
  ) async {
    try {
      return await template.render();
    } on liquify.TemplateNotFoundException catch (err, st) {
      final message = _formatMissingIncludeMessage(
        err.path,
        templateName,
        page,
      );
      logger.severe(message, err, st);
      throw PluginException(message, err, st);
    } on liquify_shared.ParsingException catch (err, st) {
      final message = _formatParsingErrorMessage(err, templateName, page);
      logger.severe(message, err, st);
      throw PluginException(message, err, st);
    } catch (err, st) {
      final message = _formatGenericLiquidError(err, templateName, page);
      logger.severe(message, err, st);
      throw PluginException(message, err, st);
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

  String _formatMissingIncludeMessage(
    String missing,
    String templateName,
    Base page,
  ) {
    final searchRoots = [
      site.includesPath,
      site.theme.includesPath,
    ].where((path) => path.isNotEmpty).toList();

    final rootsNote = searchRoots.isEmpty
        ? 'No include directories were registered.'
        : 'Checked: ${searchRoots.join(', ')}';

    return 'Include \"$missing\" referenced from $templateName while rendering ${page.source} could not be found. $rootsNote';
  }

  String _formatParsingErrorMessage(
    liquify_shared.ParsingException err,
    String templateName,
    Base page,
  ) {
    final location = 'line ${err.line}:${err.column}';
    final snippet = _extractSourceSnippet(err.source, err.line, err.column);
    final details = snippet == null ? '' : '\n$snippet';

    return 'Liquid parse error in $templateName ($location) while rendering ${page.source}: ${err.message}$details';
  }

  String _formatGenericLiquidError(Object err, String templateName, Base page) {
    final description = err.toString();
    return 'Liquid render failed in $templateName while processing ${page.source}: $description';
  }

  String? _extractSourceSnippet(String source, int line, int column) {
    if (line <= 0) return null;

    final lines = source.split('\n');
    if (line > lines.length) return null;

    final targetLine = lines[line - 1];
    final safeColumn = column.clamp(1, targetLine.length + 1);
    final pointer = ' ' * (safeColumn - 1) + '^';

    return '$targetLine\n$pointer';
  }
}
