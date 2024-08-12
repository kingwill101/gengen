import 'dart:convert';

import 'package:gengen/commands/abstract_command.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/site.dart';

class Dump extends AbstractCommand {
  Dump() {
    argParser.addOption(
      "file",
      help: "Output file",
      abbr: "f",
      defaultsTo: null,
    );
  }

  @override
  String get description => "Dump site data";

  @override
  String get name => "dump";

  @override
  Future<void> start() async {
    log.info(" dumping");

    final dump = await site.dump();
    JsonEncoder encoder = JsonEncoder.withIndent('  ');
    final encoded = encoder.convert(dump);

    if (argResults?['file'] != null) {
      fs.file(argResults!['file'] as String).writeAsStringSync(encoded);
      log.info(" dumped to ${argResults!['file']}");
    } else {
      print(encoded);
    }
  }
}
