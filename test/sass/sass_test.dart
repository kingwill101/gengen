import 'dart:io';

import 'package:gengen/sass/sass.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('compileSass compiles a simple scss file', () {
    final tempDir = Directory.systemTemp.createTempSync('gengen-sass');
    final inputPath = p.join(tempDir.path, 'main.scss');

    File(inputPath).writeAsStringSync(r'''
$color: #f00;
.button {
  color: $color;
}
''');

    final result = compileSass(inputPath);

    expect(result.css, contains('.button'));
    expect(result.css, contains('color: #f00'));

    tempDir.deleteSync(recursive: true);
  });
}
