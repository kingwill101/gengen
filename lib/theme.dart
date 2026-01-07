import 'package:gengen/configuration.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/module/module.dart';
import 'package:gengen/path.dart';
import 'package:path/path.dart' as p;

class Theme with PathMixin {
  String name;
  bool loaded = false;
  String? location;

  Theme.load(
    this.name, {
    String? themePath = "_themes",
    required Configuration config,
  }) {
    this.configuration = config;
    decideLocation(themePath);
  }

  void decideLocation(String? themePath) {
    // Check if name looks like a module path
    if (_isModulePath(name)) {
      final modulePath = _resolveModulePath(name);
      if (modulePath != null) {
        loaded = true;
        location = modulePath;
        _loadThemeConfig();
        return;
      }
    }

    // Try to find theme in cached modules
    final moduleTheme = _findThemeInModules(name);
    if (moduleTheme != null) {
      loaded = true;
      location = moduleTheme;
      _loadThemeConfig();
      return;
    }

    // Fall back to local theme directories
    var locations = [
      p.join(themePath ?? "", name),
      p.join(p.current, config.get<String>("themes_dir"), name),
    ];

    for (var local in locations) {
      if (fs.directory(local).existsSync()) {
        loaded = true;
        location = local;
        break;
      }
    }

    if (!loaded) {
      log.warning("Theme($name): not found");
      return;
    }

    _loadThemeConfig();
  }

  void _loadThemeConfig() {
    var configFile = p.joinAll([location!, "config.yaml"]);

    if (fs.file(configFile).existsSync()) {
      config.read(readConfigFile(configFile) as Map<String, dynamic>);
    }
  }

  /// Check if the theme name looks like a module path
  bool _isModulePath(String name) {
    return name.startsWith('github.com/') ||
        name.startsWith('gitlab.com/') ||
        name.startsWith('bitbucket.org/') ||
        name.startsWith('pub:') ||
        name.startsWith('./') ||
        name.startsWith('../');
  }

  /// Try to resolve theme from module cache
  String? _resolveModulePath(String modulePath) {
    final cache = ModuleCache();
    final versions = cache.getCachedVersions(modulePath);

    if (versions.isNotEmpty) {
      // Use most recent version (simple approach - last in list)
      final version = versions.last;
      final cachePath = cache.getModulePath(modulePath, version);
      if (fs.directory(cachePath).existsSync()) {
        log.fine('Resolved theme from module cache: $modulePath@$version');
        return cachePath;
      }
    }

    return null;
  }

  /// Find a theme by name within cached modules
  /// Searches for theme subdirectories inside each cached module
  String? _findThemeInModules(String themeName) {
    final cache = ModuleCache();
    final moduleSection = config.get<Map<String, dynamic>>('module');

    if (moduleSection == null) return null;

    final manifest = ModuleManifest.parse(moduleSection);
    if (!manifest.hasImports) return null;

    // Load lockfile to get pinned versions
    final lockfile = ModuleLockfile.load(config.source);

    for (final import_ in manifest.imports) {
      // Get the cached module path
      String? modulePath;

      // Check for replacement
      final replacement = manifest.getReplacementFor(import_.path);
      if (replacement != null) {
        modulePath = p.isAbsolute(replacement)
            ? replacement
            : p.join(config.source, replacement);
      } else {
        // Use locked version if available
        final locked = lockfile.getPackage(import_.path);
        if (locked != null) {
          modulePath = cache.getModulePath(import_.path, locked.version);
        } else {
          // Fall back to latest cached version
          final versions = cache.getCachedVersions(import_.path);
          if (versions.isNotEmpty) {
            modulePath = cache.getModulePath(import_.path, versions.last);
          }
        }
      }

      if (modulePath == null) continue;

      // Check multiple possible locations for the theme
      final possiblePaths = [
        p.join(modulePath, themeName), // Direct: module/themeName
        p.join(
          modulePath,
          'themes',
          themeName,
        ), // Standard: module/themes/themeName
        p.join(
          modulePath,
          '_themes',
          themeName,
        ), // Jekyll-style: module/_themes/themeName
      ];

      for (final themePath in possiblePaths) {
        if (fs.directory(themePath).existsSync()) {
          final configFile = fs.file(p.join(themePath, 'config.yaml'));
          if (configFile.existsSync()) {
            log.fine('Found theme "$themeName" in module ${import_.path}');
            return themePath;
          }
          // Also check for theme without config (layouts/includes exist)
          final hasLayouts = fs
              .directory(p.join(themePath, '_layouts'))
              .existsSync();
          final hasIncludes = fs
              .directory(p.join(themePath, '_includes'))
              .existsSync();
          if (hasLayouts || hasIncludes) {
            log.fine(
              'Found theme "$themeName" in module ${import_.path} (no config)',
            );
            return themePath;
          }
        }
      }
    }

    return null;
  }

  @override
  String get root => p.canonicalize(location ?? '');
}
