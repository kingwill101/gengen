import 'package:file/memory.dart';
import 'package:gengen/configuration.dart';
import 'package:gengen/exceptions.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Site engine integration', () {
    late MemoryFileSystem memoryFileSystem;
    late String projectRoot;

    setUp(() {
      Site.resetInstance();
      Configuration.resetConfig();
      memoryFileSystem = MemoryFileSystem(style: FileSystemStyle.posix);
      gengen_fs.fs = memoryFileSystem;
      projectRoot = '/integration_site';
    });

    tearDown(() {
      Site.resetInstance();
    });

    test('process generates output and copies plugin assets', () async {
      final sourcePath = p.join(projectRoot, 'source');
      final destinationPath = p.join(projectRoot, 'public');

      await _createBaseSite(memoryFileSystem, sourcePath);
      await _createLuaPlugin(
        memoryFileSystem,
        sourcePath,
        name: 'integration-plugin',
        assets: {
          'assets/style.css': '.integration { color: purple; }',
          'assets/script.js': 'console.log("integration");',
        },
        luaBody: '''
function init_plugin(metadata)
  return {
    convert = function(content, page)
      return content .. "\n<!-- plugin:" .. metadata.name .. " -->"
    end,
    after_generate = function()
      gengen.content.write_site('integration.txt', 'integration-complete')
    end
  }
end
''',
      );

      Site.init(
        overrides: {
          'source': sourcePath,
          'destination': destinationPath,
          'theme': 'default',
        },
      );

      await Site.instance.process();

      final indexFile = memoryFileSystem.file(
        p.join(destinationPath, 'index.html'),
      );
      expect(indexFile.existsSync(), isTrue);
      final html = indexFile.readAsStringSync();
      expect(html, contains('<!-- plugin:integration-plugin -->'));

      final assetCss = memoryFileSystem.file(
        p.join(
          destinationPath,
          'assets',
          'plugins',
          'integration-plugin',
          'style.css',
        ),
      );
      final assetJs = memoryFileSystem.file(
        p.join(
          destinationPath,
          'assets',
          'plugins',
          'integration-plugin',
          'script.js',
        ),
      );
      expect(
        assetCss.existsSync(),
        isTrue,
        reason: 'CSS asset should be copied',
      );
      expect(assetJs.existsSync(), isTrue, reason: 'JS asset should be copied');

      final runtimeFile = memoryFileSystem.file(
        p.join(destinationPath, 'integration.txt'),
      );
      expect(runtimeFile.existsSync(), isTrue);
      expect(runtimeFile.readAsStringSync(), equals('integration-complete'));
    });

    test('process propagates plugin hook failures', () async {
      final sourcePath = p.join(projectRoot, 'source');
      final destinationPath = p.join(projectRoot, 'public');

      await _createBaseSite(memoryFileSystem, sourcePath);
      await _createLuaPlugin(
        memoryFileSystem,
        sourcePath,
        name: 'failing-plugin',
        luaBody: '''
function init_plugin(metadata)
  return {
    before_read = function()
      error('intentional failure')
    end
  }
end
''',
      );

      Site.init(
        overrides: {
          'source': sourcePath,
          'destination': destinationPath,
          'theme': 'default',
        },
      );

      expect(
        () => Site.instance.process(),
        throwsA(
          isA<PluginException>().having(
            (e) => e.message,
            'message',
            contains('failing-plugin'),
          ),
        ),
      );
    });

    test('process is idempotent and cleans previous output', () async {
      final sourcePath = p.join(projectRoot, 'source');
      final destinationPath = p.join(projectRoot, 'public');

      await _createBaseSite(memoryFileSystem, sourcePath);
      await _createLuaPlugin(
        memoryFileSystem,
        sourcePath,
        name: 'integration-plugin',
        assets: {'assets/style.css': '.integration { color: purple; }'},
        luaBody: '''
function init_plugin(metadata)
  local counter = 0
  return {
    after_generate = function()
      counter = counter + 1
      gengen.content.write_site('counter.json', tostring(counter))
    end
  }
end
''',
      );

      Site.init(
        overrides: {
          'source': sourcePath,
          'destination': destinationPath,
          'theme': 'default',
        },
      );

      await Site.instance.process();
      final firstRunFile = memoryFileSystem.file(
        p.join(destinationPath, 'counter.json'),
      );
      expect(firstRunFile.existsSync(), isTrue);
      expect(firstRunFile.readAsStringSync(), equals('1'));

      await Site.instance.process();
      final secondRunFile = memoryFileSystem.file(
        p.join(destinationPath, 'counter.json'),
      );
      expect(secondRunFile.existsSync(), isTrue);
      expect(secondRunFile.readAsStringSync(), equals('2'));

      final assetFile = memoryFileSystem.file(
        p.join(
          destinationPath,
          'assets',
          'plugins',
          'integration-plugin',
          'style.css',
        ),
      );
      expect(assetFile.existsSync(), isTrue);
    });

    test('permalink variations produce expected output paths', () async {
      final sourcePath = p.join(projectRoot, 'source');
      final destinationPath = p.join(projectRoot, 'public');

      await _createBaseSite(memoryFileSystem, sourcePath);
      memoryFileSystem
          .file(p.join(sourcePath, '_config.yaml'))
          .writeAsStringSync('''
title: Permalink Site
theme: default
permalink: pretty
''');

      memoryFileSystem
          .file(p.join(sourcePath, '_posts', '2024-01-01-first.md'))
          .writeAsStringSync('''
---
title: First Post
layout: default
---
Hello, pretty permalink!
''');

      Site.init(
        overrides: {
          'source': sourcePath,
          'destination': destinationPath,
          'theme': 'default',
        },
      );

      await Site.instance.process();

      final prettyPath = memoryFileSystem.file(
        p.join(
          destinationPath,
          'posts',
          '2024',
          '01',
          '01',
          'first-post',
          'index.html',
        ),
      );
      expect(prettyPath.existsSync(), isTrue);

      final prettyHtml = prettyPath.readAsStringSync();
      expect(prettyHtml.toLowerCase(), contains('<html'));
      expect(prettyHtml.toLowerCase(), contains('<body'));
    });

    test('removes stale outputs when sources are deleted', () async {
      final sourcePath = p.join(projectRoot, 'source');
      final destinationPath = p.join(projectRoot, 'public');

      await _createBaseSite(memoryFileSystem, sourcePath);

      memoryFileSystem.file(p.join(sourcePath, 'about.md')).writeAsStringSync(
        '''
---
title: About
layout: default
---
<p>About page</p>
''',
      );

      Site.init(
        overrides: {
          'source': sourcePath,
          'destination': destinationPath,
          'theme': 'default',
        },
      );

      await Site.instance.process();

      final aboutDest = memoryFileSystem.file(
        p.join(destinationPath, 'about', 'index.html'),
      );
      expect(aboutDest.existsSync(), isTrue);

      memoryFileSystem.file(p.join(sourcePath, 'about.md')).deleteSync();

      await Site.instance.process();

      expect(aboutDest.existsSync(), isFalse);
    });
  });
}

