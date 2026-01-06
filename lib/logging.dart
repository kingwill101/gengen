import 'package:console/console.dart';
import 'package:logging/logging.dart';

final log = Logger('GenGen');

void initLog() {
  Console.resetAll();
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((LogRecord record) {
    Color color;
    switch (record.level) {
      case Level.INFO:
        color = Color.WHITE;
        break;
      case Level.WARNING:
        color = Color.YELLOW;
        break;
      case Level.FINE:
        color = Color.GREEN;
        break;
      case Level.SEVERE:
        color = Color.RED;
        break;
      default:
        color = Color.WHITE;
        break;
    }
    Console.setTextColor(color.id);
    Console.write(
      '(${record.loggerName}) ${record.level.name}: ${record.time}: ${record.message}\n',
    );
    if (record.stackTrace != null) {
      Console.setTextColor(Color.RED.id);
      Console.write('${record.error}');
      Console.write('${record.stackTrace}');
      print(record.stackTrace.toString());
    }
  });
}
