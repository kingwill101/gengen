import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:console/console.dart';
import 'package:gengen/config.dart';

import 'build.dart';

var config = loadConfig();

Future<void> main(List<String> arguments) async {
  Console.init();
  CommandRunner runner = CommandRunner("genny", "Static site generator")
    ..addCommand(BuildCommand());
  runner.run(arguments);
}