Future<void> _createBaseSite(MemoryFileSystem fs, String sourcePath) async {
  await fs.directory(sourcePath).create(recursive: true);
  await fs.directory(p.join(sourcePath, '_layouts')).create(recursive: true);
  await fs.directory(p.join(sourcePath, '_posts')).create(recursive: true);
  await fs
      .directory(p.join(sourcePath, '_themes', 'default', '_layouts'))
      .create(recursive: true);
  await fs.directory(p.join(sourcePath, '_plugins')).create(recursive: true);

  fs.file(p.join(sourcePath, 'index.html')).writeAsStringSync('''
---
title: Home
layout: default
---
<h1>Integration Test</h1>
''');

  fs.file(p.join(sourcePath, '_layouts', 'default.html')).writeAsStringSync('''
<!DOCTYPE html>
<html>
<head>{% plugin_head %}</head>
<body>
  {{ content }}
  {% plugin_body %}
</body>
</html>
''');

  fs
      .file(
        p.join(sourcePath, '_themes', 'default', '_layouts', 'default.html'),
      )
      .writeAsStringSync('''
<!DOCTYPE html>
<html>
<head>{% plugin_head %}</head>
<body>
  {{ content }}
  {% plugin_body %}
</body>
</html>
''');
}

Future<void> _createLuaPlugin(
  MemoryFileSystem fs,
  String sourcePath, {
  required String name,
  required String luaBody,
  Map<String, String> assets = const {},
}) async {
  final pluginDir = p.join(sourcePath, '_plugins', name);
  await fs.directory(pluginDir).create(recursive: true);

  final pluginTitle = name
      .split('-')
      .map(
        (segment) => segment.isNotEmpty
            ? segment[0].toUpperCase() + segment.substring(1)
            : segment,
      )
      .join('');

  fs.file(p.join(pluginDir, 'config.yaml')).writeAsStringSync('''
name: $pluginTitle
entrypoint: main.lua:init_plugin
''');

  fs.file(p.join(pluginDir, 'main.lua')).writeAsStringSync(luaBody);

  for (final entry in assets.entries) {
    final assetPath = p.join(pluginDir, entry.key);
    await fs.directory(p.dirname(assetPath)).create(recursive: true);
    fs.file(assetPath).writeAsStringSync(entry.value);
  }
}
