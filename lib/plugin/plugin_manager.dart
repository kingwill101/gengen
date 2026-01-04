import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/builtin/alias.dart';
import 'package:gengen/plugin/builtin/draft.dart';
import 'package:gengen/plugin/builtin/liquid.dart';
import 'package:gengen/plugin/builtin/markdown.dart';
import 'package:gengen/plugin/builtin/pagination.dart';
import 'package:gengen/plugin/builtin/rss.dart';
import 'package:gengen/plugin/builtin/sass.dart';
import 'package:gengen/plugin/builtin/sitemap.dart';
import 'package:gengen/plugin/builtin/tailwind.dart';
import 'package:gengen/logging.dart';

/// Manages plugin registration, groups, and enable/disable functionality
class PluginManager {
  static final Map<String, BasePlugin Function()> _availablePlugins = {
    'DraftPlugin': () => DraftPlugin(),
    'MarkdownPlugin': () => MarkdownPlugin(),
    'LiquidPlugin': () => LiquidPlugin(),
    'RssPlugin': () => RssPlugin(),
    'SassPlugin': () => SassPlugin(),
    'SitemapPlugin': () => SitemapPlugin(),
    'TailwindPlugin': () => TailwindPlugin(),
    'PaginationPlugin': () => PaginationPlugin(),
    'AliasPlugin': () => AliasPlugin(),
  };

  /// Gets the list of enabled plugins based on configuration
  static List<BasePlugin> getEnabledPlugins(Map<String, dynamic> config) {
    final pluginConfig = _normalizePluginConfig(config['plugins']);
    final enabled = Set<String>.from(pluginConfig['enabled'] as List? ?? []);
    final disabled = Set<String>.from(pluginConfig['disabled'] as List? ?? []);
    final groups = Map<String, dynamic>.from(pluginConfig['groups'] as Map? ?? {});

    final enabledPluginNames = <String>{};

    // Process enabled groups and individual plugins
    for (final item in enabled) {
      if (groups.containsKey(item)) {
        // It's a group
        final groupPlugins = List<String>.from(groups[item] as List? ?? []);
        enabledPluginNames.addAll(groupPlugins);
        log.info('(PluginManager) Enabled plugin group "$item": ${groupPlugins.join(", ")}');
      } else if (_availablePlugins.containsKey(item)) {
        // It's an individual plugin
        enabledPluginNames.add(item);
        log.info('(PluginManager) Enabled individual plugin "$item"');
      } else {
        log.warning('(PluginManager) Unknown plugin or group "$item" in enabled list');
      }
    }

    // Remove disabled plugins
    for (final item in disabled) {
      if (groups.containsKey(item)) {
        // It's a group
        final groupPlugins = List<String>.from(groups[item] as List? ?? []);
        enabledPluginNames.removeAll(groupPlugins);
        log.info('(PluginManager) Disabled plugin group "$item": ${groupPlugins.join(", ")}');
      } else if (_availablePlugins.containsKey(item)) {
        // It's an individual plugin
        enabledPluginNames.remove(item);
        log.info('(PluginManager) Disabled individual plugin "$item"');
      } else {
        log.warning('(PluginManager) Unknown plugin or group "$item" in disabled list');
      }
    }

    // Create plugin instances
    final plugins = <BasePlugin>[];
    for (final pluginName in enabledPluginNames) {
      if (_availablePlugins.containsKey(pluginName)) {
        final plugin = _availablePlugins[pluginName]!();
        plugins.add(plugin);
        log.info('(PluginManager) Registered plugin: ${plugin.metadata.name}');
      }
    }

    if (plugins.isEmpty) {
      log.warning('(PluginManager) No plugins enabled! Consider enabling at least the "core" group.');
    }

    return plugins;
  }

  /// Gets all available plugin names
  static Set<String> get availablePlugins => _availablePlugins.keys.toSet();

  /// Gets the default plugin groups
  static Map<String, List<String>> get defaultGroups => {
    'core': ['DraftPlugin', 'MarkdownPlugin', 'LiquidPlugin', 'SassPlugin', 'PaginationPlugin'],
    'seo': ['RssPlugin', 'SitemapPlugin'],
    'assets': ['SassPlugin', 'TailwindPlugin'],
    'content': ['PaginationPlugin', 'AliasPlugin'],
  };

  /// Registers a custom plugin
  static void registerPlugin(String name, BasePlugin Function() factory) {
    _availablePlugins[name] = factory;
    log.info('(PluginManager) Registered custom plugin: $name');
  }

  /// Gets plugin information for debugging
  static Map<String, dynamic> getPluginInfo(Map<String, dynamic> config) {
    final pluginConfig = _normalizePluginConfig(config['plugins']);
    final enabled = Set<String>.from(pluginConfig['enabled'] as List? ?? []);
    final disabled = Set<String>.from(pluginConfig['disabled'] as List? ?? []);
    final groups = Map<String, dynamic>.from(pluginConfig['groups'] as Map? ?? {});

    return {
      'available': availablePlugins.toList()..sort(),
      'enabled': enabled.toList()..sort(),
      'disabled': disabled.toList()..sort(),
      'groups': groups,
      'active_plugins': getEnabledPlugins(config).map((p) => p.metadata.name).toList()..sort(),
    };
}

  static Map<String, dynamic> _normalizePluginConfig(dynamic raw) {
    final baseGroups = defaultGroups.map(
      (key, value) => MapEntry(key, List<String>.from(value)),
    );

    final result = <String, dynamic>{
      'enabled': <String>['core'],
      'disabled': <String>[],
      'groups': baseGroups,
    };

    if (raw is Iterable) {
      result['enabled'].addAll(raw.map((e) => e.toString()));
      result['enabled'] = result['enabled'].toSet().toList();
      return result;
    }

    if (raw is Map) {
      final explicitEnabled = raw.containsKey('enabled');
      final map = Map<String, dynamic>.from(raw); // loose copy

      if (map.containsKey('enabled')) {
        final enabled = _normalizeStringList(map['enabled']);
        result['enabled'] = enabled.isEmpty ? <String>[] : enabled;
      }

      if (map.containsKey('disabled')) {
        result['disabled'] = _normalizeStringList(map['disabled']);
      }

      if (map.containsKey('groups')) {
        final groups = <String, List<String>>{};
        final rawGroups = map['groups'];
        if (rawGroups is Map) {
          rawGroups.forEach((key, value) {
            groups[key.toString()] = _normalizeStringList(value);
          });
        }
        result['groups'] = {...baseGroups, ...groups};
      }

      final enabled = _normalizeStringList(result['enabled']);
      result['enabled'] =
          enabled.isEmpty && !explicitEnabled ? <String>['core'] : enabled;
      result['disabled'] = _normalizeStringList(result['disabled']);
      return result;
    }

    result['enabled'] = _normalizeStringList(result['enabled']);
    if ((result['enabled'] as List).isEmpty) {
      result['enabled'] = <String>['core'];
    }
    return result;
  }

  static List<String> _normalizeStringList(dynamic value) {
    if (value is Iterable) {
      return value.map((e) => e.toString()).toSet().toList();
    }
    if (value != null) {
      return [value.toString()];
    }
    return <String>[];
  }
}
