import 'package:gengen/liquid/template.dart';
import 'package:test/test.dart';

void main() {
  group('highlight', () {
    test('good', () async {
      var template = GenGenTempate.r(
          '{%- highlight dart -%}print("hello");{%- endhighlight -%}');
      expect(
           await template.render(),
          equals(
              r'<span class="hljs-built_in">print</span>(<span class="hljs-string">"hello"</span>);'));
    });
  });

  test('raw tag', () async {
    var template = GenGenTempate.r('''{% raw %}{{ { }}}{% endraw %}''');
    expect(await template.render(), equals("{{ { }}}"));
  });
}
