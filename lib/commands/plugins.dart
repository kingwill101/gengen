import 'package:gengen/commands/abstract_command.dart';
import 'package:gengen/plugin/plugin_manager.dart';
import 'package:gengen/site.dart';

class PluginsCommand extends AbstractCommand {
  @override
  String get description => 'List available plugins and their status';

  @override
  String get name => 'plugins';

  PluginsCommand() {
    argParser.addFlag(
      'available',
      abbr: 'a',
      help: 'Show all available plugins',
      negatable: false,
    );
    argParser.addFlag(
      'enabled',
      abbr: 'e',
      help: 'Show only enabled plugins',
      negatable: false,
    );
    argParser.addFlag(
      'groups',
      abbr: 'g',
      help: 'Show plugin groups',
      negatable: false,
    );
  }

  @override
  void start() {
    final site = Site.instance;
    final pluginInfo = PluginManager.getPluginInfo(site.config.all);

    if (argResults!['groups'] as bool) {
      _showGroups(pluginInfo);
    } else if (argResults!['available'] as bool) {
      _showAvailable(pluginInfo);
    } else if (argResults!['enabled'] as bool) {
      _showEnabled(pluginInfo);
    } else {
      _showOverview(pluginInfo);
    }
  }

  void _showOverview(Map<String, dynamic> pluginInfo) {
    print('Plugin Status Overview:');
    print('======================');
    print('');
    
    final enabled = pluginInfo['enabled'] as List;
    final disabled = pluginInfo['disabled'] as List;
    final activePlugins = pluginInfo['active_plugins'] as List;
    
    print('Enabled groups/plugins: ${enabled.join(", ")}');
    print('Disabled groups/plugins: ${disabled.isEmpty ? "none" : disabled.join(", ")}');
    print('');
    print('Active plugins (${activePlugins.length}):');
    for (final plugin in activePlugins) {
      print('  ✓ $plugin');
    }
    print('');
    print('Use --groups to see plugin groups');
    print('Use --available to see all available plugins');
    print('Use --enabled to see only enabled plugins');
  }

  void _showGroups(Map<String, dynamic> pluginInfo) {
    print('Plugin Groups:');
    print('==============');
    print('');
    
    final groups = pluginInfo['groups'] as Map<String, dynamic>;
    final enabled = Set<String>.from(pluginInfo['enabled'] as List);
    final disabled = Set<String>.from(pluginInfo['disabled'] as List);
    
    for (final entry in groups.entries) {
      final groupName = entry.key;
      final plugins = List<String>.from(entry.value as List);
      
      String status = '';
      if (enabled.contains(groupName)) {
        status = ' (ENABLED)';
      } else if (disabled.contains(groupName)) {
        status = ' (DISABLED)';
      }
      
      print('$groupName$status:');
      for (final plugin in plugins) {
        print('  - $plugin');
      }
      print('');
    }
  }

  void _showAvailable(Map<String, dynamic> pluginInfo) {
    print('Available Plugins:');
    print('==================');
    print('');
    
    final available = pluginInfo['available'] as List;
    final activePlugins = Set<String>.from(pluginInfo['active_plugins'] as List);
    
    for (final plugin in available) {
      final status = activePlugins.contains(plugin) ? '✓' : '✗';
      print('  $status $plugin');
    }
    print('');
    print('✓ = enabled, ✗ = disabled');
  }

  void _showEnabled(Map<String, dynamic> pluginInfo) {
    print('Enabled Plugins:');
    print('================');
    print('');
    
    final activePlugins = pluginInfo['active_plugins'] as List;
    
    if (activePlugins.isEmpty) {
      print('No plugins are currently enabled.');
      print('Consider enabling at least the "core" group in your config.');
    } else {
      for (final plugin in activePlugins) {
        print('  ✓ $plugin');
      }
    }
  }
} 