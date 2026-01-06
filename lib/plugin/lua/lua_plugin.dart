import 'dart:async';

import 'package:gengen/exceptions.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/plugin/lua/stdlib/gengen_stdlib.dart';
import 'package:gengen/plugin/lua/value_utils.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:gengen/site.dart';
import 'package:lualike/lualike.dart';
import 'package:path/path.dart' as p;

class LuaPlugin extends BasePlugin {
  LuaPlugin(this.metadata, {FileSystem? fileSystem})
    : _fs = fileSystem ?? fs,
      _entrypoint = _LuaEntrypoint.parse(metadata.entrypoint);

  @override
  final PluginMetadata metadata;

  final FileSystem _fs;
  final _LuaEntrypoint _entrypoint;
  final LuaLike _runtime = LuaLike();
  final Map<String, Value?> _functionCache = {};

  Value? _pluginTable;
  Future<void>? _initFuture;
  bool _initialized = false;

  String _cachedHeadInjection = '';
  String _cachedBodyInjection = '';
  List<String> _cachedCssAssets = const [];
  List<String> _cachedJsAssets = const [];
  Map<String, String> _cachedMetaTags = const {};
  Map<String, LiquidFilter> _cachedLiquidFilters = const {};

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initFuture ??= _loadAndInit();
    try {
      await _initFuture;
      _initialized = true;
    } finally {
      if (!_initialized) {
        _functionCache.clear();
        _pluginTable = null;
      }
    }
  }

  Future<void> _loadAndInit() async {
    final entryAsset = _resolveEntrypointAsset();
    final scriptPath = p.normalize(entryAsset.path);

    await _registerLuaAssets();

    installGengenStdLib(
      vm: _runtime.vm,
      metadata: metadata,
      fileSystem: _fs,
      logger: logger,
      site: Site.instance,
    );

    final script = await _fs.file(scriptPath).readAsString();
    await _runtime.execute(script, scriptPath: scriptPath);

    final metadataValue = wrapDynamic(metadata.toJson());
    _runtime.setGlobal('PLUGIN_METADATA', metadataValue);
    _runtime.setGlobal('PLUGIN_NAME', Value(metadata.name));
    if (metadata.path != null) {
      _runtime.setGlobal('PLUGIN_ROOT', Value(metadata.path!));
    }

    final initResult = await _invokeInitializer(
      metadataValue,
      scriptPath: scriptPath,
    );
    _pluginTable = initResult;

    await _populateSynchronousCaches();
  }

  Future<Value> _invokeInitializer(
    Value metadataValue, {
    required String scriptPath,
  }) async {
    dynamic result;
    try {
      result = await _runtime.call(_entrypoint.function, [metadataValue]);
    } catch (error, stackTrace) {
      throw PluginException(
        'Lua plugin "${metadata.name}" failed to run initializer '
        '"${_entrypoint.function}" in ${_entrypoint.file}',
        error,
        stackTrace,
      );
    }

    final value = _coerceToValue(result);
    if (!value.isTable) {
      throw PluginException(
        'Lua plugin "${metadata.name}" initializer must return a table, '
        'got ${value.raw.runtimeType}',
      );
    }

    return value;
  }

  Future<void> _registerLuaAssets() async {
    if (metadata.path != null) {
      _runtime.vm.fileManager.addSearchPath(metadata.path!);
    }

    for (final asset in metadata.files) {
      final normalizedPath = p.normalize(asset.path);

      if (!_fs.file(normalizedPath).existsSync()) {
        continue;
      }

      if (!normalizedPath.toLowerCase().endsWith('.lua')) {
        continue;
      }

      final content = await _fs.file(normalizedPath).readAsString();
      _runtime.vm.fileManager.registerVirtualFile(normalizedPath, content);

      if (metadata.path != null) {
        final relative = p.normalize(
          p.relative(normalizedPath, from: metadata.path!),
        );
        _runtime.vm.fileManager.registerVirtualFile(relative, content);
      }
    }
  }

  PluginAsset _resolveEntrypointAsset() {
    final candidates = metadata.files.where((asset) {
      final normalizedPath = p.normalize(asset.path);
      if (normalizedPath.toLowerCase().endsWith(_entrypoint.file)) {
        return true;
      }
      if (p.basename(normalizedPath) == _entrypoint.file) {
        return true;
      }
      if (asset.name == _entrypoint.file) {
        return true;
      }
      return false;
    }).toList();

    if (candidates.isEmpty) {
      throw PluginException(
        'Lua plugin "${metadata.name}" entrypoint "${_entrypoint.file}" '
        'not found among registered plugin assets.',
      );
    }

    // Prefer the most specific match (exact path match first)
    candidates.sort((a, b) {
      final aExact =
          p.normalize(a.path) == _entrypoint.normalizedPath(metadata);
      final bExact =
          p.normalize(b.path) == _entrypoint.normalizedPath(metadata);
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;
      return a.path.length.compareTo(b.path.length);
    });

    return candidates.first;
  }

  Future<void> _populateSynchronousCaches() async {
    _cachedHeadInjection = await _invokeStringHook(
      'head_injection',
      defaultValue: '',
    );
    _cachedBodyInjection = await _invokeStringHook(
      'body_injection',
      defaultValue: '',
    );
    _cachedCssAssets = await _invokeStringListHook('css_assets');
    _cachedJsAssets = await _invokeStringListHook('js_assets');
    _cachedMetaTags = await _invokeStringMapHook('meta_tags');
    _cachedLiquidFilters = await _invokeFilterMapHook('liquid_filters');
  }

  Future<String> _invokeStringHook(
    String field, {
    required String defaultValue,
  }) async {
    final entry = _pluginTable?[field];
    if (entry == null) return defaultValue;

    final callable = _coerceToCallable(entry);
    if (callable != null) {
      final result = await _invokeLuaFunction(callable, field, const []);
      final value = unwrapValue(result);
      if (value == null) return defaultValue;
      if (value is String) return value;
      throw PluginException(
        'Lua plugin "${metadata.name}" hook "$field" must return a string.',
      );
    }

    final value = unwrapValue(entry);
    if (value == null) return defaultValue;
    if (value is String) return value;
    throw PluginException(
      'Lua plugin "${metadata.name}" hook "$field" must return a string.',
    );
  }

  Future<List<String>> _invokeStringListHook(String field) async {
    final entry = _pluginTable?[field];
    if (entry == null) return const [];

    final callable = _coerceToCallable(entry);
    if (callable != null) {
      final result = await _invokeLuaFunction(callable, field, const []);
      return _coerceToStringList(field, result);
    }

    return _coerceToStringList(field, entry);
  }

  Future<Map<String, String>> _invokeStringMapHook(String field) async {
    final entry = _pluginTable?[field];
    if (entry == null) return const {};

    final callable = _coerceToCallable(entry);
    if (callable != null) {
      final result = await _invokeLuaFunction(callable, field, const []);
      return _coerceToStringMap(field, result);
    }

    return _coerceToStringMap(field, entry);
  }

  Value? _coerceToCallable(dynamic entry) {
    if (entry is Value) {
      if (_isCallable(entry)) {
        return entry;
      }
      return null;
    }

    if (entry is Function) {
      return Value(entry);
    }

    return null;
  }

  bool _isCallable(Value value) {
    final raw = value.raw;
    if (raw is Function) return true;
    if (raw is BuiltinFunction) return true;
    if (raw is FunctionDef || raw is FunctionLiteral || raw is FunctionBody) {
      return true;
    }
    return value.hasMetamethod('__call');
  }

  List<String> _coerceToStringList(String field, Object? value) {
    final data = unwrapValue(value);
    if (data == null) return const [];

    if (data is List) {
      return data
          .map(
            (item) =>
                _expectString(field, item, messageSuffix: 'list of strings'),
          )
          .toList(growable: false);
    }

    if (data is Map) {
      final orderedEntries = data.entries
          .map((entry) => MapEntry(entry.key.toString(), entry.value))
          .toList();
      final numericEntries =
          orderedEntries
              .map((entry) => MapEntry(int.tryParse(entry.key), entry.value))
              .where((entry) => entry.key != null)
              .toList()
            ..sort((a, b) => a.key!.compareTo(b.key!));

      if (numericEntries.isEmpty) {
        throw PluginException(
          'Lua plugin "${metadata.name}" hook "$field" must return a list of strings.',
        );
      }

      return numericEntries
          .map(
            (entry) => _expectString(
              field,
              entry.value,
              messageSuffix: 'list of strings',
            ),
          )
          .toList(growable: false);
    }

    throw PluginException(
      'Lua plugin "${metadata.name}" hook "$field" must return a list of strings.',
    );
  }

  Map<String, String> _coerceToStringMap(String field, Object? value) {
    final data = unwrapValue(value);
    if (data == null) return {};
    if (data is! Map) {
      throw PluginException(
        'Lua plugin "${metadata.name}" hook "$field" must return a map of string values.',
      );
    }

    final result = <String, String>{};
    for (final entry in data.entries) {
      final key = entry.key.toString();
      final stringValue = _expectString(
        field,
        entry.value,
        messageSuffix: 'map of string values',
      );
      result[key] = stringValue;
    }
    return result;
  }

  Future<Map<String, LiquidFilter>> _invokeFilterMapHook(String field) async {
    final entry = _pluginTable?[field];
    if (entry == null) return const {};

    final callable = _coerceToCallable(entry);
    Object? result;
    if (callable != null) {
      result = await _invokeLuaFunction(callable, field, const []);
    } else {
      result = entry;
    }

    return _coerceToFilterMap(field, result);
  }

  Map<String, LiquidFilter> _coerceToFilterMap(String field, Object? value) {
    final data = unwrapValue(value);
    if (data == null) return {};
    if (data is! Map) {
      throw PluginException(
        'Lua plugin "${metadata.name}" hook "$field" must return a map of filter functions.',
      );
    }

    final result = <String, LiquidFilter>{};
    for (final entry in data.entries) {
      final name = entry.key.toString();
      final rawFn = _coerceToCallable(entry.value);
      if (rawFn == null) {
        throw PluginException(
          'Lua plugin "${metadata.name}" hook "$field" must map "$name" to a function.',
        );
      }
      result[name] = (value, args, namedArgs) {
        return _invokeFilterFunction(
          field,
          name,
          rawFn,
          value,
          args,
          namedArgs,
        );
      };
    }
    return result;
  }

  Future<Object> _invokeFilterFunction(
    String hook,
    String filterName,
    Value fn,
    Object? value,
    List<dynamic> args,
    Map<String, dynamic> namedArgs,
  ) async {
    try {
      final result = await _runtime.vm.callFunction(fn, [
        wrapDynamic(value),
        wrapDynamic(args),
        wrapDynamic(namedArgs),
      ]);
      final resolved = unwrapValue(result);
      if (resolved == null) {
        throw PluginException(
          'Lua plugin "${metadata.name}" filter "$filterName" returned nil.',
        );
      }
      return resolved;
    } catch (error, stackTrace) {
      if (error is PluginException) rethrow;
      throw PluginException(
        'Lua plugin "${metadata.name}" filter "$filterName" threw an error.',
        error,
        stackTrace,
      );
    }
  }

  String _expectString(
    String field,
    Object? value, {
    required String messageSuffix,
  }) {
    final resolved = unwrapValue(value);
    if (resolved is String) return resolved;
    throw PluginException(
      'Lua plugin "${metadata.name}" hook "$field" must return a $messageSuffix.',
    );
  }

  Future<Object?> _invokeLuaFunction(
    Value fn,
    String hook,
    List<Object?> args,
  ) async {
    try {
      return await _runtime.vm.callFunction(fn, args);
    } catch (error, stackTrace) {
      throw PluginException(
        'Lua plugin "${metadata.name}" hook "$hook" threw an error',
        error,
        stackTrace,
      );
    }
  }

  Value _coerceToValue(Object? value) {
    if (value is List && value.isNotEmpty) {
      return wrapDynamic(value.first);
    }
    return wrapDynamic(value);
  }

  Value? _getFunction(String field) {
    if (_functionCache.containsKey(field)) {
      return _functionCache[field];
    }
    final entry = _pluginTable?[field];
    if (entry == null) {
      _functionCache[field] = null;
      return null;
    }

    final callable = _coerceToCallable(entry);
    _functionCache[field] = callable;
    return callable;
  }

  Future<void> _runLifecycleHook(String field) async {
    final fn = _getFunction(field);
    if (fn == null) return;
    await _invokeLuaFunction(fn, field, const []);
  }

  @override
  Future<void> afterInit() async {
    await _ensureInitialized();
    await _runLifecycleHook('after_init');
    await _populateSynchronousCaches();
  }

  @override
  FutureOr<void> beforeRead() async {
    await _ensureInitialized();
    await _runLifecycleHook('before_read');
  }

  @override
  FutureOr<void> afterRead() async {
    await _ensureInitialized();
    await _runLifecycleHook('after_read');
  }

  @override
  FutureOr<void> beforeGenerate() async {
    await _ensureInitialized();
    await _runLifecycleHook('before_generate');
  }

  @override
  FutureOr<void> afterGenerate() async {
    await _ensureInitialized();
    await _runLifecycleHook('after_generate');
  }

  @override
  FutureOr<void> beforeRender() async {
    await _ensureInitialized();
    await _runLifecycleHook('before_render');
  }

  @override
  FutureOr<void> afterRender() async {
    await _ensureInitialized();
    await _runLifecycleHook('after_render');
  }

  @override
  FutureOr<void> beforeWrite() async {
    await _ensureInitialized();
    await _runLifecycleHook('before_write');
  }

  @override
  FutureOr<void> afterWrite() async {
    await _ensureInitialized();
    await _runLifecycleHook('after_write');
  }

  @override
  FutureOr<void> generate() async {
    await _ensureInitialized();
    await _runLifecycleHook('generate');
  }

  @override
  FutureOr<void> beforeConvert() async {
    await _ensureInitialized();
    await _runLifecycleHook('before_convert');
  }

  @override
  FutureOr<void> afterConvert() async {
    await _ensureInitialized();
    await _runLifecycleHook('after_convert');
  }

  @override
  FutureOr<String> convert(String content, Base page) async {
    await _ensureInitialized();
    final fn = _getFunction('convert');
    if (fn == null) return content;

    final result = await _invokeLuaFunction(fn, 'convert', [
      Value(content),
      wrapDynamic(page.toJson()),
    ]);

    final unwrapped = unwrapValue(result);
    if (unwrapped == null) {
      throw PluginException(
        'Lua plugin "${metadata.name}" hook "convert" returned nil.',
      );
    }

    if (unwrapped is String) {
      return unwrapped;
    }

    throw PluginException(
      'Lua plugin "${metadata.name}" hook "convert" must return a string.',
    );
  }

  @override
  String getHeadInjection() => _cachedHeadInjection;

  @override
  String getBodyInjection() => _cachedBodyInjection;

  @override
  List<String> getCssAssets() => _cachedCssAssets;

  @override
  List<String> getJsAssets() => _cachedJsAssets;

  @override
  Map<String, String> getMetaTags() => _cachedMetaTags;

  @override
  Map<String, LiquidFilter> getLiquidFilters() => _cachedLiquidFilters;
}

class _LuaEntrypoint {
  const _LuaEntrypoint(this.file, this.function);

  final String file;
  final String function;

  static _LuaEntrypoint parse(String entrypoint) {
    final parts = entrypoint.split(':');
    if (parts.length != 2) {
      throw PluginException(
        'Lua plugin entrypoint must be "<file>.lua:<initFunction>" '
        '(received "$entrypoint").',
      );
    }
    final file = parts.first.trim();
    final function = parts.last.trim();

    if (!file.toLowerCase().endsWith('.lua')) {
      throw PluginException(
        'Lua plugin entrypoint file must end with .lua (received "$file").',
      );
    }

    if (function.isEmpty) {
      throw PluginException(
        'Lua plugin entrypoint must specify an initializer function.',
      );
    }

    return _LuaEntrypoint(file, function);
  }

  String normalizedPath(PluginMetadata metadata) {
    if (metadata.path == null) return p.normalize(file);
    return p.normalize(p.join(metadata.path!, file));
  }
}
