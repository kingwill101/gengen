import 'dart:isolate';

import 'package:gengen/fs.dart';
import 'package:rxdart/rxdart.dart';

mixin WatcherMixin {
  final Map<String, dynamic> metadata = <String, dynamic>{};

  bool shouldReload() {
    var stat = FileStat.statSync(source);
    if (stat.type == FileSystemEntityType.notFound) return false;

    if (metadata.containsKey("size") && stat.size != metadata["size"]) {
      return true;
    }

    if (metadata.containsKey("last_modified") &&
        stat.modified.millisecondsSinceEpoch != metadata["last_modified"]) {
      return true;
    }

    if ((metadata.containsKey("last_modified") &&
            metadata.containsKey("size")) &&
        stat.modified.millisecondsSinceEpoch == metadata["last_modified"] &&
        stat.size == metadata["size"]) {


      return false;
    }

    return true;
  }

  String get source;

  void watch() {
    final receivePort = ReceivePort();
    Isolate.spawn(
      _watchFile,
      {'source': source, 'sendPort': receivePort.sendPort},
    );

    receivePort
        .asBroadcastStream()
        .debounceTime(Duration(milliseconds: 500))
        .listen((message) {
      if (message is String && message == 'file_changed') {
        onFileChange();
      }
    });
  }

  static void _watchFile(Map<String, dynamic> args) {
    String source = args['source'] as String;
    SendPort sendPort = args['sendPort'] as SendPort;

    var file = fs.file(source);
    var stream = file.watch();

    stream.listen((event) {
      if (event.type == FileSystemEvent.modify) {
        sendPort.send('file_changed');
      }
    });
  }

  void onFileChange();
}
