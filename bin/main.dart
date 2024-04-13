import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:console/console.dart';
import 'package:gengen/commands/build.dart';
import 'package:gengen/commands/new.dart';
import 'package:gengen/commands/serve.dart';
import 'package:gengen/logging.dart';

void main(List<String> arguments) {
  log.info("Binary location ${Platform.resolvedExecutable}");
  Console.init();
  initLog();


  String banner = '''
 ██████╗ ███████╗███╗   ██╗       ██████╗ ███████╗███╗   ██╗
██╔════╝ ██╔════╝████╗  ██║      ██╔════╝ ██╔════╝████╗  ██║
██║  ███╗█████╗  ██╔██╗ ██║  ██  ██║  ███╗█████╗  ██╔██╗ ██║
██║   ██║██╔══╝  ██║╚██╗██║      ██║   ██║██╔══╝  ██║╚██╗██║
╚██████╔╝███████╗██║ ╚████║      ╚██████╔╝███████╗██║ ╚████║
 ╚═════╝ ╚══════╝╚═╝  ╚═══╝       ╚═════╝ ╚══════╝╚═╝  ╚═══╝
''';
  Console.setTextColor(Color.BLUE.id);
  print(banner);

  CommandRunner<void> runner =
      CommandRunner<void>("gengen", "Static site generator")
        ..addCommand(Build())
        ..addCommand(New())
        ..addCommand(Serve());
  runner.run(arguments);
}
