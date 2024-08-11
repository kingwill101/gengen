import 'package:dart_eval/dart_eval.dart';
import 'package:gengen/plugin/converter.dart';
import 'package:gengen/plugin/generator.dart';
import 'package:gengen/plugin/model.dart';
import 'package:gengen/plugin/site_data.dart';

class PluginContext {
  Compiler compiler;
  Map<String, String>? source;
  String name;
  Runtime? runtime;

  PluginContext.create({
    this.name = "gengen",
    this.source = const {},
  }) : compiler = Compiler() {
    compiler.defineBridgeClasses([
      $Base.$declaration,
      $Site.$declaration,
      $Converter$bridge.$declaration,
      $Generator$bridge.$declaration,
    ]);

    final program = compiler.compile({name: source!});

    runtime = Runtime.ofProgram(program)
      ..registerBridgeFunc(
          'package:gengen/site.dart', 'Site.instance*g', $Site.$instance)
      ..registerBridgeFunc(
          'package:gengen/site.dart', 'Site.', $Site.$new)
      ..registerBridgeFunc(
          'package:gengen/models/base.dart', 'Base.', $Base.$new)
      ..registerBridgeFunc('package:gengen/plugin/plugin.dart', 'Generator.',
          $Generator$bridge.$new,
          isBridge: true)
      ..registerBridgeFunc('package:gengen/plugin/plugin.dart', 'Converter.',
          $Converter$bridge.$new,
          isBridge: true);
  }

  dynamic run(
    String func, {
    String packageEntryPoint = 'package:plugin/main.dart',
    List<dynamic> args = const [],
  }) {
    return runtime?.executeLib(packageEntryPoint, func, args);
  }
}
