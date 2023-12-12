import 'dart:io';

import 'package:gengen/entry_filter.dart';
import 'package:gengen/layout.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart';

class LayoutReader {
  Site site;
  var layouts = <String, Layout>{};

  LayoutReader(this.site);

  Map<String, Layout> read() {
    layoutEntries().forEach((layoutFile) {
      var name = site.relativeToRoot(withoutExtension(layoutFile));
      layouts[name] =
          Layout(site, layoutFile, name, ext: extension(layoutFile));
    });

    themeLayoutEntries().forEach((layoutFile) {
      var name =  site.theme.relativeToRoot(withoutExtension(layoutFile));
      layouts[name] =
          Layout(site, layoutFile, name, ext: extension(layoutFile));
    });

    return layouts;
  }

  List<String> layoutEntries() {
    var directory = Directory(site.layoutsPath);
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

    return EntryFilter(site).filter(entries);
  }

  List<String> themeLayoutEntries() {
    var directory = Directory(site.theme.layoutsPath);
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

    return EntryFilter(site).filter(entries);
  }

}
