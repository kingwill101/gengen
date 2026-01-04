import 'package:file/memory.dart';
import 'package:gengen/site.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/configuration.dart';
import 'package:test/test.dart';

void main() {
  group('Liquid render order with Markdown', () {
    late MemoryFileSystem fs;
    late Site site;

    tearDown(() {
      Site.resetInstance();
      Configuration.resetConfig();
    });

    setUp(() async {
      fs = MemoryFileSystem();
      gengen_fs.fs = fs;

      final projectRoot = fs.currentDirectory.path;

      await fs.directory('$projectRoot/test_site').create(recursive: true);
      await fs.directory('$projectRoot/test_site/_themes').create(recursive: true);
      await fs.directory('$projectRoot/test_site/_themes/default').create(recursive: true);
      await fs.directory('$projectRoot/test_site/_themes/default/_layouts').create(recursive: true);
      await fs.directory('$projectRoot/test_site/public').create(recursive: true);

      await fs.file('$projectRoot/test_site/_config.yaml').writeAsString('''
title: "Test Site"
source: $projectRoot/test_site
destination: $projectRoot/test_site/public
permalink: "pretty"
snippet: "**Bold**"
''');

      await fs.file('$projectRoot/test_site/_themes/default/_layouts/default.html').writeAsString('''
<!doctype html>
<html>
<head><title>{{ site.title }}</title></head>
<body>
{{ content }}
</body>
</html>
''');

      await fs.file('$projectRoot/test_site/_themes/default/config.yaml').writeAsString('''
name: default
version: 1.0.0
''');

      await fs.file('$projectRoot/test_site/order.md').writeAsString('''
---
title: "Order Test"
layout: default
---

{{ site.snippet }}
''');

      await fs.file('$projectRoot/test_site/no-liquid.md').writeAsString('''
---
title: "No Liquid"
layout: default
render_with_liquid: false
---

Literal: {{ site.title }}
''');

      Site.init(overrides: {
        'source': '$projectRoot/test_site',
        'destination': '$projectRoot/test_site/public',
        'permalink': 'pretty',
        'theme': 'default',
      });
      site = Site.instance;
    });

    test('renders Liquid before Markdown so Liquid output is converted', () async {
      await site.process();

      final page = site.pages.firstWhere(
        (page) => page.config['title'] == 'Order Test',
      );

      final output = await fs.file(page.filePath).readAsString();
      expect(output, contains('<strong>Bold</strong>'));
    });

    test('render_with_liquid false keeps content literal but layout renders', () async {
      await site.process();

      final page = site.pages.firstWhere(
        (page) => page.config['title'] == 'No Liquid',
      );

      final output = await fs.file(page.filePath).readAsString();
      expect(output, contains('Test Site'));
      expect(output, contains('{{ site.title }}'));
    });
  });
}
