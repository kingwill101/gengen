import 'package:gengen/models/base.dart';
import 'package:gengen/utilities.dart';
import 'package:liquify/liquify.dart';
import 'package:markdown/markdown.dart' as md;

class DocumentDrop extends Drop {
  Base content;

  @override
  List<Symbol> get invokable => <Symbol>[
    #content,
    #output,
    #title,
    #permalink,
    #url,
    #relative_path,
    #path,
    #excerpt,
    #date,
    #summary,
    #next,
    #previous,
  ];

  DocumentDrop(this.content);

  @override
  Map<String, dynamic> get attrs => {
    ...content.frontMatter,
    "layout": content.layout,
    "collection": content.collectionLabel,
    "collection_label": content.collectionLabel,
    "relative_path": content.relativePath,
    "path": content.relativePath,
    "url": _url(),
    "next": content.next?.to_liquid,
    "previous": content.previous?.to_liquid,
    "debug": {"source": content.source, "name": content.name},
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
      case #output:
        return content.renderer.content;
      case #title:
        return content.config["title"];
      case #permalink:
        final link = content.link();
        if (link.startsWith('/')) {
          return link;
        }
        return '/$link';
      case #url:
        return _url();
      case #relative_path:
      case #path:
        return content.relativePath;
      case #excerpt:
        if (content.isMarkdown) {
          return extractExcerpt(md.markdownToHtml(content.content));
        }
        return extractExcerpt(content.content);
      case #date:
        return content.date;
      case #summary:
        return extractExcerpt(content.content);
      case #next:
        return content.next?.to_liquid;
      case #previous:
        return content.previous?.to_liquid;
      default:
        return null;
    }
  }

  String _url() {
    var link = content.link();
    if (link.startsWith('/')) {
      link = link.substring(1);
    }
    if (link.endsWith('/index.html')) {
      final trimmed = link.substring(0, link.length - 'index.html'.length);
      return '/$trimmed';
    }
    return '/$link';
  }
}
