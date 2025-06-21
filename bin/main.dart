import 'dart:io';

import 'package:console/console.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:gengen/commands/command_runner.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/di.dart';

void main(List<String> arguments) async {
  // await Sentry.init((options) {
  //   options.diagnosticLevel = SentryLevel.debug;
  //   options.dsn =
  //       'https://c41e8a714ca2b857d485d614e6164cad@o4506952189739008.ingest.us.sentry.io/4508188359720960';
  //   // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
  //   // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
  //   // We recommend adjusting this value in production.
  //   options.tracesSampleRate = 1.0;
  // });

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

  await handle_command(arguments);
}
