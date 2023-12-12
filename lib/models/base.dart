import 'dart:core';
import 'dart:io';

import 'package:gengen/content/tokenizer.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/models/permalink_structure.dart';
import 'package:gengen/models/url.dart';
import 'package:gengen/renderer.dart';
import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart';
import 'package:more/collection.dart';
import 'package:path/path.dart' as p;

class Base {
  late Site _site;

  final Set<String> sassExtensions = const {".sass", ".scss"};
  final Set<String> htmlExtensions = const {'.html', '.xhtml', '.htm'};
  final Set<String> markdownExtensions = const {'.md', '.markdown'};

  bool isPost = true;

  Directory? destination;

  Map<String, dynamic> dirConfig = const {};

  late String name;
  late String source;
  late String content;

  Map<String, dynamic> frontMatter = {};

  Map<String, dynamic> defaultMatter = {};

  Map<String, dynamic> get config => _config();

  Renderer get renderer => Renderer(this);

  String get ext => p.extension(source);

  Site get site => _site;

  bool get isSass => sassExtensions.contains(ext);

  bool get isHtml => htmlExtensions.contains(ext);

  bool get isMarkdown => markdownExtensions.contains(ext);

  bool get hasLiquid => containsLiquid(content);

  bool get isAsset => isSass;

  String get layout => config["layout"] as String? ?? "";

  Base.fromYaml(
    this.frontMatter,
    this.source,
    this.content, [
    this.dirConfig = const {},
    this.destination,
  ]);

  Base(this.source, this._site, [this.name = ""]) {
    read();
  }

  String link([Directory? dst]) {
    if (dst != null) {
      destination = dst;

      return p.joinAll([dst.path, permalink()]);
    }

    return p.joinAll([destination!.path, permalink()]);
  }

  void read() {
    String fileContent = readFileSafe(source);
    var loadedContent = toContent(fileContent);
    dirConfig = getDirectoryFrontMatter(source) ?? {};
    frontMatter = loadedContent.frontMatter;
    content = loadedContent.content;
    name = source.removePrefix(site.config.source + p.separator);
  }

  void write(Directory destination) {
    var file = File(link(destination));
    file
        .create(recursive: true)
        .then((file) async => file.writeAsString(await renderer.render()))
        .then((value) {

      log.info("written $relativePath -> ${p.relative(link())}");
    });
  }

  Map<String, dynamic> _config() {
    Map<String, dynamic> config = Map.from(dirConfig);

    defaultMatter.forEach((key, value) {
      config[key] = value;
    });

    frontMatter.forEach((key, value) {
      config[key] = value;
    });

    return config;
  }

  String get relativePath {
    return p.relative(source, from: site.config.source);
  }

  Map<String, dynamic> get data => {
        "page": {
          ...config,
          "debug":{
            "source": source,
            "name": name,
          },
        },
      };

  late String template;

  String get url {
    return URL(
      template: template,
      placeholders: urlPlaceholders,
      permalink: permalink(),
    ).toString();
  }

  Map<String, dynamic> get urlPlaceholders {
    return {
      // 'path': dir,
      'basename': name,
      'output_ext': ext,
    };
  }
}
