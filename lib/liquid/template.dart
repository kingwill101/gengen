import 'dart:async';
import 'dart:io';

import 'package:gengen/liquid/modules/data_module.dart';
import 'package:gengen/liquid/modules/url_module.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/md/md.dart';
import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart';
import 'package:glob/glob.dart';
import 'package:liquid_engine/liquid_engine.dart' as liquid;
import 'package:path/path.dart' as p;

class Template {
  String template;

  String child;

  Map<String, dynamic> data;

  final context = liquid.Context.create();

  liquid.Root? contentRoot;

  Template.r(
    this.template, {
    this.child = "",
    this.data = const {},
    this.contentRoot = const ContentRoot(),
  }) {
    Map<String, liquid.Module> modules = {
      "data": DataModule(),
      "url": UrlModule(),
    };

    modules.forEach((key, value) {
      context.modules[key] = value;
      context.modules[key]!.register(context);
    });
  }

  Future<String> render() async {
    context.variables.addAll(data);

    child = await parse(child);
    context.variables["content"] = child;

    return parse(template);
  }

  Future<String> parse(String content) async {
    Completer<String> c = Completer();

    try {
      liquid.Template.parse(
        context,
        liquid.Source(null, content, contentRoot),
      )
          .render(context)
          .then((value) => c.complete(value))
          .onError((error, stackTrace) {
        log.severe(error);
      }).catchError((Object err) {
        log.severe(err);
        c.completeError(err);
      });
    } catch (err, stacktrace) {
      log.severe(err);
      log.severe(stacktrace);
      c.completeError(err);
    }

    return c.future;
  }
}

class ContentRoot implements liquid.Root {
  const ContentRoot();

  @override
  Future<liquid.Source> resolve(String relPath) async {
    var paths = [Site.instance.includesPath, Site.instance.theme.includesPath];

    for (var dirPath in paths) {
      var directory = Directory(dirPath);
      if (!directory.existsSync()) continue;

      var globPattern = Glob("$relPath.*");

      var fileSystemEntities = directory.listSync(recursive: true);
      for (var entity in fileSystemEntities) {
        if (entity is File &&
            globPattern.matches(p.relative(entity.path, from: dirPath))) {
          if (p.basenameWithoutExtension(entity.path) ==
              p.basenameWithoutExtension(relPath)) {
            var fileContent = readFileSafe(entity.path);

            return liquid.Source(null, renderMd(fileContent), this);
          }
        }
      }
    }

    log.warning("Include: $relPath not found");

    return liquid.Source(null, '', this);
  }
}
