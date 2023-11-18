import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:untitled/config.dart';

import 'build.dart';

var config = loadConfig();

Future<void> main(List<String> arguments) async {
  CommandRunner runner = CommandRunner("genny", "Static site generator")
    ..addCommand(BuildCommand());
  runner.run(arguments);
}
