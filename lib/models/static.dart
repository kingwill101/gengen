import 'dart:io';

import 'package:gengen/logging.dart';
import 'package:gengen/models/base.dart';
import 'package:path/path.dart';

class Static extends Base {
  Static(super.source, super.site);

  void copyWrite(String path) {
    File(!isSass ? path : setExtension(path, ".css"))
        .create(recursive: true)
        .then((file) async {
      return isSass
          ? file.writeAsString(await renderer.render())
          : File(source).copy(file.path);
    }).then((value) {
      log.info("written $source -> ${value.path}");
    });
  }

  @override
  void write(Directory destination) {
    var path = join(destination.path, name);
    copyWrite(path);
  }
}
