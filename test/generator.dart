import 'dart:io';

import 'package:test/test.dart';
import 'package:untitled/generator/generator.dart';
import 'package:untitled/markdown/mardown.dart';

void main() {
  test("generators", () {
    PostGenerator postGenerator = PostGenerator("", Directory.current);
    assert(postGenerator.extensions.isNotEmpty);

    PageGenerator pageGenerator = PageGenerator("", Directory.current);
    assert(pageGenerator.extensions.isNotEmpty);

  });
}
