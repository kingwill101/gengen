import 'package:gengen/commands/abstract_command.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/site.dart';

class Build extends AbstractCommand {
  @override
  String get description => "Build static site";

  @override
  String get name => "build";

  @override
  Future<void> start() async {
    log.info(" Starting build\n");
    try {
      await Site.instance.process();
    } on Exception catch (e, _) {
      log.severe(e.toString());
    }
  }
}
