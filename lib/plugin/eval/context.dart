import 'package:dart_eval/dart_eval.dart';
import 'package:gengen/plugin/eval/generator.dart';
import 'package:gengen/plugin/eval/model.dart';
import 'package:gengen/plugin/eval/site_data.dart';

class PluginContext {
  Compiler compiler;
  Map<String, String>? source;
  String name;
  Runtime? runtime;

  PluginContext.create({
    this.name = "gengen",
    this.source = const {},
    Map<String, Map<String, String>> packages = const {},
  }) : compiler = Compiler() {
    compiler.defineBridgeClasses([
      $Base.$declaration,
      $Site.$declaration,
      $Plugin$bridge.$declaration,
    ]);

    final sources = {name: source!, ...packages};
    final program = compiler.compile(sources);

    runtime = Runtime.ofProgram(program)
      ..registerBridgeFunc(
        'package:gengen/site.dart',
        'Site.instance*g',
        $Site.$instance,
      )
      ..registerBridgeFunc(
        'package:gengen/site.dart',
        'Site.',
        $Site.$new,
      )
      ..registerBridgeFunc(
        'package:gengen/models/base.dart',
        'Base.',
        $Base.$new,
      )
      ..registerBridgeFunc(
        'package:gengen/plugin/plugin.dart',
        'BasePlugin.',
        $Plugin$bridge.$new,
        isBridge: true,
      );
  }

  dynamic run(
    String func, {
    String packageEntryPoint = 'package:plugin/main.dart',
    List<dynamic> args = const [],
  }) {
    return runtime?.executeLib(packageEntryPoint, func, args);
  }
}
