import 'package:gengen/entry_filter.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/readers/data_reader.dart';
import 'package:gengen/readers/layout_reader.dart';
import 'package:gengen/readers/page_reader.dart';
import 'package:gengen/readers/plugin_reader.dart';
import 'package:gengen/readers/post_reader.dart';
import 'package:gengen/readers/static_reader.dart';
import 'package:gengen/readers/theme_reader.dart';
import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart';
import 'package:more/collection.dart';
import 'package:path/path.dart';

class Reader {
  List<String> getEntries(String dir, [String subfolder = ""]) {
    var base = Site.instance.inSourceDir(join(dir, subfolder));
    var directory = fs.directory(base);

    if (!directory.existsSync()) {
      return [];
    }

    var entries = directory
        .listSync(recursive: true)
        .whereType<File>()
        .map((entity) => relative(entity.path, from: base))
        .toList();

    entries = EntryFilter().filter(entries);

    entries.removeWhere((entry) {
      var fullPath = join(base, entry);

      return fs.directory(fullPath).existsSync();
    });

    return entries;
  }

  void readDirs() {
    List<String> dotPages = [];
    List<String> dotStaticFiles = [];

    var entries = filterSpecial(Site.instance.root);

    for (var fileEntity in entries) {
      if (EntryFilter().isSpecial(fileEntity)) continue;
      if (fs.directory(fileEntity).existsSync()) continue;

      if (fs.file(fileEntity).existsSync() && hasYamlHeader(fileEntity)) {
        dotPages.add(fileEntity);
      } else {
        dotStaticFiles.add(fileEntity);
      }
    }
    readPosts();
    readPages(dotPages);
    readStaticFiles(dotStaticFiles);
  }

  void readPosts() {
    Site.instance.posts = PostReader().readPosts(
      Site.instance.postPath,
    );
  }

  void read() {
    readData();
    Site.instance.layouts = LayoutReader().read();
    readDirs();
    readPlugins();
  }

  void readPlugins() {
    Site.instance.plugins.addAll(
      PluginReader().read(),
    );
  }

  void readData() {
    DataReader().read();
  }

  void readPages(List<String> dotPages) {
    PageReader().read(dotPages).forEach((page) {
      var search =
          Site.instance.pages.where((element) => element.source == page.source);
      if (search.isEmpty) {
        Site.instance.pages.add(page);
      }
    });
  }

  void readStaticFiles(List<String> dotStaticFiles) {
    var files = [
      ...ThemeReader().read(),
      ...StaticReader().read(dotStaticFiles)
    ];
    for (var file in files) {
      var search = Site.instance.staticFiles
          .where((element) => element.source == file.source);
      if (search.isEmpty) {
        Site.instance.staticFiles.add(file);
      }
    }
  }

  List<String> filterSpecial(String base) {
    var directory = fs.directory(base);
    var filter = EntryFilter();

    return filter
        .filter(
      directory.listSync(recursive: true).map((e) => e.path).toList(),
    )
        .where((entry) {
      var parts = split(entry.removePrefix(base));

      return !parts.any((part) => filter.isSpecial(part));
    }).toList();
  }

  List<String> filter(String base) {
    var directory = fs.directory(base);
    var filter = EntryFilter();

    return filter
        .filter(
          directory.listSync(recursive: true).map((e) => e.path).toList(),
        )
        .toList();
  }
}
