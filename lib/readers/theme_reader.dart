import 'dart:io';

import 'package:gengen/fs.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/models/theme_asset.dart';
import 'package:gengen/reader.dart';
import 'package:gengen/site.dart';

class ThemeReader {
  List<Base> unfilteredContent = [];

  ThemeReader();

  List<Base> read() {
    unfilteredContent.clear(); // Clear any previous content
    
    if (!site.theme.loaded) return [];
    
    var files = Reader().filterSpecial(site.theme.root);

    for (var file in files) {
      if (fs.isDirectorySync(file)) {
        continue;
      }
      if (file.startsWith(site.theme.layoutsPath)) {
        continue;
      }
      
      final themeAsset = ThemeAsset(file);
      unfilteredContent.add(themeAsset);
    }

    return unfilteredContent;
  }
}
