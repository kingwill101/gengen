import 'package:file/file.dart';
import 'package:gengen/plugin/lua/value_utils.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart' as utils;
import 'package:lualike/lualike.dart';
import 'package:logging/logging.dart' as dart_logging;
import 'package:path/path.dart' as p;

void installGengenStdLib({
  required Interpreter vm,
  required PluginMetadata metadata,
  required FileSystem fileSystem,
  required dart_logging.Logger logger,
  required Site site,
}) {
  final pluginRoot = metadata.path;

  String stringArg(List<Object?> args, int index, {String fallback = ''}) {
    if (index >= args.length) return fallback;
    final value = unwrapValue(args[index]);
    if (value == null) return fallback;
    return value.toString();
  }

  Value luaFn(Object? Function(List<Object?> args) impl) => Value(impl);

  Value nil() => Value(null);

  String? resolvePluginPath(String relative) {
    if (pluginRoot == null) return null;
    final normalized = relative.isEmpty
        ? pluginRoot
        : p.join(pluginRoot, relative);
    return p.normalize(normalized);
  }

  Value protect(Object? value) {
    if (value is String) {
      return Value(LuaString.fromDartString(value));
    }
    return wrapDynamic(value);
  }

  final logTable = {
    'debug': luaFn((args) {
      final message = stringArg(args, 0);
      logger.fine(message);
      return nil();
    }),
    'info': luaFn((args) {
      final message = stringArg(args, 0);
      logger.info(message);
      return nil();
    }),
    'warn': luaFn((args) {
      final message = stringArg(args, 0);
      logger.warning(message);
      return nil();
    }),
    'error': luaFn((args) {
      final message = stringArg(args, 0);
      logger.severe(message);
      return nil();
    }),
  };

  final configTable = {
    'get': luaFn((args) {
      final key = stringArg(args, 0);
      final defaultValue = args.length > 1 ? unwrapValue(args[1]) : null;
      final value = site.config.get<dynamic>(key, defaultValue: defaultValue);
      return protect(value);
    }),
  };

  final pathsTable = {
    'plugin': luaFn((args) {
      final relative = stringArg(args, 0);
      final resolved = resolvePluginPath(relative);
      return resolved == null ? nil() : protect(resolved);
    }),
    'plugin_root': luaFn(
      (_) => pluginRoot == null ? nil() : protect(p.normalize(pluginRoot)),
    ),
    'site_source': luaFn((args) {
      final relative = stringArg(args, 0);
      final root = site.config.source;
      final resolved = relative.isEmpty ? root : p.join(root, relative);
      return protect(p.normalize(resolved));
    }),
    'site_destination': luaFn((args) {
      final relative = stringArg(args, 0);
      final root = site.destination.path;
      final resolved = relative.isEmpty ? root : p.join(root, relative);
      return protect(p.normalize(resolved));
    }),
    'join': luaFn((args) {
      final parts = args.map((e) => stringArg([e], 0)).toList();
      return protect(p.joinAll(parts));
    }),
    'basename': luaFn((args) => protect(p.basename(stringArg(args, 0)))),
    'dirname': luaFn((args) => protect(p.dirname(stringArg(args, 0)))),
  };

  String? readFile(String base, String relative) {
    final absolute = p.normalize(p.join(base, relative));
    final file = fileSystem.file(absolute);
    if (!file.existsSync()) return null;
    return file.readAsStringSync();
  }

  bool writeFile(String base, String relative, String contents) {
    final absolute = p.normalize(p.join(base, relative));
    final directory = fileSystem.directory(p.dirname(absolute));
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    final file = fileSystem.file(absolute);
    file.writeAsStringSync(contents);
    return true;
  }

  bool fileExists(String base, String relative) {
    final absolute = p.normalize(p.join(base, relative));
    return fileSystem.file(absolute).existsSync();
  }

  final contentTable = {
    'read_plugin': luaFn((args) {
      final relative = stringArg(args, 0);
      final root = pluginRoot;
      if (root == null) return nil();
      final result = readFile(root, relative);
      return result == null ? nil() : protect(result);
    }),
    'read_site': luaFn((args) {
      final relative = stringArg(args, 0);
      final result = readFile(site.config.source, relative);
      return result == null ? nil() : protect(result);
    }),
    'write_site': luaFn((args) {
      final relative = stringArg(args, 0);
      final content = stringArg(args, 1);
      final success = writeFile(site.destination.path, relative, content);
      return protect(success);
    }),
    'exists_plugin': luaFn((args) {
      final relative = stringArg(args, 0);
      final root = pluginRoot;
      if (root == null) return protect(false);
      return protect(fileExists(root, relative));
    }),
    'exists_site': luaFn((args) {
      final relative = stringArg(args, 0);
      return protect(fileExists(site.config.source, relative));
    }),
  };

  final utilTable = {
    'slugify': luaFn((args) => protect(utils.slugify(stringArg(args, 0)))),
    'contains_markdown': luaFn(
      (args) => protect(utils.containsMarkdown(stringArg(args, 0))),
    ),
    'excerpt': luaFn((args) {
      final html = stringArg(args, 0);
      final maxLengthValue = args.length > 1 ? unwrapValue(args[1]) : null;
      final maxLength = maxLengthValue is num ? maxLengthValue.toInt() : 200;
      final excerpt = utils.extractExcerpt(html, maxLength: maxLength);
      return protect(excerpt);
    }),
    'parse_date': luaFn((args) {
      final dateString = stringArg(args, 0);
      final formatValue = args.length > 1 ? unwrapValue(args[1]) : null;
      final format = formatValue is String
          ? formatValue
          : "yyyy-MM-dd HH:mm:ss";
      final parsed = utils
          .parseDate(dateString, format: format)
          .toIso8601String();
      return protect(parsed);
    }),
  };

  final pluginTable = {
    'name': protect(metadata.name),
    'version': protect(metadata.version ?? ''),
    'description': protect(metadata.description ?? ''),
    'author': protect(metadata.author ?? ''),
    'path': pluginRoot == null ? nil() : protect(p.normalize(pluginRoot)),
    'metadata': protect(metadata.toJson()),
  };

  final gengenTable = {
    'log': Value(logTable),
    'config': Value(configTable),
    'paths': Value(pathsTable),
    'content': Value(contentTable),
    'util': Value(utilTable),
    'plugin': Value(pluginTable),
  };

  vm.globals.define('gengen', Value(gengenTable));
}
