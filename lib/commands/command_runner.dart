import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gengen/commands/build.dart';
import 'package:gengen/commands/dump.dart';
import 'package:gengen/commands/new.dart';
import 'package:gengen/commands/serve.dart';
import 'package:gengen/logging.dart';

Future<void> handle_command(List<String> args) async {
  await _GenGenCommandRunner().run(args);
}

class _GenGenCommandRunner extends CommandRunner<void> {
  _GenGenCommandRunner() : super("gengen", "Static site generator") {
    addCommand(Build());
    addCommand(New());
    addCommand(Serve());
    addCommand(Dump());
  }

  @override
  Future<void> run(Iterable<String> args) async {
    try {
      await super.run(args);
      exit(0);
    } catch (e) {
      log.info(e);
    }
  }
}
