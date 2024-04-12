import 'dart:io';

import 'package:gengen/entry_filter.dart';
import 'package:gengen/layout.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart';

class LayoutReader {

  var layouts = <String, Layout>{};

  LayoutReader();

  Map<String, Layout> read() {
    layoutEntries().forEach((layoutFile) {
      var name = Site.instance.relativeToRoot(withoutExtension(layoutFile));
      layouts[name] =
          Layout(layoutFile, name, ext: extension(layoutFile));
    });

    themeLayoutEntries().forEach((layoutFile) {
      var name =  Site.instance.theme.relativeToRoot(withoutExtension(layoutFile));
      layouts[name] =
          Layout(layoutFile, name, ext: extension(layoutFile));
    });

    return layouts;
  }

  List<String> layoutEntries() {
    var directory = Directory(Site.instance.layoutsPath);
    if (!directory.existsSync()) {
      return [];
    }

    var entries = <String>[];
    var allEntities = directory.listSync(recursive: true, followLinks: false);

    for (var entity in allEntities) {
      if (entity is File &&
          entity.path.contains(RegExp(r'[^/\\]*[/\\][^/\\]*\..*'))) {
        entries.add(entity.path);
      }
    }

    return EntryFilter().filter(entries);
  }

  List<String> themeLayoutEntries() {
    var directory = Directory(Site.instance.theme.layoutsPath);
    if (!directory.existsSync()) {
      return [];
    }

    var entries = <String>[];
    var allEntities = directory.listSync(recursive: true, followLinks: false);

    for (var entity in allEntities) {
      if (entity is File &&
          entity.path.contains(RegExp(r'[^/\\]*[/\\][^/\\]*\..*'))) {
        entries.add(entity.path);
      }
    }

    return EntryFilter().filter(entries);
  }

}
