import 'package:gengen/fs.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/models/theme_asset.dart';
import 'package:gengen/models/theme_content_asset.dart';
import 'package:gengen/models/theme_page.dart';
import 'package:gengen/reader.dart';
import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart';
import 'package:path/path.dart' as p;

class ThemeContent {
  final List<Base> pages;
  final List<Base> assets;

  const ThemeContent({required this.pages, required this.assets});
}

class ThemeReader {
  List<Base> unfilteredContent = [];

  ThemeReader();

  ThemeContent read() {
    unfilteredContent.clear(); // Clear any previous content

    if (!site.theme.loaded) {
      return const ThemeContent(pages: [], assets: []);
    }

    final themeRoot = site.theme.root;
    final themeContentRoot = site.theme.pathFor('content');
    final hasContentRoot = fs.directory(themeContentRoot).existsSync();

    final files = Reader().filterSpecial(themeRoot);
    final pages = <Base>[];
    final assets = <Base>[];

    for (var file in files) {
      if (fs.isDirectorySync(file)) {
        continue;
      }
      if (file.startsWith(site.theme.layoutsPath)) {
        continue;
      }
      if (hasContentRoot && file.startsWith(themeContentRoot)) {
        continue;
      }

      final relativePath = p.relative(file, from: site.theme.root);
      final sitePath = p.join(site.root, relativePath);
      if (fs.file(sitePath).existsSync()) {
        continue;
      }

      final themeAsset = ThemeAsset(file);
      assets.add(themeAsset);
      unfilteredContent.add(themeAsset);
    }

    if (hasContentRoot) {
      final contentFiles = Reader().filterSpecial(themeContentRoot);
      for (var file in contentFiles) {
        if (fs.isDirectorySync(file)) {
          continue;
        }

        final relativePath = p.relative(file, from: themeContentRoot);
        final sitePath = p.join(site.root, relativePath);
        if (fs.file(sitePath).existsSync()) {
          continue;
        }

        if (hasYamlHeader(file)) {
          final themePage = ThemePage(file, contentRoot: themeContentRoot);
          pages.add(themePage);
          unfilteredContent.add(themePage);
        } else {
          final themeAsset = ThemeContentAsset(
            file,
            contentRoot: themeContentRoot,
          );
          assets.add(themeAsset);
          unfilteredContent.add(themeAsset);
        }
      }
    }

    return ThemeContent(pages: pages, assets: assets);
  }
}
