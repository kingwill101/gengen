import 'dart:io';

import 'package:console/console.dart';
import 'package:gengen/content/content.dart';
import 'package:gengen/generator/generator.dart';
import 'package:gengen/generator/handlers.dart';
import 'package:gengen/generator/shared/handlers.dart';
import 'package:gengen/models.dart';
import 'package:gengen/pipeline/pipeline.dart';
import 'package:gengen/utilities.dart';

class PageGenerator extends Generator<Page> {
  PageGenerator(String source, Directory? outputDir,
      {super.extensions = const ["html", "liquid", "md", "markdown"],
      super.ignoreDirs = const ["assets", "posts", "templates", "public"]})
      : super(source: source, destination: outputDir);

  @override
  Future<PageGenerator> transform() async {
    for (var source in sources) {
      var fileContent = await readFile(source);
      if (fileContent == null) {
        continue;
      }

      var content = toContent(fileContent);
      if (content == null) {
        continue;
      }

      var directoryFrontMatter = getDirectoryFrontMatter(source) ?? {};

      directoryFrontMatter.addAll({"permalink": PermalinkStructure.post});

      var page = Page.fromYaml(content.frontMatter, source,
          content.content ?? "", directoryFrontMatter, destination);

      collection.add(page);
    }
    return this;
  }

  @override
  Future<Generator<Page>> write() async {
    Console.setTextColor(Color.WHITE.id, bright: true);

    for (var item in collection) {
      Pipeline<Base> pipeline = Pipeline(item, [LiquidWriter(), HtmlWriter()]);

      pipeline.handle();
    }

    return this;
  }

  static Pipeline<Generator> pipeline(PageGenerator generator) {
    return Pipeline<Generator>(
        generator, [CollectHandler(), TransformHandler(), WriteHandler()]);
  }
}
