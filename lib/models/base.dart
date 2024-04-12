import 'dart:core';
import 'dart:io';

import 'package:gengen/content/tokenizer.dart';
import 'package:gengen/drops/document_drop.dart';
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

  bool isDraft() {
    if (config.containsKey("draft") && config["draft"] is bool) {
      return config["draft"] as bool;
    }

    return false;
  }

  void handleAlias(File value) {
    if (!value.existsSync()) return;
    if (config.containsKey("aliases") && config["aliases"] is List) {
      for (var alias in config["aliases"] as List) {
        try {
          var dest = File(p.join(destinationPath,
              p.setExtension(alias as String, p.extension(filePath))));
          dest.createSync(recursive: true);
          dest.writeAsStringSync(value.readAsStringSync());
        } on Exception catch (_, e) {
          log.warning("Failed to create alias '$alias': $e");
        }
      }
    }
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

  bool get isMarkdown =>
      markdownExtensions.contains(ext) || containsMarkdown(content);

  bool get hasLiquid => containsLiquid(content);

  bool get isAsset => isSass;

  String get layout => config["layout"] as String? ?? "";

  bool get isIndex => withoutExtension(basename(name)) == 'index';

  DateTime get date {
    if (!config.containsKey("date")) {
      return DateTime.fromMicrosecondsSinceEpoch(0);
    }
    var date = DateTime.parse(config["date"] as String);

    return date;
  }

  Base(
    this.source, {
    this.name = "",
    this.frontMatter = const {},
    this.dirConfig = const {},
    this.destination,
  }) {
    read();
  }

  String link() {
    return permalink();
  }

  void read() {
    metadata["last_modified"] =
        FileStat.statSync(source).modified.millisecondsSinceEpoch;
    metadata["size"] = FileStat.statSync(source).size;

    String fileContent = readFileSafe(source);
    var loadedContent = toContent(fileContent);

    //config from _index.md located in directory hierarchy
    //starting in _posts
    dirConfig = walkDirectoriesAndGetFrontMatters(
        Site.instance.relativeToSource(source));

    //config found in post/page front matter
    frontMatter = loadedContent.frontMatter;

    content = cleanUpContent(loadedContent.content);
    name = source.removePrefix(Site.instance.config.source + p.separator);
    renderer = Renderer(this);
  }

  String get destinationPath {
    var destiny = destination ?? Site.instance.destination;

    if (isPage && !isIndex) {
      name = setExtension("index", ext);
    }

    return destiny.path;
  }

  void copyWrite() {
    File(!isSass ? filePath : setExtension(filePath, ".css"))
        .create(recursive: true)
        .then((file) async {
      if (isSass) {
        return file.writeAsString(await renderer.render());
      }

      return File(source).copy(file.path);
    }).then((value) {
      log.info("written $source -> ${value.path}");
    });
  }

  String get filePath => join(destinationPath, link());

  void write() {
    if (isStatic) return copyWrite();

    File file = File(filePath);
    file.create(recursive: true).then((file) async {
      var fileContent = isPost || isPage ? await renderer.render() : content;
      return file.writeAsString(fileContent);
    }).then((value) {
      log.info("written $relativePath -> ${link()}");
      //only call when path is null to prevent
      handleAlias(value);
    });
  }

  Map<String, dynamic> _config() {
    Map<String, dynamic> config = Map.from(dirConfig);
    for (var element in [defaultMatter, dirConfig, frontMatter]) {
      element.forEach((key, value) {
        config[key] = value;
      });
    }

    return config;
  }

  String get relativePath {
    return p.relative(source, from: Site.instance.config.source);
  }

  DocumentDrop get to_liquid => DocumentDrop(this);

  @override
  void onFileChange() {
    //listing pages will have stale content if we don't  process everything
    Site.instance.process();
    Site.instance.notifyFileChange(filePath);
  }
}
