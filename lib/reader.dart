import 'package:gengen/entry_filter.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/readers/data_reader.dart';
import 'package:gengen/readers/collection_reader.dart';
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

  Future<void> readDirs() async {
    List<String> dotPages = [];
    List<String> dotStaticFiles = [];

    var entries = filterSpecial(Site.instance.root);

    for (var fileEntity in entries) {
      if (await fs.directory(fileEntity).exists()) continue;

      if (await fs.file(fileEntity).exists() && hasYamlHeader(fileEntity)) {
        dotPages.add(fileEntity);
      } else {
        dotStaticFiles.add(fileEntity);
      }
    }
    await readPosts();
    await readCollections();
    readPages(dotPages);
    readStaticFiles(dotStaticFiles);
  }

  Future<void> readPosts() async {
    Site.instance.posts = PostReader().readPosts(
      Site.instance.postPath,
    );
  }

  Future<void> readCollections() async {
    Site.instance.setCollections(CollectionReader().read());
  }

  Future<void> read() async {
    await readData();
    Site.instance.layouts = await LayoutReader().read();
    await readDirs();
    await readPlugins();
  }

  Future<void> readPlugins() async {
    Site.instance.plugins.addAll(
      await PluginReader().read(),
    );
  }

  Future<void> readData() async {
    await DataReader().read();
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

    final allFiles = directory.listSync(recursive: true).map((e) => e.path).toList();
    final filteredFiles = filter.filter(allFiles);

    return filteredFiles.where((entry) {
      var parts = split(entry.removePrefix(base));
      return !parts.any((part) => filter.isSpecial(part));
    }).toList();
  }

  Future<List<String>> filter(String base) async {
    var directory = fs.directory(base);

    if (!await directory.exists()) {
      return [];
    }
    
    var filter = EntryFilter();

    return filter
        .filter(
          await directory.list(recursive: true).map((e) => e.path).toList(),
        )
        .toList();
  }
}
