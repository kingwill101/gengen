import 'package:gengen/entry_filter.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/layout.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart';

/// Responsible for reading and managing layout files for the site.
///
/// The LayoutReader class is responsible for reading and managing the layout files
/// for the site. It scans the layouts directory and the theme layouts directory
/// to find all available layouts, and stores them in a map for easy access.
///
class LayoutReader {
  var layouts = <String, Layout>{};

  LayoutReader();

  Future<Map<String, Layout>> read() async {
    layoutEntries().forEach((layoutFile) {
      var name = relative(withoutExtension(layoutFile), from: site.layoutsPath);
      layouts[name] = Layout(layoutFile, name, ext: extension(layoutFile));
    });

    themeLayoutEntries().forEach((layoutFile) {
      var name = relative(
        withoutExtension(layoutFile),
        from: site.theme.layoutsPath,
      );
      layouts[name] = Layout(layoutFile, name, ext: extension(layoutFile));
    });

    return layouts;
  }

  List<String> layoutEntries() {
    var directory = fs.directory(site.layoutsPath);
    if (!directory.existsSync()) {
      return [];
    }

    var entries = <String>[];
    var allEntities = directory.listSync(recursive: true, followLinks: false);

    for (var entity in allEntities) {
      if (entity is File) {
        entries.add(entity.path);
      }
    }

    return EntryFilter().filter(entries);
  }

  List<String> themeLayoutEntries() {
    if (!site.theme.loaded) return [];
    var directory = fs.directory(site.theme.layoutsPath);
    if (!directory.existsSync()) {
      return [];
    }

    var entries = <String>[];
    var allEntities = directory.listSync(recursive: true, followLinks: false);

    for (var entity in allEntities) {
      if (entity is File) {
        entries.add(entity.path);
      }
    }

    return EntryFilter().filter(entries);
  }
}
