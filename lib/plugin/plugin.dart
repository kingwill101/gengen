import 'dart:async';

import 'package:gengen/models/base.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:logging/logging.dart';
import 'package:liquify/liquify.dart' as liquid;

import 'package:gengen/plugin/logger.dart';

typedef LiquidFilter = liquid.FilterFunction;

extension PluginLogExtension on BasePlugin {
  Logger get logger => plugLog;
}

abstract class BasePlugin {
  final bool isWrapper = false;

  PluginMetadata get metadata => throw UnimplementedError();

  FutureOr<void> beforeRead() {}

  FutureOr<void> afterRead() {}

  FutureOr<void> beforeGenerate() {}

  FutureOr<void> afterGenerate() {}

  FutureOr<void> beforeRender() {}

  FutureOr<void> afterRender() {}

  FutureOr<void> beforeWrite() {}

  FutureOr<void> afterWrite() {}

  FutureOr<void> generate() {}

  FutureOr<String> convert(String content, Base page) async {
    return content;
  }

  FutureOr<void> afterInit() {}

  FutureOr<void> beforeConvert() {}

  FutureOr<void> afterConvert() {}

  /// Returns HTML to be injected into the `<head>` section.
  /// This is called during template rendering for each page
  String getHeadInjection() {
    return '';
  }

  /// Returns HTML to be injected before `</body>`.
  /// This is called during template rendering for each page
  String getBodyInjection() {
    return '';
  }

  /// Returns a list of CSS files that should be automatically included
  /// These are relative to the plugin's asset directory
  List<String> getCssAssets() {
    return [];
  }

  /// Returns a list of JavaScript files that should be automatically included
  /// These are relative to the plugin's asset directory
  List<String> getJsAssets() {
    return [];
  }

  /// Returns additional meta tags to be included in head
  Map<String, String> getMetaTags() {
    return {};
  }

  /// Returns Liquid filters to register globally.
  ///
  /// The map key is the filter name, and the value is a filter function
  /// compatible with Liquify's FilterRegistry.
  Map<String, LiquidFilter> getLiquidFilters() {
    return const {};
  }
}
