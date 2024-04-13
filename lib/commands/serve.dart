import 'dart:async';

import 'package:gengen/commands/abstract_command.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/router.dart';
import 'package:gengen/site.dart';

class Serve extends AbstractCommand {
  @override
  String get description => "Build static site";

  @override
  String get name => "serve";

  @override
  Future<FutureOr<void>?> start() async {
    try {
      Site.instance.process();
      Site.instance.watch();
      route();
    } on Exception catch (e, _) {
      log.severe(e.toString());
    }
  }
}
