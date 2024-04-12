import 'dart:core';
import 'dart:io';

import 'package:gengen/content/tokenizer.dart';
import 'package:gengen/drops/document_drop.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/models/permalink_structure.dart';
import 'package:gengen/renderer/renderer.dart';
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
  bool isPage = false;
  bool isStatic = false;
  Directory? destination;

  Map<String, dynamic> dirConfig = const {};

  late String name;
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

  Base(
    this.source, {
    this.site,
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
    String fileContent = readFileSafe(source);
    var loadedContent = toContent(fileContent);

    //config from _index.md located in the same directory
    dirConfig = getDirectoryFrontMatter(source) ?? {};

    //config found in post/page front matter
    frontMatter = loadedContent.frontMatter;

    content = loadedContent.content;
    name = source.removePrefix(site!.config.source + p.separator);
    renderer = Renderer(this);
  }

  String get destinationPath {
    var destiny = destination ?? site!.destination;

    if (isPost && !isIndex) {
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

    var file = File(filePath);

    file.create(recursive: true).then((file) async {
      return isPost || isPage
          ? file.writeAsString(await renderer.render())
          : file.writeAsString(content);
    }).then((value) {
      log.info("written $relativePath -> ${link()}");
    });
  }

  Map<String, dynamic> _config() {
    Map<String, dynamic> config = Map.from(dirConfig);

    defaultMatter.forEach((key, value) {
      config[key] = value;
    });

    // global default
    // directory configs has _index.md
    // page default

    frontMatter.forEach((key, value) {
      config[key] = value;
    });

    return config;
  }

  String get relativePath {
    return p.relative(source, from: site?.config.source);
  }

  Map<String, dynamic> _data() {
    var d = {
      "page": {
        ...config,
        'content': renderer.content,
        'permalink': link(),
        "debug": {
          "source": source,
          "name": name,
        },
      },
    };

    return d;
  }

  Map<String, dynamic> get data => _data();

  late String template;

  DocumentDrop get to_liquid => DocumentDrop(this);

  @override
  void onFileChange() {
    //listing pages will have stale content if we don't  process everything
    Site.instance.process();
    Site.instance.notifyFileChange(filePath);
  }
}
