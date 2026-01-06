import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:gengen/configuration.dart';
import 'package:gengen/di.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/liquid/template.dart';
import 'package:gengen/site.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    if (!getIt.isRegistered<FileSystem>()) {
      getIt.registerSingleton<FileSystem>(const LocalFileSystem());
    }
    gengen_fs.fs = const LocalFileSystem();
    Configuration.resetConfig();
    Site.resetInstance();
  });

  group('highlight', () {
    test('good', () async {
      var template = GenGenTempate.r(
        '{%- highlight dart -%}print("hello");{%- endhighlight -%}',
      );
      expect(
        await template.render(),
        equals(
          r'<span class="hljs-built_in">print</span>(<span class="hljs-string">"hello"</span>);',
        ),
      );
    });
  });

  test('raw tag', () async {
    var template = GenGenTempate.r('''{% raw %}{{ { }}}{% endraw %}''');
    expect(await template.render(), equals("{{ { }}}"));
  });
}
