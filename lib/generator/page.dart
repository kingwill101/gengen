import 'dart:io';

import 'package:gengen/generator/generator.dart';
import 'package:gengen/generator/handlers.dart';
import 'package:gengen/generator/pipeline.dart';
import 'package:gengen/models.dart';

class PageGenerator extends Generator<Page> {
  PageGenerator(String source, Directory? outputDir,
      {super.extensions = const ["html", "liquid"]})
      : super(source: source, destination: outputDir);

  @override
  Future<PageGenerator> transform() {
    // TODO: implement transform
    throw UnimplementedError();
  }

  @override
  Future<Generator<Page>> write() {
    // TODO: implement write
    throw UnimplementedError();
  }

  static Pipeline<Generator> pipeline(PageGenerator generator) {
    return Pipeline<Generator>(
        generator, [CollectHandler(), TransformHandler(), WriteHandler()]);
  }
}
