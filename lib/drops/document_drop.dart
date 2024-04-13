import 'package:gengen/models/base.dart';
import 'package:gengen/utilities.dart';
import 'package:intl/intl.dart';
import 'package:liquid_engine/liquid_engine.dart';

class DocumentDrop extends Drop {
  Base content;

  @override
  List<Symbol> get invokable =>
      <Symbol>[#content, #title, #permalink, #excerpt, #date];

  DocumentDrop(this.content);

  @override
  Map<String, dynamic> get attrs => {
        "debug": {
          "source": content.source,
          "name": content.name,
        },
      };

  @override
  dynamic invoke(Symbol symbol) {

    /**
     * {
        page: {
        inputPath: './test1.md',
        url: '/test1/',
        date: new Date(),
        // … and everything else in Eleventy’s `page`
        },
        data: { title: 'Test Title', tags: ['tag1', 'tag2'], date: 'Last Modified', /* … */ },
        content: '<h1>Test Title</h1>\n\n<p>This is text content…',
        // Pre-release only: v3.0.0-alpha.1
        rawInput: '<h1>{{ title }}</h1>\n\n<p>This is text content…',
        }
     */
    switch (symbol) {
      case #content:
        return content.renderer.content;
      case #title:
        return content.config["title"];
      case #permalink:
        return content.link();
      case #excerpt:
        return extractExcerpt(content.renderer.content);
      case #date:
        return DateFormat.yMMMMEEEEd().format(content.date);
      default:
        return null;
    }
  }
}
