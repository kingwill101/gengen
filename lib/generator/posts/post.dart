import 'dart:io';

import 'package:console/console.dart';
import 'package:gengen/generator/generator.dart';
import 'package:gengen/generator/handlers.dart';
import 'package:gengen/generator/pipeline.dart';
import 'package:gengen/generator/posts/handlers.dart';
import 'package:gengen/markdown/mardown.dart';
import 'package:gengen/models.dart';
import 'package:gengen/utilities.dart';
import 'package:path/path.dart';
import 'package:toml/toml.dart';

class PostGenerator extends Generator<Post> {
  Map<String, Map<String, dynamic>> directoryDefaults;

  List<String> blockList = [];

  PostGenerator(String source, Directory? outputDir,
      {super.extensions = const ["md", "html"],
      this.blockList = const ["_index.md"],
      Map<String, Map<String, dynamic>>? directoryDefaults})
      : directoryDefaults = directoryDefaults ?? {},
        super(source: source, destination: outputDir);

  getFrontMatter(String matter) {
    Map<String, dynamic> frontMatter = <String, dynamic>{};
    try {
      frontMatter = parseFrontMatter(matter).cast<String, dynamic>();
    } catch (exc) {
      try {
        frontMatter = TomlDocument.parse(matter).toMap();
      } catch (e) {
        Console.setTextColor(Color.RED.id, bright: true);
        print("[TOML] Unable to read front matter, giving up");
        Console.setTextColor(Color.WHITE.id, bright: true);
        return {};
      }
    }

    return frontMatter;
  }

  Map<String, dynamic>? getDirectoryFrontMatter(String path) {
    var dir = dirname(path);

    if (directoryDefaults.containsKey(dir)) {
      return directoryDefaults[dir];
    }

    directoryDefaults[dir] = {};

    var index = File(joinAll([dir, "_index.md"]));

    if (!index.existsSync()) {
      return {};
    }

    var content = index.readAsStringSync();

    var markdown = markdownContent(content);
    if (markdown == null) {
      return {};
    }

    var matter = getFrontMatter(markdown.frontmatter ?? "");
    directoryDefaults[dir] = matter;

    return matter;
  }

  @override
  Future<PostGenerator> transform() async {
    for (var path in sources) {
      var fileContent = await readFile(path);
      if (fileContent == null) {
        continue;
      }

      if (blockList.contains(basename(path)) ||
          basename(path).startsWith(RegExp(r'^[-_*]'))) {
        continue;
      }
      var markdown = markdownContent(fileContent);
      if (markdown == null) {
        continue;
      }

      var contentFrontMatter = getFrontMatter(markdown.frontmatter ?? "");

      var directoryFrontMatter = getDirectoryFrontMatter(path);

      var post = Post.fromYaml(contentFrontMatter, path, markdown.content ?? "",
          directoryFrontMatter ?? {}, destination);
      collection.add(post);
    }
    return this;
  }

  @override
  Future<PostGenerator> write() async {
    Console.setTextColor(Color.WHITE.id, bright: true);

    for (var item in collection) {
      Pipeline<Post> pipeline = Pipeline(item, [LiquidWriter(), HtmlWriter()]);

      pipeline.handle();
    }
    return this;
  }

  static Pipeline<Generator> pipeline(PostGenerator postGenerator) {
    return Pipeline<Generator>(
        postGenerator, [CollectHandler(), TransformHandler(), WriteHandler()]);
  }
}
