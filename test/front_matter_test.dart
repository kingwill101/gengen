import 'package:gengen/content/tokenizer.dart';
import 'package:markdown/markdown.dart';
import 'package:test/test.dart';

void main() {
  test("front matter", () {
    String source = '''
---
title: "Society and Dancehall"
date: 2023-11-09T09:30:04-05:00
draft: false
tags: ["music", "dancehall"]
description: "An overview of the effects of dancehall and the jamaican culture"
---
this is the content
    ''';
    Content? content = toContent(source);

    String c = markdownToHtml(content.content);
    assert(c.isNotEmpty);
  });

  test("no front matter", () {
    String source = r'''
---
---

For any Jekyll site, a *build session* consists of discrete phases in the following order --- *setting up plugins,
reading source files, running generators, rendering templates*, and finally *writing files to disk*.

While the phases above are self-explanatory, the one phase that warrants dissection is *the rendering phase*.

    ''';
    Content? content = toContent(source);
    assert(content.frontMatter.isEmpty);
    assert(content.content.isNotEmpty);
  });
}
