import 'package:gengen/fs.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/module/module_cache.dart';
import 'package:gengen/module/module_import.dart';
import 'package:gengen/module/module_lockfile.dart';
import 'package:gengen/module/module_manifest.dart';
import 'package:gengen/module/module_source.dart';
import 'package:gengen/module/sources.dart';
import 'package:path/path.dart' as p;

/// Main module resolver - coordinates resolution from various sources
class ModuleResolver {
  final String siteRoot;
  final ModuleManifest manifest;
  final ModuleLockfile lockfile;
  final ModuleCache cache;

  late final List<ModuleSourceHandler> _sources;

  ModuleResolver({
    required this.siteRoot,
    required this.manifest,
    required this.lockfile,
    ModuleCache? cache,
  }) : cache = cache ?? ModuleCache() {
    _sources = [
      LocalModuleSource(siteRoot: siteRoot),
      GitModuleSource(cache: this.cache),
      PubModuleSource(cache: this.cache),
    ];
  }

  /// Resolve all modules from the manifest
  Future<List<ResolvedModule>> resolveAll({bool update = false}) async {
    final resolved = <ResolvedModule>[];

    for (final import_ in manifest.imports) {
      final module = await resolve(import_, update: update);
      if (module != null) {
        resolved.add(module);
      } else {
        log.warning('Failed to resolve module: ${import_.path}');
      }
    }

    return resolved;
  }

  /// Resolve a single module import
  Future<ResolvedModule?> resolve(
    ModuleImport import_, {
    bool update = false,
  }) async {
    // Check for replacement first
    final replacement = manifest.getReplacementFor(import_.path);
    if (replacement != null) {
      final replacementPath = p.isAbsolute(replacement)
          ? replacement
          : p.join(siteRoot, replacement);

      if (fs.directory(replacementPath).existsSync()) {
        log.fine('Using replacement for ${import_.path}: $replacement');
        return ResolvedModule(
          import_: import_,
          resolvedPath: replacementPath,
          resolvedVersion: 'local',
          source: ModuleSource.replacement,
        );
      } else {
        log.warning(
          'Replacement path not found for ${import_.path}: $replacement',
        );
      }
    }

    // Check lockfile unless updating
    LockedModule? locked;
    if (!update && lockfile.hasPackage(import_.path)) {
      locked = lockfile.getPackage(import_.path);
    }

    // Find appropriate handler
    for (final source in _sources) {
      if (source.canHandle(import_)) {
        final resolved = await source.resolve(
          import_,
          lockVersion: locked?.version,
          lockSha: locked?.sha,
        );

        if (resolved != null) {
          // Update lockfile with resolved version
          lockfile.setPackage(
            import_.path,
            LockedModule(
              path: import_.path,
              version: resolved.resolvedVersion,
              resolved: resolved.resolvedPath,
              sha: resolved.sha,
              lockedAt: DateTime.now(),
            ),
          );
          return resolved;
        }
      }
    }

    return null;
  }

  /// Fetch a module (force download/update)
  Future<ResolvedModule?> fetch(ModuleImport import_) async {
    for (final source in _sources) {
      if (source.canHandle(import_)) {
        final resolved = await source.fetch(import_);
        if (resolved != null) {
          lockfile.setPackage(
            import_.path,
            LockedModule(
              path: import_.path,
              version: resolved.resolvedVersion,
              resolved: resolved.resolvedPath,
              sha: resolved.sha,
              lockedAt: DateTime.now(),
            ),
          );
          return resolved;
        }
      }
    }
    return null;
  }

  /// Update specific modules or all if none specified
  Future<List<ResolvedModule>> update([List<String>? modulePaths]) async {
    final toUpdate =
        modulePaths ?? manifest.imports.map((i) => i.path).toList();
    final resolved = <ResolvedModule>[];

    for (final path in toUpdate) {
      final import_ = manifest.imports.firstWhere(
        (i) => i.path == path,
        orElse: () => throw ArgumentError('Module not in manifest: $path'),
      );

      // Remove from lockfile to force re-resolution
      lockfile.removePackage(path);

      final module = await fetch(import_);
      if (module != null) {
        resolved.add(module);
        log.info('Updated: ${module.path}@${module.resolvedVersion}');
      } else {
        log.warning('Failed to update: $path');
      }
    }

    return resolved;
  }

  /// Remove unused modules from cache
  Future<void> tidy() async {
    final usedPaths = manifest.imports.map((i) => i.path).toSet();
    final lockedPaths = lockfile.packages.keys.toSet();

    // Remove from lockfile if not in manifest
    for (final path in lockedPaths.difference(usedPaths)) {
      lockfile.removePackage(path);
      log.info('Removed from lockfile: $path');
    }
  }

  /// Verify that all cached modules match lockfile
  Future<bool> verify() async {
    var allValid = true;

    for (final entry in lockfile.packages.entries) {
      final path = entry.key;
      final locked = entry.value;

      // Find the import
      final import_ = manifest.imports.firstWhere(
        (i) => i.path == path,
        orElse: () => ModuleImport(path: path, type: ModuleType.fromPath(path)),
      );

      // Resolve without using lockfile
      for (final source in _sources) {
        if (source.canHandle(import_)) {
          final resolved = await source.resolve(
            import_,
            lockVersion: locked.version,
            lockSha: locked.sha,
          );

          if (resolved == null) {
            log.warning('Module not found: $path');
            allValid = false;
          } else if (locked.sha != null && resolved.sha != locked.sha) {
            log.warning(
              'SHA mismatch for $path: expected ${locked.sha}, got ${resolved.sha}',
            );
            allValid = false;
          }
          break;
        }
      }
    }

    return allValid;
  }

  /// Save the lockfile
  void saveLockfile() {
    lockfile.save();
    log.fine('Saved lockfile: ${lockfile.lockfilePath}');
  }
}
