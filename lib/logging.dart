import 'package:console/console.dart';
import 'package:logging/logging.dart';

final log = Logger('GenGen');

void initLog() {
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
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}
