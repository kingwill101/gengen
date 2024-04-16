import 'dart:io';

import 'package:console/console.dart';
import 'package:gengen/commands/command_runner.dart';
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

    handle_command(arguments);

}
