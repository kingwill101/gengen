import 'dart:io';
import 'package:gengen/entry_filter.dart';
import 'package:gengen/readers/layout_reader.dart';
import 'package:gengen/readers/page_reader.dart';
import 'package:gengen/readers/post_reader.dart';
import 'package:gengen/readers/static_reader.dart';
import 'package:gengen/readers/theme_reader.dart';
import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart';
import 'package:more/collection.dart';
import 'package:path/path.dart';

class Reader {
  final Site _site;

  late PostReader postReader;
  late PageReader pageReader;
  late LayoutReader layoutReader;

  Site get site => _site;

  Reader(this._site) {
    postReader = PostReader(_site);
    pageReader = PageReader(_site);
    layoutReader = LayoutReader(_site);
  }

  List<String> getEntries(String dir, [String subfolder = ""]) {
    var base = site.inSourceDir(join(dir, subfolder));
    var directory = Directory(base);

    if (!directory.existsSync()) {
      return [];
    }

    var entries = directory
        .listSync(recursive: true)
        .whereType<File>()
        .map((entity) => relative(entity.path, from: base))
        .toList();

    entries = EntryFilter(site).filter(entries);

    entries.removeWhere((entry) {
      var fullPath = join(base, entry);

      return Directory(fullPath).existsSync();
    });

    return entries;
  }

  void readDirs() {
    List<String> dotPages = [];
    List<String> dotStaticFiles = [];

    var entries = filterSpecial(site.root);

    for (var fileEntity in entries) {
      if (EntryFilter(site).isSpecial(fileEntity)) continue;
      if (Directory(fileEntity).existsSync()) continue;

      if (File(fileEntity).existsSync() && hasYamlHeader(fileEntity)) {
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
    _site.posts = postReader.readPosts(site.postPath);
  }

  void read() {
    _site.layouts = layoutReader.read();
    readDirs();
  }

  void readPages(List<String> dotPages) {
    site.pages.addAll(PageReader(site).read(dotPages));
  }

  void readStaticFiles(List<String> dotStaticFiles) {
    site.staticFiles.addAll(StaticReader(site).read(dotStaticFiles));
    site.staticFiles.addAll(ThemeReader(site).read());
  }

  List<String> filterSpecial(String base) {
    var directory = Directory(base);
    var filter = EntryFilter(site);

    return filter
        .filter(
      directory.listSync(recursive: true).map((e) => e.path).toList(),
    )
        .where((entry) {
      var parts = split(entry.removePrefix(base));

      return !parts.any((part) => filter.isSpecial(part));
    }).toList();
  }
}
