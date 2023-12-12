import 'dart:io';

import 'package:gengen/models/base.dart';
import 'package:gengen/models/theme_asset.dart';
import 'package:gengen/reader.dart';
import 'package:gengen/site.dart';

class ThemeReader {
  final Site site;
  List<Base> unfilteredContent = [];

  ThemeReader(this.site);

  List<Base> read() {
    var files = Reader(site).filterSpecial(site.theme.root);

    for (var file in files) {
      if (FileStat.statSync(file).type == FileSystemEntityType.directory) {
        continue;
      }
      unfilteredContent.add(ThemeAsset(file, site));
    }
    
    return unfilteredContent;
  }
}
