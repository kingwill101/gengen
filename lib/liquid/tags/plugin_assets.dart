import 'dart:async';
import 'package:gengen/site.dart';
import 'package:liquify/parser.dart';

/// Liquid tag that injects plugin head assets
/// Usage: {% plugin_head %}
class PluginHead extends AbstractTag {
  PluginHead(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    final site = Site.instance;
    final output = StringBuffer();

    // Collect all plugin head injections
    for (final plugin in site.plugins) {
      // Get direct head injection HTML
      final headInjection = plugin.getHeadInjection();
      if (headInjection.isNotEmpty) {
        output.writeln(headInjection);
      }

      // Get CSS assets and generate link tags
      final cssAssets = plugin.getCssAssets();
      for (final cssAsset in cssAssets) {
        final assetUrl = _getPluginAssetUrl(plugin.metadata.name, cssAsset);
        output.writeln('<link rel="stylesheet" href="$assetUrl">');
      }

      // Get meta tags
      final metaTags = plugin.getMetaTags();
      for (final entry in metaTags.entries) {
        output.writeln('<meta name="${entry.key}" content="${entry.value}">');
      }
    }

    buffer.write(output.toString());
  }

  @override
  FutureOr<dynamic> evaluateAsync(Evaluator evaluator, Buffer buffer) {
    return evaluate(evaluator, buffer);
  }

  String _getPluginAssetUrl(String pluginName, String assetPath) {
    // Plugin assets are served from /assets/plugins/[plugin-name]/[asset-path]
    return '/assets/plugins/$pluginName/$assetPath';
  }
}

/// Liquid tag that injects plugin body assets
/// Usage: {% plugin_body %}
class PluginBody extends AbstractTag {
  PluginBody(super.content, super.filters);

  @override
  dynamic evaluate(Evaluator evaluator, Buffer buffer) {
    final site = Site.instance;
    final output = StringBuffer();

    // Collect all plugin body injections
    for (final plugin in site.plugins) {
      // Get direct body injection HTML
      final bodyInjection = plugin.getBodyInjection();
      if (bodyInjection.isNotEmpty) {
        output.writeln(bodyInjection);
      }

      // Get JS assets and generate script tags
      final jsAssets = plugin.getJsAssets();
      for (final jsAsset in jsAssets) {
        final assetUrl = _getPluginAssetUrl(plugin.metadata.name, jsAsset);
        output.writeln('<script src="$assetUrl"></script>');
      }
    }

    buffer.write(output.toString());
  }

  @override
  FutureOr<dynamic> evaluateAsync(Evaluator evaluator, Buffer buffer) {
    return evaluate(evaluator, buffer);
  }

  String _getPluginAssetUrl(String pluginName, String assetPath) {
    // Plugin assets are served from /assets/plugins/[plugin-name]/[asset-path]
    return '/assets/plugins/$pluginName/$assetPath';
  }
} 
