import 'dart:async';
import 'dart:io';

import 'package:console/console.dart';
import 'package:gengen/generator/pipeline.dart';
import 'package:gengen/liquid/template.dart';
import 'package:gengen/models.dart';
import 'package:markdown/markdown.dart';
import 'package:path/path.dart';

class HtmlWriter extends Handle<Post> {
  @override
  void handle(Post data, HandleFunc<Post> next) {
    var fileDestination = joinAll(
        [data.destination!.path, withoutExtension(data.source), "index.html"]);

    var file = File(fileDestination);
    file
        .create(recursive: true)
        .then((file) => file.writeAsString(markdownToHtml(data.content)))
        .then((value) {
      Console.setTextColor(Color.GREEN.id, bright: true);

      print("written ${data.source} -> $fileDestination");
    });
  }
}

class LiquidWriter extends Handle<Post> {
  @override
  Future<void> handle(Post data, HandleFunc<Post> next) async {
    try {
      data.content = await Template(data.content).render();
    } catch (e) {
      Console.setTextColor(Color.RED.id, bright: true);

      print("Unable to write content\n");
      print(" source - ${data.source}");
      Console.setTextColor(Color.WHITE.id, bright: true);

      print(" ---CONTENT---");
      print(data.content);
      print(" ---\\CONTENT---");
    }

    next(data);
  }
}
