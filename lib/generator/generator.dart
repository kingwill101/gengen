import 'dart:io';

import 'package:gengen/generator/page/page.dart';
import 'package:gengen/generator/posts/post.dart';
import 'package:gengen/pipeline/pipeline.dart';
import 'package:path/path.dart';

void gen({Directory? outputDir}) {
  List<Pipeline<Generator>> pipelines = [
    PostGenerator.pipeline(PostGenerator("posts", outputDir)),
    PageGenerator.pipeline(PageGenerator(current, outputDir)),
    StaticGenerator.pipeline(StaticGenerator(joinAll(["static"]), outputDir))
  ];

  for (var pipeline in pipelines) {
    pipeline.handle();
  }
}

abstract class Generator<T> {
  static Map<String, Map<String, dynamic>> directoryDefaults = {};
  String source;
  List<String> sources = [];
  List<T> collection = [];

  List<String> extensions;

  Directory? destination;

  List<String> ignoreDirs;

  Generator(
      {required this.source,
      this.destination,
      this.ignoreDirs = const [],
      this.extensions = const []});

  Future<List<String>> _mapContent(String directory) async {
    Directory root = Directory(directory);

    if (!root.existsSync()) {
      return [];
    }

    List<String> listing = [];
    await root.list(recursive: true).forEach((FileSystemEntity entry) {
      var value = entry.path;

      bool shouldSkip = false;

      for (var blocked in this.ignoreDirs) {
        if (value.startsWith(joinAll([current, blocked]))) {
          shouldSkip = true;
          break;
        }
      }

      if (shouldSkip) {
        return;
      }

      if (Directory(value).existsSync()) {
        return;
      }

      String ext = basename(value).split(".").last;

      if (!extensions.contains(ext)) {
        return;
      }

      listing.add(value);
    });

    return listing;
  }

  Future<Generator<T>> collect() async {
    sources = await _collect();
    return this;
  }

  Future<List<String>> _collect() async {
    return await _mapContent(source);
  }

  Future<Generator<T>> transform() async {
    return this;
  }

  Future<Generator<T>> write();
}
