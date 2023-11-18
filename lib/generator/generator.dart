import 'dart:io';

import 'package:gengen/generator/pipeline.dart';
import 'package:gengen/generator/posts/post.dart';
import 'package:gengen/generator/static.dart';
import 'package:gengen/utilities.dart';
import 'package:path/path.dart';

void gen({Directory? outputDir}) {
  List<Pipeline<Generator>> pipelines = [
    PostGenerator.pipeline(
        PostGenerator(joinAll(["content", "posts"]), outputDir)),
    StaticGenerator.pipeline(StaticGenerator(joinAll(["static"]), outputDir))
  ];

  for (var pipeline in pipelines) {
    pipeline.handle();
  }
}

abstract class Generator<T> {
  String source;
  List<String> sources = [];
  List<T> collection = [];

  List<String> extensions;

  Directory? destination;

  Generator(
      {required this.source, this.destination, this.extensions = const []});

  Future<List<String>> _mapContent(String directory) async {
    Directory root = Directory(directory);
    List<String> listing = [];
    await root.list(recursive: true).forEach((FileSystemEntity entry) {
      listing.add(entry.path);
    });
    return listing;
  }

  Future<Generator<T>> collect() async {
    await _collect();
    return this;
  }

  Future<List<String>> _collect() async {
    var content = await _mapContent(source);
    for (var path in content) {
      if (await isDir(path)) {
        continue;
      }

      String ext = basename(path).split(".").last;

      if (!extensions.contains(ext)) {
        continue;
      }
      sources.add(path);
    }

    return content;
  }

  Future<Generator<T>> transform() async {
    return this;
  }

  Future<Generator<T>> write();
}
