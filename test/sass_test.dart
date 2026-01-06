import 'dart:io';

import 'package:gengen/sass/sass.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('compileSass compiles a simple file', () {
    final tempDir = Directory.systemTemp.createTempSync('gengen-sass');
    final input = File(p.join(tempDir.path, 'main.scss'))
      ..writeAsStringSync(r'''
$primary: #ff0000;
.button {
  color: $primary;
}
''');

    final result = compileSass(input.path);
    expect(result.css, contains('.button'));
    expect(result.css, contains('color: #ff0000'));

    tempDir.deleteSync(recursive: true);
  });
}
