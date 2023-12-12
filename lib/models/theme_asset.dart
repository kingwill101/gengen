import 'dart:io';

import 'package:gengen/models/static.dart';
import 'package:path/path.dart';

class ThemeAsset extends Static {
  ThemeAsset(super.source, super.site);

  @override
  void write(Directory destination) {
    name = relative(source, from: site.theme.root);
    var path = join(destination.path, name);
    copyWrite(path);
  }
}
