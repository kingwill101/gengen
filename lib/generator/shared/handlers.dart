import 'dart:async';
import 'dart:io';

import 'package:console/console.dart';
import 'package:gengen/liquid/template.dart';
import 'package:gengen/models.dart';
import 'package:gengen/pipeline/pipeline.dart';
import 'package:markdown/markdown.dart';

class HtmlWriter extends Handle<Base> {
  @override
  void handle(Base data, HandleFunc<Base> next) {

    var file = File(data.link());
    file
        .create(recursive: true)
        .then((file) => file.writeAsString(markdownToHtml(data.content)))
        .then((value) {
      Console.setTextColor(Color.GREEN.id, bright: true);

      print("written ${data.source} -> ${data.link()}");
    });
  }
}

class LiquidWriter<T> extends Handle<Base> {
  @override
  Future<void> handle(Base data, HandleFunc<Base> next) async {
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
