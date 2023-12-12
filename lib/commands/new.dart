import 'dart:async';

import 'package:gengen/commands/abstract_command.dart';

class New extends AbstractCommand {
  @override
  String get description => "Create site or theme from template";

  @override
  String get name => "new";

  @override
  FutureOr<void>? run() {}
}
