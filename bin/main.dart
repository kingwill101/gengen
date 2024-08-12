import 'dart:io';

import 'package:console/console.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:gengen/commands/command_runner.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/di.dart';

void main(List<String> arguments) {

  getIt.registerLazySingleton<FileSystem>(() => LocalFileSystem());

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
