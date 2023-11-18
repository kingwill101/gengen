import 'package:gengen/liquid/template.dart';
import 'package:liquid_engine/liquid_engine.dart' as liquid;
import 'package:test/test.dart';

class TestRoot implements liquid.Root {
  Map<String, String> files;

  TestRoot(this.files);

  @override
  Future<liquid.Source> resolve(String relPath) async {
    return liquid.Source(null, files[relPath]!, this);
  }
}

void main() {
  test('template', () async {
    final root = TestRoot({
      'header.html': 'header',
    });

    var template = Template("{% include 'header.html' %}", contentRoot: root);
    var result = await template.render();
    expect(result, "header");
  });
}
