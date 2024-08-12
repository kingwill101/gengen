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

  bool isDraft() {
    if (config.containsKey("draft") && config["draft"] is bool) {
      return config["draft"] as bool;
    }

    return false;
  }

  Map<String, Object> toJson() {
    return {
      "name": name,
      "config": config,
      "relativePath": relativePath,
      "filePath": filePath,
      "ext": ext,
      "isPost": isPost,
      "isDraft": isDraft(),
      "isStatic": isStatic,
      "isAsset": isAsset,
      "isPage": isPage,
      "permalink": permalink(),
      "frontMatter": frontMatter,
    };
  }

  void handleAlias(File value) {
    if (!value.existsSync()) return;
    if (config.containsKey("aliases") && config["aliases"] is List) {
      for (var alias in (config["aliases"] as List)) {
        if ((alias as String).startsWith("/")) {
          alias = alias.substring(1);
        }

        final aliasDestination = p.joinAll(
            [destinationPath, p.setExtension(alias, p.extension(filePath))]);

        try {
          var dest = fs.file(aliasDestination);
          dest.createSync(recursive: true);
          dest.writeAsStringSync(value.readAsStringSync());
          log.fine("Created alias '$alias'");
          print("\t\t  -> '${dest.absolute}'");
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
    if (source.isEmpty) return;
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

    //loop properties and check if values contain liquid templates
    for (var key in frontMatter.keys) {
      if (containsLiquid(frontMatter[key].toString())) {
        frontMatter[key] =
            Template.r(frontMatter[key].toString(), data: config);
      }
    }

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
    fs
        .file(!isSass ? filePath : setExtension(filePath, ".css"))
        .create(recursive: true)
        .then((file) async {
      if (isSass) {
        return file.writeAsString(await renderer.render());
      }

      return fs.file(source).copy(file.path);
    }).then((value) {
      log.info("copied $source");
      print("\t\t-> ${value.absolute}");
    });
  }

  String get filePath => join(destinationPath, link());

  Future<void> write() async {
    if (isStatic) return copyWrite();

    File file = await fs.file(filePath).create(recursive: true);

    var fileContent = isPost || isPage ? await renderer.render() : content;
    await file.writeAsString(fileContent);
    log.info("written $relativePath");
    print("\t\t-> ${link()}");
    print("\t\t-> ${file.absolute}");
    //only call when path is null to prevent
    handleAlias(file);
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
