import 'dart:io';

import 'package:markdown/markdown.dart';
import 'package:path/path.dart';
import 'package:toml/toml.dart';
import 'package:untitled/liquid/template.dart';
import 'package:untitled/markdown/mardown.dart';

import '../models.dart';

void gen({Directory? outputDir}) {
  List<Generator> generators = [
    PostGenerator(joinAll(["content", "posts"]), outputDir),
  ];

  for (var generator in generators) {
    generator
        .collect()
        .then((value) => value.transform().then((value) => value.write()));
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
      if (await _isDir(path)) {
        continue;
      }

      String ext = basename(path).split(".").last;

      if (!extensions.contains(ext)) {
        continue;
      }
      sources.add(path);
      print("path $path");
    }

    return content;
  }

  Future<Generator<T>> transform();

  Future<Generator<T>> write();

  Future<bool> _isDir(String path) {
    return Directory(path).exists();
  }

  Future<String?> _readFile(String path) async {
    var file = File(path);
    if (!await file.exists()) {
      return null;
    }

    return file.readAsString();
  }
}

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
}

class PostGenerator extends Generator<Post> {
  PostGenerator(String source, Directory? outputDir,
      {super.extensions = const ["md"]})
      : super(source: source, destination: outputDir);

  @override
  Future<PostGenerator> transform() async {
    for (var path in sources) {
      var fileContent = await _readFile(path);
      if (fileContent == null) {
        continue;
      }
      var markdown = markdownContent(fileContent);
      if (markdown == null) {
        continue;
      }

      Map<String, dynamic> fontMatter = <String, dynamic>{};
      try {
        fontMatter =
            parseFrontMatter(markdown.frontmatter!).cast<String, dynamic>();
      } catch (exc) {
        try {
          fontMatter = TomlDocument.parse(markdown.frontmatter!).toMap();
        } catch (e) {
          print("[TOML] Unable to read front matter, giving up");
          return this;
        }
      }

      var post = Post.fromYaml(fontMatter, path, markdown.content ?? "");
      collection.add(post);
    }
    return this;
  }

  @override
  Future<PostGenerator> write() async {
    for (var item in collection) {
      if (destination == null) {
        continue;
      }

      Template(item.content, null, {}).render().then((content) {
        var fileDestination = joinAll(
            [destination!.path, withoutExtension(item.source), "index.html"]);

        var file = File(fileDestination);
        file
            .create(recursive: true)
            .then((file) => file.writeAsString(markdownToHtml(content)))
            .then((value) {
          print("written ${item.source} -> $fileDestination");
        });
      });
    }
    return this;
  }
}
