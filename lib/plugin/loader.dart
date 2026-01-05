import 'package:gengen/logging.dart';
import 'package:gengen/exceptions.dart';
import 'package:gengen/plugin/lua/lua_plugin.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:path/path.dart' as p;

typedef PluginInitializer = BasePlugin? Function(PluginMetadata metadata);

PluginInitializer? _initializer;

void registerPluginInitializer(PluginInitializer initializer) {
  _initializer = initializer;
}

BasePlugin? initializePlugin(PluginMetadata metadata) {
  if (_initializer != null) {
    return _initializer!(metadata);
  }

  if (_isLuaEntrypoint(metadata.entrypoint)) {
    try {
      return LuaPlugin(metadata);
    } on PluginException {
      rethrow;
    } catch (error, stackTrace) {
      throw PluginException(
        'Failed to initialize Lua plugin "${metadata.name}"',
        error,
        stackTrace,
      );
    }
  }

  final fileTypes = metadata.files.map((f) => p.extension(f.path)).toSet();

  if (fileTypes.contains('.dart')) {
    log.warning(
      'Plugin "${metadata.name}" contains Dart sources, but Dart-based plugins '
      'are no longer supported.',
    );
  }

  return null;
}

bool _isLuaEntrypoint(String entrypoint) {
  final separatorIndex = entrypoint.lastIndexOf(':');
  if (separatorIndex == -1) return false;
  final filePart = entrypoint.substring(0, separatorIndex).trim();
  return filePart.toLowerCase().endsWith('.lua');
}

bool isLuaEntrypoint(String entrypoint) {
  return _isLuaEntrypoint(entrypoint);
}
