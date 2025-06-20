import 'dart:async';

import 'package:gengen/models/base.dart';
import 'package:gengen/plugin/eval/eval_loader.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';

class DartEvalPluginWrapper implements BasePlugin {
  @override
  final PluginMetadata metadata;

  final BasePlugin pluginInstance;

  DartEvalPluginWrapper(this.metadata, this.pluginInstance);

  Future<T> _safeCall<T>(String methodName, {String? content, Base? page}) async {
    if (EvalLoader(metadata).overridesMethod(methodName)) {
      switch (methodName) {
        case 'afterInit':
          await pluginInstance.afterInit();
          break;
        case 'beforeRead':
          await pluginInstance.beforeRead();
          break;
        case 'afterRead':
          await pluginInstance.afterRead();
          break;
        case 'beforeGenerate':
          await pluginInstance.beforeGenerate();
          break;
        case 'generate':
          await pluginInstance.generate();
          break;
        case 'beforeConvert':
          await pluginInstance.beforeConvert();
          break;
        case 'convert':
          if (content != null && page != null) {
            return await pluginInstance.convert(content, page) as T;
          }
          break;
        case 'afterConvert':
          await pluginInstance.afterConvert();
          break;
        case 'afterGenerate':
          await pluginInstance.afterGenerate();
          break;
        case 'beforeRender':
          await pluginInstance.beforeRender();
          break;
        case 'afterRender':
          await pluginInstance.afterRender();
          break;
        case 'beforeWrite':
          await pluginInstance.beforeWrite();
          break;
        case 'afterWrite':
          await pluginInstance.afterWrite();
          break;
      }
    }
    return null as T;
  }

  @override
  FutureOr<void> afterInit() async => _safeCall('afterInit');

  @override
  FutureOr<void> beforeRead() async => _safeCall('beforeRead');

  @override
  FutureOr<void> afterRead() async => _safeCall('afterRead');

  @override
  FutureOr<void> beforeGenerate() async => _safeCall('beforeGenerate');

  @override
  FutureOr<void> afterGenerate() async => _safeCall('afterGenerate');

  @override
  FutureOr<void> beforeRender() async => _safeCall('beforeRender');

  @override
  FutureOr<void> afterRender() async => _safeCall('afterRender');

  @override
  FutureOr<void> beforeWrite() async => _safeCall('beforeWrite');

  @override
  FutureOr<void> afterWrite() async => _safeCall('afterWrite');

  @override
  FutureOr<void> generate() async => _safeCall('generate');

  @override
  FutureOr<String> convert(String content, Base page) async {
    if (EvalLoader(metadata).overridesMethod('convert')) {
      return await _safeCall<String>('convert', content: content, page: page);
    }
    return content;
  }

  @override
  bool get isWrapper => true;

  @override
  FutureOr<void> afterConvert() {
    return _safeCall('afterConvert');
  }

  @override
  FutureOr<void> beforeConvert() {
    return _safeCall('beforeConvert');
  }
}
