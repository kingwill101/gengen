import 'dart:io';

import 'package:console/console.dart';
import 'package:gengen/content/content.dart';
import 'package:gengen/generator/generator.dart';
import 'package:gengen/generator/handlers.dart';
import 'package:gengen/generator/shared/handlers.dart';
import 'package:gengen/models.dart';
import 'package:gengen/pipeline/pipeline.dart';
import 'package:gengen/utilities.dart';
import 'package:path/path.dart';

class PostGenerator extends Generator<Post> {
  List<String> blockList = [];

  PostGenerator(String source, Directory? outputDir,
      {super.extensions = const ["md", "markdown", "liquid", "html"],
      this.blockList = const ["_index.md"],
      Map<String, Map<String, dynamic>>? directoryDefaults})
      : super(source: source, destination: outputDir);

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

      var content = toContent(fileContent);
      if (content == null) {
        continue;
      }

      var directoryFrontMatter = getDirectoryFrontMatter(path);

      var post = Post.fromYaml(content.frontMatter, path, content.content ?? "",
          directoryFrontMatter ?? {}, destination);

      collection.add(post);
    }
    return this;
  }

  @override
  Future<PostGenerator> write() async {
    Console.setTextColor(Color.WHITE.id, bright: true);

    for (var item in collection) {
      Pipeline<Base> pipeline = Pipeline(item, [LiquidWriter(), HtmlWriter()]);

      pipeline.handle();
    }
    return this;
  }

  static Pipeline<Generator> pipeline(PostGenerator postGenerator) {
    return Pipeline<Generator>(
        postGenerator, [CollectHandler(), TransformHandler(), WriteHandler()]);
  }
}
