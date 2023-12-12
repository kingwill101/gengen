import 'package:args/command_runner.dart';
import 'package:console/console.dart';
import 'package:gengen/commands/build.dart';
import 'package:gengen/commands/new.dart';
import 'package:gengen/logging.dart';

void main(List<String> arguments) {
  Console.init();

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

  initLog();
  CommandRunner<void> runner =
      CommandRunner<void>("gengen", "Static site generator")
        ..addCommand(Build())
        ..addCommand(New());
  runner.run(arguments);
}
