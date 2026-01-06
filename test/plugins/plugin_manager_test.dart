import 'package:test/test.dart';
import 'package:gengen/plugin/plugin_manager.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';

void main() {
  group('PluginManager', () {
    test(
      'should return default core plugins when only core group is enabled',
      () {
        final config = _pluginConfig(
          enabled: <String>['core'],
          groups: <String, List<String>>{
            'core': <String>['DraftPlugin', 'MarkdownPlugin', 'LiquidPlugin'],
            'seo': <String>['RssPlugin', 'SitemapPlugin'],
          },
        );

        final plugins = PluginManager.getEnabledPlugins(config);
        final pluginNames = plugins.map((p) => p.metadata.name).toSet();

        expect(pluginNames, contains('DraftPlugin'));
        expect(pluginNames, contains('MarkdownPlugin'));
        expect(pluginNames, contains('LiquidPlugin'));
        expect(pluginNames, isNot(contains('RssPlugin')));
        expect(pluginNames, isNot(contains('SitemapPlugin')));
      },
    );

    test('should enable multiple groups', () {
      final config = _pluginConfig(
        enabled: <String>['core', 'seo'],
        groups: <String, List<String>>{
          'core': <String>['DraftPlugin', 'MarkdownPlugin', 'LiquidPlugin'],
          'seo': <String>['RssPlugin', 'SitemapPlugin'],
        },
      );

      final plugins = PluginManager.getEnabledPlugins(config);
      final pluginNames = plugins.map((p) => p.metadata.name).toSet();

      expect(pluginNames, contains('DraftPlugin'));
      expect(pluginNames, contains('MarkdownPlugin'));
      expect(pluginNames, contains('LiquidPlugin'));
      expect(pluginNames, contains('RssPlugin'));
      expect(pluginNames, contains('SitemapPlugin'));
    });

    test('should disable specific plugins even when group is enabled', () {
      final config = _pluginConfig(
        enabled: <String>['core', 'seo'],
        disabled: <String>['RssPlugin'],
        groups: <String, List<String>>{
          'core': <String>['DraftPlugin', 'MarkdownPlugin', 'LiquidPlugin'],
          'seo': <String>['RssPlugin', 'SitemapPlugin'],
        },
      );

      final plugins = PluginManager.getEnabledPlugins(config);
      final pluginNames = plugins.map((p) => p.metadata.name).toSet();

      expect(pluginNames, contains('DraftPlugin'));
      expect(pluginNames, contains('MarkdownPlugin'));
      expect(pluginNames, contains('LiquidPlugin'));
      expect(pluginNames, isNot(contains('RssPlugin')));
      expect(pluginNames, contains('SitemapPlugin'));
    });

    test('should enable individual plugins without groups', () {
      final config = _pluginConfig(
        enabled: <String>['MarkdownPlugin', 'SassPlugin'],
      );

      final plugins = PluginManager.getEnabledPlugins(config);
      final pluginNames = plugins.map((p) => p.metadata.name).toSet();

      expect(pluginNames, contains('MarkdownPlugin'));
      expect(pluginNames, contains('SassPlugin'));
      expect(pluginNames, isNot(contains('DraftPlugin')));
      expect(pluginNames, isNot(contains('LiquidPlugin')));
    });

    test('should disable entire groups', () {
      final config = _pluginConfig(
        enabled: <String>['core', 'seo'],
        disabled: <String>['seo'],
        groups: <String, List<String>>{
          'core': <String>['DraftPlugin', 'MarkdownPlugin', 'LiquidPlugin'],
          'seo': <String>['RssPlugin', 'SitemapPlugin'],
        },
      );

      final plugins = PluginManager.getEnabledPlugins(config);
      final pluginNames = plugins.map((p) => p.metadata.name).toSet();

      expect(pluginNames, contains('DraftPlugin'));
      expect(pluginNames, contains('MarkdownPlugin'));
      expect(pluginNames, contains('LiquidPlugin'));
      expect(pluginNames, isNot(contains('RssPlugin')));
      expect(pluginNames, isNot(contains('SitemapPlugin')));
    });

    test('should return empty list when no plugins are configured', () {
      final config = _pluginConfig();

      final plugins = PluginManager.getEnabledPlugins(config);
      expect(plugins, isEmpty);
    });

    test('should return plugin info correctly', () {
      final config = _pluginConfig(
        enabled: <String>['core'],
        disabled: <String>['SassPlugin'],
        groups: <String, List<String>>{
          'core': <String>['DraftPlugin', 'MarkdownPlugin', 'LiquidPlugin'],
        },
      );

      final info = PluginManager.getPluginInfo(config);

      expect(info['available'], isA<List<String>>());
      expect(info['enabled'], equals(<String>['core']));
      expect(info['disabled'], equals(<String>['SassPlugin']));
      expect(info['active_plugins'], isA<List<String>>());
      expect(info['groups'], isA<Map<String, dynamic>>());
      final groups = info['groups'] as Map<String, dynamic>;
      expect(
        groups['core'],
        equals(<String>['DraftPlugin', 'MarkdownPlugin', 'LiquidPlugin']),
      );
    });

    test('should handle missing plugin configuration gracefully', () {
      final config = <String, dynamic>{};

      final plugins = PluginManager.getEnabledPlugins(config);
      expect(
        plugins.map((p) => p.metadata.name),
        containsAll(<String>[
          'DraftPlugin',
          'MarkdownPlugin',
          'LiquidPlugin',
          'SassPlugin',
          'PaginationPlugin',
        ]),
      );
    });

    test('should register custom plugins', () {
      // Create a mock plugin
      final originalPlugins = PluginManager.availablePlugins.toSet();

      PluginManager.registerPlugin('TestPlugin', () => MockPlugin());

      expect(PluginManager.availablePlugins, contains('TestPlugin'));
      expect(
        PluginManager.availablePlugins.length,
        equals(originalPlugins.length + 1),
      );
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

Map<String, dynamic> _pluginConfig({
  List<String> enabled = const <String>[],
  List<String> disabled = const <String>[],
  Map<String, List<String>> groups = const <String, List<String>>{},
}) {
  return <String, dynamic>{
    'plugins': <String, dynamic>{
      'enabled': List<String>.from(enabled),
      'disabled': List<String>.from(disabled),
      'groups': groups.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      ),
    },
  };
}
