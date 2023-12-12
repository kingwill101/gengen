import 'dart:async';

import 'package:gengen/logging.dart';
import 'package:gengen/site.dart';
import 'package:gengen/commands/abstract_command.dart';

class Build extends AbstractCommand {
  @override
  String get description => "Build static site";

  @override
  String get name => "build";

  @override
  FutureOr<void>? run() {
    log.info(" Starting build\n");

    try {
      var site = Site(config);
      site.process();
    } on Exception catch (e, _) {
      log.severe(e.toString());
    }
    // gen(outputDir: outputDir);
  }
}
