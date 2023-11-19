import 'dart:io';

import 'package:gengen/generator/page/page.dart';
import 'package:gengen/generator/posts/post.dart';
import 'package:test/test.dart';

void main() {
  test("generators", () {
    PostGenerator postGenerator = PostGenerator("", Directory.current);
    assert(postGenerator.extensions.isNotEmpty);

    PageGenerator pageGenerator = PageGenerator("", Directory.current);
    assert(pageGenerator.extensions.isNotEmpty);
  });
}
