import 'dart:io';

import 'package:console/console.dart';
import 'package:gengen/generator/generator.dart';
import 'package:gengen/pipeline/pipeline.dart';
import 'package:gengen/models.dart';

import 'handlers.dart';

class StaticGenerator extends Generator<Post> {
  StaticGenerator(String source, Directory? outputDir,
      {super.extensions = const ["js", "css", "jpeg", "jpg", "png"]})
      : super(source: source, destination: outputDir);

  @override
  Future<StaticGenerator> write() async {
    Console.setTextColor(Color.WHITE.id, bright: true);

    print("Copying assets");
    Console.setTextColor(Color.GREEN.id, bright: true);

    for (var source in sources) {
      print(source);
    }

    return this;
  }

  static Pipeline<Generator> pipeline(StaticGenerator generator) {
    return Pipeline<Generator>(generator, [CollectHandler(), WriteHandler()]);
  }
}
