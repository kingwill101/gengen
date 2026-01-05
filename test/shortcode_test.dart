import 'package:file/memory.dart';
import 'package:gengen/configuration.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/liquid/template.dart';
import 'package:gengen/md/md.dart';
import 'package:gengen/shortcodes.dart';
import 'package:gengen/site.dart';
import 'package:liquify/liquify.dart' as liquid;
import 'package:test/test.dart';

void main() {
  group('Shortcode parsing', () {
    test('parses shortcode attributes with mixed quoting', () {
      final attrs = parseShortcodeAttributes(
        " url='https://example.com' width=560 height:\"315\" data-id=foo",
      );

      expect(attrs['url'], equals('https://example.com'));
      expect(attrs['width'], equals('560'));
      expect(attrs['height'], equals('315'));
      expect(attrs['data-id'], equals('foo'));
    });

    test('parses shortcode args into name and attributes', () {
      final parts = parseShortcodeArgs(
        "'partials/media/twitter' url='https://example.com' width='560'",
      );

      expect(parts.name, equals('partials/media/twitter'));
      expect(parts.attributes['url'], equals('https://example.com'));
      expect(parts.attributes['width'], equals('560'));
    });

    test('builds shortcode tag', () {
      final tag = buildShortcodeTag(
        'partials/media/twitter',
        {'url': 'https://example.com', 'width': '560'},
      );

      expect(tag, contains("{% shortcode 'partials/media/twitter'"));
      expect(tag, contains("url='https://example.com'"));
      expect(tag, contains("width='560'"));
    });

    test('replaces markdown shortcodes with liquid shortcodes', () {
      final input =
          "[ shortcode 'partials/media/twitter' url='https://example.com' ]";
      final output = replaceShortcodesWithLiquid(input);

      expect(output, contains("{% shortcode 'partials/media/twitter'"));
      expect(output, contains("url='https://example.com'"));
    });

    test('does not replace shortcodes inside fenced code blocks', () {
      final input = '''
Before
```text
[ shortcode 'partials/media/youtube' id='VIDEO_ID' ]
```
After [ shortcode 'partials/media/twitter' url='https://example.com' ]
''';
      final output = replaceShortcodesWithLiquid(input);

      expect(output, contains("[ shortcode 'partials/media/youtube'"));
      expect(output, contains("{% shortcode 'partials/media/twitter'"));
    });

    test('does not replace shortcodes inside raw blocks', () {
      final input = '''
{% raw %}
[ shortcode 'partials/media/youtube' id='VIDEO_ID' ]
{% endraw %}
[ shortcode 'partials/media/twitter' url='https://example.com' ]
''';
      final output = replaceShortcodesWithLiquid(input);

      expect(output, contains("[ shortcode 'partials/media/youtube'"));
      expect(output, contains("{% shortcode 'partials/media/twitter'"));
    });
  });

  group('Markdown shortcode', () {
    test('converts shortcode syntax to liquid shortcode tag', () {
      final result = renderMd(
        "[ shortcode 'partials/media/twitter' url='https://example.com' ]",
      );

      expect(result, contains("{% shortcode 'partials/media/twitter'"));
      expect(result, contains("url='https://example.com'"));
    });
  });

  group('Liquid shortcode tag', () {
    test('renders included partial with attributes', () async {
      Configuration.resetConfig();
      Site.resetInstance();
      final fs = MemoryFileSystem();
      gengen_fs.fs = fs;

      final projectRoot = fs.currentDirectory.path;
      Site.init(overrides: {
        'source': projectRoot,
        'destination': '$projectRoot/public',
      });

      final root = liquid.MapRoot({
        'partials/media/twitter': 'URL={{ url }}|W={{ width }}',
      });

      final template = GenGenTempate.r(
        "{% shortcode 'partials/media/twitter' url='https://example.com' width='560' %}",
        contentRoot: root,
      );

      final result = await template.render();
      expect(result, contains('URL=https://example.com'));
      expect(result, contains('W=560'));
    });
  });
}
