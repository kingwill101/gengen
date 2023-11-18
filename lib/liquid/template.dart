import 'dart:io';

import 'package:liquid_engine/liquid_engine.dart' as liquid;
import 'package:path/path.dart';

class Template {
  String template;

  String? child;

  Map<String, dynamic> data;

  final context = liquid.Context.create();

  liquid.Root contentRoot;

  Template(this.template,
      {this.child,
      this.data = const {},
      this.contentRoot = const ContentRoot()});

  Template.r(this.template, this.child, this.data,
      {this.contentRoot = const ContentRoot()});

  Future<String> render() async {
    context.variables.addAll(data);

    if (child != null) {
      child = await parse(child!);
      context.variables["content"] = child;
    }

    return liquid.Template.parse(
            context, liquid.Source(null, template, contentRoot))
        .render(context);
  }

  Future<String> parse(String content) {
    return liquid.Template.parse(
            context, liquid.Source(null, content, contentRoot))
        .render(context);
  }
}

class ContentRoot implements liquid.Root {
  const ContentRoot();

  @override
  Future<liquid.Source> resolve(String relPath) async {
    String path = joinAll([current, "partials", relPath]);

    final file = Uri.file(path);
    final content = await File(path).readAsString();

    return liquid.Source(file, content, this);
  }
}
