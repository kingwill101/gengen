import 'dart:async';

import 'package:args/args.dart';
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

extension ArgResultExtension on ArgResults {
  Map<String, dynamic> get map => _config();

  Map<String, dynamic> _config() {
    Map<String, dynamic> results = {};

    for (var element in options) {
      if (element == "help") continue;
      results[element] =
          element == "config" ? this[element].split(",") : this[element];
    }

    return results;
  }
}
