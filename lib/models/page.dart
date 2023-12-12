import 'dart:io';

import 'package:gengen/models/base.dart';
import 'package:gengen/models/permalink_structure.dart';
import 'package:path/path.dart';

class Page extends Base {
  @override
  bool get isPost => false;

  bool get isIndex => withoutExtension(basename(name)) == 'index';

  Page(super.source, super.site) {
    defaultMatter.addAll({"permalink": PermalinkStructure.post});
  }

  @override
  void write(Directory destination) {
    if (isIndex) return super.write(destination);
    var newDestination = joinAll([destination.path, withoutExtension(name)]);
    name = setExtension("index", ext);
    
    return super.write(Directory(newDestination));
  }
}
