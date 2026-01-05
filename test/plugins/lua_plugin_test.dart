import 'package:file/memory.dart';
import 'package:gengen/configuration.dart';
import 'package:gengen/exceptions.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/liquid/template.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/models/plugin_asset.dart';
import 'package:gengen/plugin/lua/lua_plugin.dart';
import 'package:gengen/readers/plugin_reader.dart';
import 'package:gengen/site.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('LuaPlugin', () {
    late MemoryFileSystem fs;
    late String projectRoot;
    late String sourcePath;

    setUp(() {
      Site.resetInstance();
      Configuration.resetConfig();
      Logger.root.clearListeners();

      fs = MemoryFileSystem();
      gengen_fs.fs = fs;

      projectRoot = fs.currentDirectory.path;
      sourcePath = p.join(projectRoot, 'site');

      fs.directory(p.join(sourcePath, '_plugins')).createSync(recursive: true);
      fs.directory(p.join(sourcePath, '_posts')).createSync(recursive: true);

      // Minimal markdown file so Base can load site content for convert tests.
      final postPath = p.join(sourcePath, '_posts', 'sample.md');
      fs
          .file(postPath)
          .writeAsStringSync('---\\ntitle: Sample\\n---\\nContent');

      Site.init(
        overrides: {
          'source': sourcePath,
          'destination': p.join(projectRoot, 'public'),
        },
      );
    });

    tearDown(() {
      Site.resetInstance();
    });

    test('loads Lua plugin and executes lifecycle hooks', () async {
      final plugin = await _writeAndLoadPlugin(
        sourcePath: sourcePath,
        name: 'lua-example',
        luaSource: '''
function init_plugin(metadata)
  return {
    after_generate = function()
      gengen.content.write_site('from_lua.txt', 'Lua says hello')
    end,
    convert = function(content, page)
      local slug = tostring(gengen.util.slugify('Sample'))
      local exists = gengen.content.exists_plugin('main.lua') and 'true' or 'false'
      return slug .. '|' .. exists
    end,
    head_injection = function()
      return '<meta name="lua-plugin" content="lua-example">'
    end,
    css_assets = {'styles.css', 'theme.css'},
    js_assets = {'lua-plugin.js'},
    meta_tags = {
      author = 'Lua Author'
    }
  }
end
''',
      );

      final pluginSource = fs
          .file(p.join(sourcePath, '_plugins', 'lua-example', 'main.lua'))
          .readAsStringSync();
      expect(pluginSource.contains('gengen.content.write_site'), isTrue);

      await plugin.afterInit();

      expect(
        plugin.getHeadInjection(),
        contains('<meta name="lua-plugin" content="lua-example">'),
      );
      expect(plugin.getCssAssets(), equals(['styles.css', 'theme.css']));
      expect(plugin.getJsAssets(), equals(['lua-plugin.js']));
      expect(plugin.getMetaTags(), equals({'author': 'Lua Author'}));

      await plugin.afterGenerate(); // Should run without throwing.

      final generatedFile = fs.file(
        p.join(projectRoot, 'public', 'from_lua.txt'),
      );
      expect(generatedFile.existsSync(), isTrue);
      expect(generatedFile.readAsStringSync(), equals('Lua says hello'));

      final pagePath = p.join(sourcePath, '_posts', 'sample.md');
      final page = Base(pagePath);

      final converted = await plugin.convert('hello', page);
      final parts = converted.split('|');
      expect(parts.length, equals(2));
      expect(parts[0], equals('sample'));
      expect(parts[1], equals('true'));

      // Lua sources should not be treated as static assets.
      final luaAssets = Site.instance.staticFiles
          .whereType<PluginStaticAsset>()
          .where((asset) => asset.source.endsWith('.lua'));
      expect(luaAssets, isEmpty);
    });

    test('reports type mismatches from Lua hooks with context', () async {
      final plugin = await _writeAndLoadPlugin(
        sourcePath: sourcePath,
        name: 'lua-bad-convert',
        luaSource: '''
function init_plugin(metadata)
  return {
    convert = function(content, page)
      return 42
    end
  }
end
''',
      );

      await plugin.afterInit();

      final pagePath = p.join(sourcePath, '_posts', 'sample.md');
      final page = Base(pagePath);

      expect(
        () => plugin.convert('content', page),
        throwsA(
          isA<PluginException>().having(
            (error) => error.message,
            'message',
            contains('hook "convert"'),
          ),
        ),
      );
    });

    test('registers liquid filters from Lua plugins', () async {
      final plugin = await _writeAndLoadPlugin(
        sourcePath: sourcePath,
        name: 'lua-filters',
        luaSource: '''
function init_plugin(metadata)
  return {
    liquid_filters = {
      shout = function(value, args, named)
        return string.upper(tostring(value))
      end,
      nilfilter = function(value, args, named)
        return nil
      end
    }
  }
end
''',
      );

      await plugin.afterInit();
      Site.instance.plugins.add(plugin);

      final template = GenGenTempate.r(
        'Hello {{ "world" | shout }}',
        data: {'page': <String, dynamic>{}, 'site': <String, dynamic>{}},
      );
      final rendered = await template.render();
      expect(rendered, contains('WORLD'));

      final badTemplate = GenGenTempate.r(
        'Test {{ "x" | nilfilter }}',
        data: {'page': <String, dynamic>{}, 'site': <String, dynamic>{}},
      );

      expect(
        () async => await badTemplate.render(),
        throwsA(
          isA<PluginException>().having(
            (error) => error.message,
            'message',
            contains('filter "nilfilter"'),
          ),
        ),
      );
    });
  });
}

Future<LuaPlugin> _writeAndLoadPlugin({
  required String sourcePath,
  required String name,
  required String luaSource,
}) async {
  final pluginDir = p.join(sourcePath, '_plugins', name);
  gengen_fs.fs.directory(pluginDir).createSync(recursive: true);

  gengen_fs.fs.file(p.join(pluginDir, 'config.yaml')).writeAsStringSync('''
name: $name
entrypoint: main.lua:init_plugin
''');

  gengen_fs.fs.file(p.join(pluginDir, 'main.lua')).writeAsStringSync(luaSource);

  final plugins = await PluginReader.dirPlugins(
    gengen_fs.fs.directory(p.join(sourcePath, '_plugins')),
  );

  expect(
    plugins,
    isNotEmpty,
    reason: 'Expected at least one plugin to be loaded from $pluginDir',
  );

  final plugin = plugins.firstWhere(
    (plugin) => plugin.metadata.name == name,
    orElse: () => throw StateError('Lua plugin $name not found'),
  );

  expect(plugin, isA<LuaPlugin>());
  return plugin as LuaPlugin;
}
