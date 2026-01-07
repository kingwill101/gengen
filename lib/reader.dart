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
import 'package:gengen/models/base.dart';
import 'package:gengen/models/page.dart';
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
    final themeContent = ThemeReader().read();
    await readPosts();
    await readCollections();
    readPages(dotPages);
    readThemePages(themeContent.pages);
    readStaticFiles(dotStaticFiles, themeContent.assets);
  }

  Future<void> readPosts() async {
    Site.instance.posts = PostReader().readPosts(Site.instance.postPath);

    // Also read index pages from _posts directory and add them to pages
    _readPostIndexPages();
  }

  void _readPostIndexPages() {
    final postDir = Site.instance.inSourceDir(Site.instance.postPath);
    final directory = fs.directory(postDir);

    if (!directory.existsSync()) return;

    // Look for index.html or index.md in _posts
    for (final ext in ['.html', '.md', '.markdown']) {
      final indexPath = join(postDir, 'index$ext');
      if (fs.file(indexPath).existsSync()) {
        final page = Page(indexPath);
        // Check if not already added
        final exists = Site.instance.pages.any((p) => p.source == page.source);
        if (!exists) {
          Site.instance.pages.add(page);
        }
        break; // Only add one index file
      }
    }
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
    Site.instance.plugins.addAll(await PluginReader().read());
  }

  Future<void> readData() async {
    final dataReader = DataReader();

    Map<String, dynamic> themeData = {};
    Map<String, dynamic> themePluginData = {};
    if (site.theme.loaded) {
      themeData = await dataReader.readFrom(site.theme.dataPath);
      themePluginData = await dataReader.readPluginData(site.theme.pluginPath);
    }

    final sitePluginData = await dataReader.readPluginData(site.pluginPath);
    final pluginData = deepMerge(themePluginData, sitePluginData);

    final siteData = await dataReader.readFrom(site.dataPath);
    var merged = deepMerge(pluginData, themeData);
    merged = deepMerge(merged, siteData);

    site.config.add("data", merged);
  }

  void readPages(List<String> dotPages) {
    PageReader().read(dotPages).forEach((page) {
      var search = Site.instance.pages.where(
        (element) => element.source == page.source,
      );
      if (search.isEmpty) {
        Site.instance.pages.add(page);
      }
    });
  }

  void readThemePages(List<Base> themePages) {
    for (final page in themePages) {
      var search = Site.instance.pages.where(
        (element) => element.source == page.source,
      );
      if (search.isEmpty) {
        Site.instance.pages.add(page);
      }
    }
  }

  void readStaticFiles(
    List<String> dotStaticFiles, [
    List<Base> themeAssets = const [],
  ]) {
    var files = [...themeAssets, ...StaticReader().read(dotStaticFiles)];

    for (var file in files) {
      var search = Site.instance.staticFiles.where(
        (element) => element.source == file.source,
      );
      if (search.isEmpty) {
        Site.instance.staticFiles.add(file);
      }
    }
  }

  List<String> filterSpecial(String base) {
    var directory = fs.directory(base);
    var filter = EntryFilter();

    final allFiles = directory
        .listSync(recursive: true)
        .map((e) => e.path)
        .toList();
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
