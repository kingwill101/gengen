import 'dart:async';

import 'package:gengen/models/base.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:logging/logging.dart';

import 'package:gengen/plugin/logger.dart';

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
}
