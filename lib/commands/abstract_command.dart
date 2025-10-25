import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:gengen/commands/arg_extension.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart';

abstract class AbstractCommand extends Command<void> {
  AbstractCommand() {
    argParser.addOption(
      "config",
      help: "config files (comma separated)",
      defaultsTo: null,
    );

    argParser.addOption("source", help: "site directory", defaultsTo: current);
    argParser.addOption("theme", help: "site theme", defaultsTo: "default");
    argParser.addOption("themes_dir", help: "Directory containing themes");
    argParser.addOption("destination", help: "Output directory");
  }

  @override
  Future<void> run() async {
    final overrides = <String, dynamic>{...?argResults?.map};

    if (argResults?.rest.isNotEmpty == true) {
      overrides['source'] = argResults!.rest.first;
    }

    Site.init(overrides: overrides);
    var result = start();
    if (result is Future<void>) {
      await result;
    }
  }

  FutureOr<void> start();
}
