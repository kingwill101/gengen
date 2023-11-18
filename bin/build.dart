
import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart';
import 'package:untitled/generator/generator.dart';

class BuildCommand extends Command {
  @override
  String get description => "Build static site";

  @override
  String get name => "build";

  BuildCommand() {
    argParser.addOption("output", help: "Output directory");
    argParser.addOption("working-dir", help: "Working directory");
  }

  @override
  FutureOr? run() {
    print("Starting build");

    Directory.current =
        argResults?["working-dir"] as String? ?? joinAll([current]);

    var output =
        argResults?["output"] as String? ?? joinAll([current, "public"]);

    Directory outputDir = Directory(output);

    if (outputDir.existsSync()) {
      outputDir.deleteSync(recursive: true);
    }

    outputDir.create(recursive: true);

    gen(outputDir: outputDir);
  }
}
