import 'package:gengen/liquid/template.dart';
import 'package:gengen/md/md.dart';
import 'package:gengen/utilities.dart';
import 'package:liquify/liquify.dart' as liquid;
import 'package:test/test.dart';

void main() {
  group("Templates", () {
    test('template include tag', () {
      final root = liquid.MapRoot({
        'header.html': 'header',
        'bottom/footer.html': 'footer',
      });

      var template =
          GenGenTempate.r("{% include 'header.html' %}", contentRoot: root);
      var result = template.render();
      expect(result, "header");
    });

    // test('template include without quotes', () {
    //   final root = liquid.MapRoot({
    //     'bottom/footer.html': 'footer',
    //   });

    //   final template = GenGenTempate.r("{% include bottom/footer.html %}",
    //       contentRoot: root);
    //   final result = template.render();
    //   expect(result, "footer");
    // });

    test('template render tag', () {
      final root = liquid.MapRoot({
        'header.html': 'header',
        'header_with.html': 'header {{ age }}',
      });

      var tests = [
        (
          '''{% assign my_age = 1 %} {%- render 'header_with.html', age: my_age -%}''',
          'header 1'
        ),
      ];
      for (var t in tests) {
        var result = GenGenTempate.r(t.$1, contentRoot: root).render();
        expect(result, t.$2);
      }
    });
  });

  group("filters", () {
    test('append', () {
      var result = GenGenTempate.r('{{"1+" | append: "1" }}',
          contentRoot: liquid.MapRoot({})).render();
      expect(result, '1+1');
    });

    test('date', () {
      final root = liquid.MapRoot({});
      var test = '''{{ site.time | date: 'y' }}''';
      var result = GenGenTempate.r(test, contentRoot: root, data: {
        'site': {'time': DateTime.now()}
      }).render();
      expect(result, DateTime.now().year.toString());
    });

    test("getJson", ()  {
      var json = r'''
      {%- assign product_data = 'https://dummyjson.com/products/1' | get_json -%}
      {{- product_data.id -}}
      ''';

      var result =
          GenGenTempate.r(json, contentRoot: liquid.MapRoot({})).render();
      expect(result, '1');
    });
  });

  group(' markdown', () {
    test('correct shortcode', () {
      var result = renderMd(
          "[ shortcode 'partials/media/twitter' url='https://twitter.com/duttyberryshow/status/1616150633077145615' width='560' height='315' ]");
      assert(result.isNotEmpty);
    });
  });

  test('contains Liquid', () {
    assert(containsLiquid('{{ site.time | date: "%Y-%m-%d" }}'));
  });
}
