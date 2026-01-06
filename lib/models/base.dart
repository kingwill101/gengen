import 'dart:core';

import 'package:gengen/content/tokenizer.dart';
import 'package:gengen/drops/document_drop.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/liquid/template.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/models/permalink_structure.dart';
import 'package:gengen/renderer.dart';
import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart';
import 'package:gengen/watcher.dart';
import 'package:more/collection.dart';
import 'package:path/path.dart' as p;
import 'package:path/path.dart';

class Base with WatcherMixin {
  final Set<String> sassExtensions = const {".sass", ".scss"};
  final Set<String> htmlExtensions = const {'.html', '.xhtml', '.htm'};
  final Set<String> markdownExtensions = const {'.md', '.markdown'};

  bool isPost = false;
  bool outputEnabled = true;
  String collection = '';
  Base? previous;
  Base? next;

  bool isDraft() {
    if (config.containsKey("draft") && config["draft"] is bool) {
      return config["draft"] as bool;
    }

    return false;
  }

  bool get isPublished {
    if (config.containsKey("published") && config["published"] is bool) {
      return config["published"] as bool;
    }
    return true;
  }

  bool get isFutureDated {
    return date.isAfter(DateTime.now());
  }

  bool get shouldWrite {
    if ((isPost || isCollection) && !isPublishable) {
      return false;
    }
    if (isCollection && !outputEnabled) {
      return false;
    }
    return true;
  }

  bool get isPublishable {
    final includeUnpublished =
        site.config.get<bool>('unpublished', defaultValue: false) ?? false;
    if (!includeUnpublished && !isPublished) {
      return false;
    }
    final includeFuture =
        site.config.get<bool>('future', defaultValue: false) ?? false;
    if (!includeFuture && isFutureDated) {
      return false;
    }
    return true;
  }

  Map<String, Object> toJson() {
    return {
      "name": name,
      "config": config,
      "relativePath": relativePath,
      "filePath": filePath,
      "ext": ext,
      "isPost": isPost,
      "isCollection": isCollection,
      "collection": collectionLabel,
      "output": outputEnabled,
      "isDraft": isDraft(),
      "isStatic": isStatic,
      "isAsset": isAsset,
      "isPage": isPage,
      "permalink": permalink(),
      "frontMatter": frontMatter,
    };
  }

  bool isPage = false;
  bool isStatic = false;
  Directory? destination;

  Map<String, dynamic> dirConfig = const {};

  late String name;
  @override
  late String source;
  late String content;

  Map<String, dynamic> frontMatter = {};

  Map<String, dynamic> defaultMatter = {};

  Map<String, dynamic> get config => _config();

  late Renderer renderer;

  String get ext => p.extension(source);

  bool get isSass => sassExtensions.contains(ext);

  bool get isHtml => htmlExtensions.contains(ext);

  bool get isMarkdown {
    final result =
        markdownExtensions.contains(ext) || containsMarkdown(content);
    log.info("isMarkdown check for $source: $result");
    return result;
  }

  bool get hasLiquid => containsLiquid(content);

  bool get isAsset => isSass;

  String get layout => config["layout"] as String? ?? "";

  bool get isIndex => withoutExtension(basename(name)) == 'index';

  bool get isCollection => collection.isNotEmpty && !isPost && !isPage;

  String get collectionLabel {
    if (collection.isNotEmpty) return collection;
    if (isPost) return 'posts';
    if (isPage) return 'pages';
    return '';
  }

  String get pathPlaceholder => p.relative(p.dirname(source), from: site.root);

  DateTime get date {
    if (!config.containsKey("date")) {
      return DateTime.now();
    }
    final rawDate = config["date"];
    if (rawDate is DateTime) {
      return rawDate;
    }
    if (rawDate is int) {
      return DateTime.fromMillisecondsSinceEpoch(rawDate);
    }
    return parseDate(
      rawDate.toString(),
      format: site.config.get("date_format"),
    );
  }

  Base(
    this.source, {
    this.name = "",
    this.frontMatter = const {},
    this.dirConfig = const {},
    this.destination,
  }) {
    if (source.isEmpty) return;
    read();
  }

  String link() {
    return permalink();
  }

  void read() {
    metadata["last_modified"] = FileStat.statSync(
      source,
    ).modified.millisecondsSinceEpoch;
    metadata["size"] = FileStat.statSync(source).size;

    String fileContent = readFileSafe(source);
    var loadedContent = toContent(fileContent);

    //config from _index.md located in directory hierarchy
    //starting in _posts
    dirConfig = walkDirectoriesAndGetFrontMatters(
      site.relativeToSource(source),
    );

    //config found in post/page front matter
    frontMatter = loadedContent.frontMatter;

    populateDerivedFrontMatter();

    //loop properties and check if values contain liquid templates
    for (var key in frontMatter.keys) {
      if (containsLiquid(frontMatter[key].toString())) {
        frontMatter[key] = GenGenTempate.r(
          frontMatter[key].toString(),
          data: config,
        );
      }
    }

    content = cleanUpContent(loadedContent.content);
    name = source.removePrefix(site.config.source + p.separator);
    renderer = Renderer(this);
  }

