import 'package:gengen/liquid/template.dart';
import 'package:gengen/md/md.dart';
import 'package:liquid_engine/liquid_engine.dart' as liquid;
import 'package:test/test.dart';

void main() {
  group("Templates", () {
    test('template include tag', () async {
      final root = TestRoot({
        'header.html': 'header',
      });

      var template =
          Template.r("{% include 'header.html' %}", contentRoot: root);
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
          '''{% assign my_age = 1 %} {%- render 'header_with.html' with my_age as age -%}''',
          'header 1'
        ),
      ];
      for (var t in tests) {
        var result = await Template.r(t.$1, contentRoot: root).render();
        expect(result, t.$2);
      }
    });
  });

  group("filters", () {
    test('append', () async {
      var result = await Template.r('{{"1+" | append: "1" }}', contentRoot: TestRoot({})).render();
      expect(result, '1+1');
    });

    test("getJson", () async {
      var json =
      '''
      {% assign arguments = 'https://dummyjson.com/products/1' %}
      {{ "https://dummyjson.com/products/1" | getJson: endpoint }}
      ''';

      var result = await Template.r(json, contentRoot: TestRoot({})).render();
      expect(result, '');
    });
  });

  group(' markdown' , (){
    test('correct shortcode', () {
      var result = renderMd("[ shortcode 'partials/media/twitter' url='https://twitter.com/duttyberryshow/status/1616150633077145615' width='560' height='315' ]");
      assert(result.isNotEmpty);
    });
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
