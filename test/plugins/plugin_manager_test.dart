import 'package:test/test.dart';
import 'package:gengen/plugin/plugin_manager.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';

void main() {
  group('PluginManager', () {
    test('should return default core plugins when only core group is enabled', () {
      final config = {
        'plugins': {
          'enabled': ['core'],
          'disabled': [],
          'groups': {
            'core': ['DraftPlugin', 'MarkdownPlugin', 'LiquidPlugin'],
            'seo': ['RssPlugin', 'SitemapPlugin'],
          }
        }
      };

      final plugins = PluginManager.getEnabledPlugins(config);
      final pluginNames = plugins.map((p) => p.metadata.name).toSet();

      expect(pluginNames, contains('DraftPlugin'));
      expect(pluginNames, contains('MarkdownPlugin'));
      expect(pluginNames, contains('LiquidPlugin'));
      expect(pluginNames, isNot(contains('RssPlugin')));
      expect(pluginNames, isNot(contains('SitemapPlugin')));
    });

    test('should enable multiple groups', () {
      final config = {
        'plugins': {
          'enabled': ['core', 'seo'],
          'disabled': [],
          'groups': {
            'core': ['DraftPlugin', 'MarkdownPlugin', 'LiquidPlugin'],
            'seo': ['RssPlugin', 'SitemapPlugin'],
          }
        }
      };

      final plugins = PluginManager.getEnabledPlugins(config);
      final pluginNames = plugins.map((p) => p.metadata.name).toSet();

      expect(pluginNames, contains('DraftPlugin'));
      expect(pluginNames, contains('MarkdownPlugin'));
      expect(pluginNames, contains('LiquidPlugin'));
      expect(pluginNames, contains('RssPlugin'));
      expect(pluginNames, contains('SitemapPlugin'));
    });

    test('should disable specific plugins even when group is enabled', () {
      final config = {
        'plugins': {
          'enabled': ['core', 'seo'],
          'disabled': ['RssPlugin'],
          'groups': {
            'core': ['DraftPlugin', 'MarkdownPlugin', 'LiquidPlugin'],
            'seo': ['RssPlugin', 'SitemapPlugin'],
          }
        }
      };

      final plugins = PluginManager.getEnabledPlugins(config);
      final pluginNames = plugins.map((p) => p.metadata.name).toSet();

      expect(pluginNames, contains('DraftPlugin'));
      expect(pluginNames, contains('MarkdownPlugin'));
      expect(pluginNames, contains('LiquidPlugin'));
      expect(pluginNames, isNot(contains('RssPlugin')));
      expect(pluginNames, contains('SitemapPlugin'));
    });

    test('should enable individual plugins without groups', () {
      final config = {
        'plugins': {
          'enabled': ['MarkdownPlugin', 'SassPlugin'],
          'disabled': [],
          'groups': {}
        }
      };

      final plugins = PluginManager.getEnabledPlugins(config);
      final pluginNames = plugins.map((p) => p.metadata.name).toSet();

      expect(pluginNames, contains('MarkdownPlugin'));
      expect(pluginNames, contains('SassPlugin'));
      expect(pluginNames, isNot(contains('DraftPlugin')));
      expect(pluginNames, isNot(contains('LiquidPlugin')));
    });

    test('should disable entire groups', () {
      final config = {
        'plugins': {
          'enabled': ['core', 'seo'],
          'disabled': ['seo'],
          'groups': {
            'core': ['DraftPlugin', 'MarkdownPlugin', 'LiquidPlugin'],
            'seo': ['RssPlugin', 'SitemapPlugin'],
          }
        }
      };

      final plugins = PluginManager.getEnabledPlugins(config);
      final pluginNames = plugins.map((p) => p.metadata.name).toSet();

      expect(pluginNames, contains('DraftPlugin'));
      expect(pluginNames, contains('MarkdownPlugin'));
      expect(pluginNames, contains('LiquidPlugin'));
      expect(pluginNames, isNot(contains('RssPlugin')));
      expect(pluginNames, isNot(contains('SitemapPlugin')));
    });

    test('should return empty list when no plugins are configured', () {
      final config = {
        'plugins': {
          'enabled': [],
          'disabled': [],
          'groups': {}
        }
      };

      final plugins = PluginManager.getEnabledPlugins(config);
      expect(plugins, isEmpty);
    });

    test('should return plugin info correctly', () {
      final config = {
        'plugins': {
          'enabled': ['core'],
          'disabled': ['SassPlugin'],
          'groups': {
            'core': ['DraftPlugin', 'MarkdownPlugin', 'LiquidPlugin'],
          }
        }
      };

      final info = PluginManager.getPluginInfo(config);

      expect(info['available'], isA<List>());
      expect(info['enabled'], equals(['core']));
      expect(info['disabled'], equals(['SassPlugin']));
      expect(info['active_plugins'], isA<List>());
      expect(info['groups'], isA<Map>());
    });

    test('should handle missing plugin configuration gracefully', () {
      final config = <String, dynamic>{};

      final plugins = PluginManager.getEnabledPlugins(config);
      expect(plugins, isEmpty);
    });

    test('should register custom plugins', () {
      // Create a mock plugin
      final originalPlugins = PluginManager.availablePlugins.toSet();
      
      PluginManager.registerPlugin('TestPlugin', () => MockPlugin());
      
      expect(PluginManager.availablePlugins, contains('TestPlugin'));
      expect(PluginManager.availablePlugins.length, equals(originalPlugins.length + 1));
    });
  });
}

class MockPlugin extends BasePlugin {
  @override
  PluginMetadata get metadata => PluginMetadata(
    name: 'TestPlugin',
    version: '1.0.0',
    description: 'A test plugin',
  );
}