  String get destinationPath {
    var destiny = destination ?? site.destination;

    // TODO: Review this logic - it seems to be incorrectly modifying the name
    // which affects permalink generation
    // if (isPage && !isIndex) {
    //   name = setExtension("index", ext);
    // }

    return destiny.path;
  }

  Future<void> copyWrite() async {
    final outputPath = !isSass ? filePath : setExtension(filePath, ".css");
    final file = await fs.file(outputPath).create(recursive: true);
    if (isSass) {
      await file.writeAsString(await renderer.render());
    } else {
      await fs.file(source).copy(file.path);
    }
    log.info("copied $source to ${file.absolute}");
  }

  String get filePath => join(destinationPath, link());

  Future<void> render() async {
    final start = DateTime.now();
    log.info("attempting to render $relativePath");
    if (isPost || isPage || isCollection || (isStatic && isSass)) {
      log.info("rendering $relativePath");
      await renderer.render();
    }
    final duration = DateTime.now().difference(start);
    log.info(
      "render completed for $relativePath in ${duration.inMilliseconds}ms",
    );
  }

  Future<void> write() async {
    final start = DateTime.now();
    if (isStatic && isSass) {
      await copyWrite();
      final duration = DateTime.now().difference(start);
      log.info(
        "write completed for $relativePath in ${duration.inMilliseconds}ms",
      );
      return;
    }

    if (isStatic && !isSass && ext == '.css') {
      final hasSassTwin = site.staticFiles.any((asset) {
        if (!asset.isSass) return false;
        final sassOutputPath = setExtension(asset.filePath, '.css');
        return sassOutputPath == filePath;
      });
      if (hasSassTwin) {
        log.info(
          'Skipping $relativePath because a Sass asset will generate ${p.basename(filePath)}',
        );
        return;
      }
    }
    log.info("trying to write $relativePath");
    File file = await fs.file(filePath).create(recursive: true);

    var fileContent = (isPost || isPage || (isCollection && !isStatic))
        ? renderer.content
        : content;
    if (isPost) {
      log.fine(
        'Writing post $relativePath snippet: '
        '${fileContent.substring(0, fileContent.length > 60 ? 60 : fileContent.length)}',
      );
    }
    await file.writeAsString(fileContent);
    final duration = DateTime.now().difference(start);
    log.info("written $relativePath in ${duration.inMilliseconds}ms");
    log.info("\t\t-> ${link()}");
    log.info("\t\t-> ${file.absolute}");
  }

  Map<String, dynamic> _config() {
    Map<String, dynamic> config = {};
    for (var element in [
      defaultMatter,
      site.config.all,
      dirConfig,
      frontMatter,
    ]) {
      config = deepMerge(config, element);
    }
    return config;
  }

  String get relativePath {
    if (isPost || isCollection) {
      return p.relative(source, from: site.collectionsPath);
    }
    return p.relative(source, from: site.config.source);
  }

  DocumentDrop get to_liquid => DocumentDrop(this);

  @override
  void onFileChange() {
    //listing pages will have stale content if we don't  process everything
    site.process();
    site.notifyFileChange(filePath);
  }

  void populateDerivedFrontMatter() {
    if (!isCollection && !isPost) {
      return;
    }

    final filename = p.basename(source);
    final basename = p.basenameWithoutExtension(filename);
    final dateMatch = RegExp(
      r'^(\d{2,4}-\d{1,2}-\d{1,2})-(.+)$',
    ).firstMatch(basename);

    String derivedSlug = basename;
    if (dateMatch != null) {
      final dateValue = dateMatch.group(1);
      final slugValue = dateMatch.group(2);
      if (dateValue != null &&
          (!frontMatter.containsKey('date') ||
              frontMatter['date'] == null ||
              frontMatter['date'].toString().isEmpty)) {
        frontMatter['date'] = dateValue;
      }
      if (slugValue != null && slugValue.isNotEmpty) {
        derivedSlug = slugValue;
      }
    }

    derivedSlug = derivedSlug.replaceAll(RegExp(r'\.*$'), '');
    final explicitSlug = frontMatter['slug']?.toString().trim() ?? '';
    final slugForTitle = explicitSlug.isNotEmpty ? explicitSlug : derivedSlug;

    if (!frontMatter.containsKey('slug') ||
        frontMatter['slug'] == null ||
        frontMatter['slug'].toString().isEmpty) {
      frontMatter['slug'] = derivedSlug;
    }

    if (!frontMatter.containsKey('title') ||
        frontMatter['title'] == null ||
        frontMatter['title'].toString().isEmpty) {
      frontMatter['title'] = _titleizeSlug(slugForTitle);
    }
  }

  String _titleizeSlug(String slug) {
    if (slug.isEmpty) return '';
    final words = slug
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'));
    return words
        .map(
          (word) =>
              word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }
}
