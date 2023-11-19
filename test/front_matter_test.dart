import 'package:markdown/markdown.dart';
import 'package:test/test.dart';
import 'package:gengen/content/content.dart';

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

    assert(content != null);
    assert(content?.frontMatter != null);
    assert(content?.content != null);

    String c = markdownToHtml(content!.content!);
    assert(c.isNotEmpty);
  });
}
