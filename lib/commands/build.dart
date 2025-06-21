import 'package:gengen/commands/abstract_command.dart';
import 'package:gengen/commands/arg_extension.dart';
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
      // Check if a positional argument was provided as source directory
      if (argResults?.rest.isNotEmpty == true) {
        final sourceDir = argResults!.rest.first;
        log.info("Using source directory: $sourceDir");
        Site.resetInstance();
        Site.init(overrides: {
          ...argResults?.map ?? {},
          'source': sourceDir,
        });
      }
      
      await site.process();
      log.info("Build complete\n");
    } on Exception catch (e, s) {
      log.severe(e.toString(), e, s);
    }
  }
}
