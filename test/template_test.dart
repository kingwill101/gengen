import 'package:gengen/liquid/template.dart';
import 'package:liquid_engine/liquid_engine.dart' as liquid;
import 'package:test/test.dart';

void main() {
  test('template include tag', () async {
    final root = TestRoot({
      'header.html': 'header',
    });

    var template = Template("{% include 'header.html' %}", contentRoot: root);
    var result = await template.render();
    expect(result, "header");
  });

  test('template render tag', () async {
    final root = TestRoot({
      'header.html': 'header',
      'header_with.html': 'header {{ age }}',
    });

    var tests = [
      (
        '''{% assign my_age = 1 %} {% render 'header_with.html' with my_age as age%}''',
        'header 1'
      ),
      // ("{% render 'header.html' %}", 'header'),
    ];
    for (var t in tests) {
      var result = await Template(t.$1, contentRoot: root).render();
      expect(result, t.$2);
    }
  });
}

class TestRoot implements liquid.Root {
  Map<String, String> files;

  TestRoot(this.files);

  @override
  Future<liquid.Source> resolve(String relPath) async {
    return liquid.Source(null, files[relPath]!, this);
  }
}
