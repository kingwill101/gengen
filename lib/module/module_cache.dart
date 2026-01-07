import 'dart:io' as io;

import 'package:gengen/fs.dart';
import 'package:gengen/logging.dart';
import 'package:path/path.dart' as p;

/// Manages the module cache directory (~/.gengen/cache/modules/)
class ModuleCache {
  final String cacheRoot;

  ModuleCache({String? cacheRoot})
    : cacheRoot = cacheRoot ?? _defaultCacheRoot();

  static String _defaultCacheRoot() {
    final home = _getHomeDirectory();
    return p.join(home, '.gengen', 'cache', 'modules');
  }

  static String _getHomeDirectory() {
    // Try environment variables at runtime
    final home =
        io.Platform.environment['HOME'] ??
        io.Platform.environment['USERPROFILE'];

    if (home != null && home.isNotEmpty) {
      return home;
    }

    // Fallback: try to derive from current directory
    final cwd = fs.currentDirectory.path;
    final parts = p.split(cwd);
    if (parts.length >= 3) {
      // Assume /home/user or /Users/user or C:\Users\user
      return p.joinAll(parts.take(3));
    }

    return p.join(cwd, '.gengen-cache');
  }

  /// Get the cache path for a module
  String getModulePath(String modulePath, String version) {
    return p.join(cacheRoot, modulePath, version);
  }

  /// Check if a module version is cached
  bool isCached(String modulePath, String version) {
    final cachePath = getModulePath(modulePath, version);
    return fs.directory(cachePath).existsSync();
  }

  /// Get all cached versions for a module
  List<String> getCachedVersions(String modulePath) {
    final moduleDir = fs.directory(p.join(cacheRoot, modulePath));
    if (!moduleDir.existsSync()) return [];

    return moduleDir
        .listSync()
        .whereType<Directory>()
        .map((d) => p.basename(d.path))
        .toList();
  }

  /// Create cache directory for a module
  Directory createCacheDirectory(String modulePath, String version) {
    final cachePath = getModulePath(modulePath, version);
    final dir = fs.directory(cachePath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Remove a specific cached module version
  void removeModule(String modulePath, String version) {
    final cachePath = getModulePath(modulePath, version);
    final dir = fs.directory(cachePath);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
      log.info('Removed cached module: $modulePath@$version');
    }
  }

  /// Remove all versions of a cached module
  void removeAllVersions(String modulePath) {
    final moduleDir = fs.directory(p.join(cacheRoot, modulePath));
    if (moduleDir.existsSync()) {
      moduleDir.deleteSync(recursive: true);
      log.info('Removed all cached versions of: $modulePath');
    }
  }

  /// Get total size of cache in bytes
  int getCacheSize() {
    final cacheDir = fs.directory(cacheRoot);
    if (!cacheDir.existsSync()) return 0;

    var size = 0;
    for (final entity in cacheDir.listSync(recursive: true)) {
      if (entity is File) {
        size += entity.lengthSync();
      }
    }
    return size;
  }

  /// Clear the entire cache
  void clearCache() {
    final cacheDir = fs.directory(cacheRoot);
    if (cacheDir.existsSync()) {
      cacheDir.deleteSync(recursive: true);
      log.info('Cleared module cache');
    }
  }

  /// Ensure cache root directory exists
  void ensureCacheExists() {
    final cacheDir = fs.directory(cacheRoot);
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
  }
}
