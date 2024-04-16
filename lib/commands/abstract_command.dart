import 'dart:async';

import 'package:gengen/commands/arg_extension.dart';
import 'package:args/command_runner.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart';

abstract class AbstractCommand extends Command<void> {

  AbstractCommand() {

    argParser.addOption(
      "config",
      help: "config files (comma separated)",
      defaultsTo: "config.yaml",
    );

    argParser.addOption("source", help: "site directory", defaultsTo: current);
    argParser.addOption("theme", help: "site theme", defaultsTo: "default");
    argParser.addOption(
      "themes_dir",
      help: "Directory containing themes",
    );
    argParser.addOption(
      "destination",
      help: "Output directory",
    );
  }

  @override
  FutureOr<void>? run() {
    Site.init(overrides: argResults?.map ?? {});
    start();
  }

  void start();
}

