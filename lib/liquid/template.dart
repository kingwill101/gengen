import 'dart:io';

import 'package:gengen/logging.dart';
import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart';
import 'package:glob/glob.dart';
import 'package:liquid_engine/liquid_engine.dart' as liquid;
import 'package:path/path.dart' as p;

class Template {
  String template;

  String child;

  late Site site;

  Map<String, dynamic> data;

  final context = liquid.Context.create();

  liquid.Root? contentRoot;

  Template(
    this.template, {
    this.child = "",
    this.data = const {},
    required this.contentRoot,
  });

  Template.r(
    this.template, {
    this.child = "",
    this.data = const {},
    required this.contentRoot,
  });

  Future<String> render() async {
    context.variables.addAll(data);

    child = await parse(child);
    context.variables["content"] = child;

    return liquid.Template.parse(
      context,
      liquid.Source(null, template, contentRoot),
    ).render(context);
  }

  Future<String> parse(String content) {
    return liquid.Template.parse(
      context,
      liquid.Source(null, content, contentRoot),
    ).render(context);
  }
}

class ContentRoot implements liquid.Root {
  Site site;

  ContentRoot(this.site);

  @override
  Future<liquid.Source> resolve(String relPath) async {
    var paths = [site.includesPath, site.theme.includesPath];

    for (var dirPath in paths) {
      var directory = Directory(dirPath);
      if (!directory.existsSync()) continue;

      var globPattern = Glob("${p.basename(relPath)}.*");

      var fileSystemEntities = directory.listSync();
      for (var entity in fileSystemEntities) {
        if (entity is File &&
            globPattern.matches(p.relative(entity.path, from: dirPath))) {
          if (p.basenameWithoutExtension(entity.path) ==
              p.basenameWithoutExtension(relPath)) {
            var fileContent = readFileSafe(entity.path);

            return liquid.Source(Uri.file(entity.path), fileContent, this);
          }
        }
      }
    }

    log.warning("Include: $relPath not found");

    return liquid.Source(null, '', this);
  }
}
