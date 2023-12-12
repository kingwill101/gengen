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
}
