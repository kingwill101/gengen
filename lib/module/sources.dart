import 'dart:io' as io;

import 'package:gengen/fs.dart';
import 'package:gengen/module/module_cache.dart';
import 'package:gengen/module/module_import.dart';
import 'package:gengen/module/module_source.dart';
import 'package:gengen/module/version_constraint.dart';
import 'package:path/path.dart' as p;

/// Handles local path module sources (./path, ../path, /absolute/path)
class LocalModuleSource implements ModuleSourceHandler {
  final String siteRoot;

  LocalModuleSource({required this.siteRoot});

  @override
  bool canHandle(ModuleImport import_) => import_.type == ModuleType.local;

  @override
  Future<ResolvedModule?> resolve(
    ModuleImport import_, {
    String? lockVersion,
    String? lockSha,
  }) async {
    final resolvedPath = _resolvePath(import_.path);

    if (!fs.directory(resolvedPath).existsSync()) {
      return null;
    }

    return ResolvedModule(
      import_: import_,
      resolvedPath: resolvedPath,
      resolvedVersion: 'local',
      source: ModuleSource.local,
    );
  }

  @override
  Future<ResolvedModule?> fetch(ModuleImport import_) async {
    // Local modules don't need fetching
    return resolve(import_);
  }

  @override
  Future<List<String>> listVersions(ModuleImport import_) async {
    // Local modules don't have versions
    return ['local'];
  }

  String _resolvePath(String path) {
    if (p.isAbsolute(path)) {
      return p.normalize(path);
    }
    return p.normalize(p.join(siteRoot, path));
  }
}

/// Handles git repository module sources (github.com/*, gitlab.com/*, etc.)
class GitModuleSource implements ModuleSourceHandler {
  final ModuleCache cache;

  GitModuleSource({required this.cache});

  @override
  bool canHandle(ModuleImport import_) => import_.type == ModuleType.git;

  @override
  Future<ResolvedModule?> resolve(
    ModuleImport import_, {
    String? lockVersion,
    String? lockSha,
  }) async {
    final version = lockVersion ?? import_.version ?? 'main';

    // Check if already cached with exact version
    if (cache.isCached(import_.path, version)) {
      final cachePath = cache.getModulePath(import_.path, version);
      return ResolvedModule(
        import_: import_,
        resolvedPath: cachePath,
        resolvedVersion: version,
        sha: lockSha,
        source: ModuleSource.gitCache,
      );
    }

    // For semver constraints, check if any cached version satisfies
    if (version.startsWith('^') || version.contains(' ') || version.startsWith('>=')) {
      final cachedVersions = cache.getCachedVersions(import_.path);
      final matchingCached = _findMatchingCachedVersion(cachedVersions, version);
      if (matchingCached != null) {
        final cachePath = cache.getModulePath(import_.path, matchingCached);
        return ResolvedModule(
          import_: import_,
          resolvedPath: cachePath,
          resolvedVersion: matchingCached,
          source: ModuleSource.gitCache,
        );
      }
    }

    // Need to fetch
    return fetch(import_);
  }

  /// Find a cached version that satisfies the constraint
  String? _findMatchingCachedVersion(List<String> cachedVersions, String constraint) {
    if (cachedVersions.isEmpty) return null;

    try {
      final versionConstraint = VersionConstraint.parse(constraint);

      // Sort versions descending to get latest first
      final sorted = cachedVersions.toList()
        ..sort((a, b) => b.compareTo(a));

      for (final cached in sorted) {
        // Try to parse the cached version
        final cleanVersion = cached.startsWith('v') ? cached.substring(1) : cached;
        final parsed = Version.tryParse(cleanVersion);
        if (parsed != null && versionConstraint.allows(parsed)) {
          return cached;
        }
      }
    } catch (_) {
      // If constraint parsing fails, return null
    }

    return null;
  }

  @override
  Future<ResolvedModule?> fetch(ModuleImport import_) async {
    final version = import_.version ?? 'main';
    final repoUrl = _getGitUrl(import_.path);

    // Determine git ref to checkout
    String gitRef = version;
    if (version.startsWith('branch:')) {
      gitRef = version.substring(7);
    } else if (version.startsWith('tag:')) {
      gitRef = version.substring(4);
    } else if (version.startsWith('commit:')) {
      gitRef = version.substring(7);
    } else if (version.startsWith('^') || version.contains(' ')) {
      // Semver constraint - need to list tags and find matching version
      final tags = await _listGitTags(repoUrl);
      final matchingVersion = _findMatchingVersion(tags, version);
      if (matchingVersion != null) {
        gitRef = matchingVersion;
      }
    }

    // Create cache directory and clone
    final cacheDir = cache.createCacheDirectory(import_.path, gitRef);

    try {
      // Clone or checkout specific ref
      final result = await io.Process.run('git', [
        'clone',
        '--depth',
        '1',
        '--branch',
        gitRef,
        repoUrl,
        cacheDir.path,
      ]);

      if (result.exitCode != 0) {
        // Try without --branch for commit hashes
        final result2 = await io.Process.run('git', [
          'clone',
          repoUrl,
          cacheDir.path,
        ]);

        if (result2.exitCode != 0) {
          return null;
        }

        // Checkout specific commit
        await io.Process.run(
          'git',
          ['checkout', gitRef],
          workingDirectory: cacheDir.path,
        );
      }

      // Get current commit SHA
      final shaResult = await io.Process.run(
        'git',
        ['rev-parse', 'HEAD'],
        workingDirectory: cacheDir.path,
      );
      final sha = shaResult.stdout.toString().trim();

      return ResolvedModule(
        import_: import_,
        resolvedPath: cacheDir.path,
        resolvedVersion: gitRef,
        sha: sha,
        source: ModuleSource.gitCache,
      );
    } catch (e) {
      // Clean up on failure
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
      }
      return null;
    }
  }

  @override
  Future<List<String>> listVersions(ModuleImport import_) async {
    final repoUrl = _getGitUrl(import_.path);
    return _listGitTags(repoUrl);
  }

  String _getGitUrl(String path) {
    // github.com/user/repo -> https://github.com/user/repo.git
    if (!path.startsWith('http')) {
      return 'https://$path.git';
    }
    return path;
  }

  Future<List<String>> _listGitTags(String repoUrl) async {
    try {
      final result = await io.Process.run('git', [
        'ls-remote',
        '--tags',
        repoUrl,
      ]);

      if (result.exitCode != 0) return [];

      final lines = result.stdout.toString().split('\n');
      final tags = <String>[];

      for (final line in lines) {
        final match = RegExp(r'refs/tags/(.+)$').firstMatch(line);
        if (match != null) {
          var tag = match.group(1)!;
          // Skip ^{} dereferenced tags
          if (!tag.endsWith('^{}')) {
            tags.add(tag);
          }
        }
      }

      return tags;
    } catch (_) {
      return [];
    }
  }

  String? _findMatchingVersion(List<String> tags, String constraint) {
    // Simple implementation - find best matching version
    // TODO: Use proper semver constraint matching
    final versions = tags
        .map((t) => t.startsWith('v') ? t : 'v$t')
        .where((t) => RegExp(r'^v?\d+\.\d+\.\d+').hasMatch(t))
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Sort descending

    return versions.isNotEmpty ? versions.first : null;
  }
}

/// Handles pub.dev package sources (pub:package_name)
class PubModuleSource implements ModuleSourceHandler {
  final ModuleCache cache;

  PubModuleSource({required this.cache});

  @override
  bool canHandle(ModuleImport import_) => import_.type == ModuleType.pub;

  @override
  Future<ResolvedModule?> resolve(
    ModuleImport import_, {
    String? lockVersion,
    String? lockSha,
  }) async {
    final packageName = import_.path.substring(4); // Remove 'pub:' prefix
    final version = lockVersion ?? import_.version ?? 'latest';

    // Check pub cache first
    final pubCachePath = _getPubCachePath(packageName, version);
    if (pubCachePath != null && fs.directory(pubCachePath).existsSync()) {
      return ResolvedModule(
        import_: import_,
        resolvedPath: pubCachePath,
        resolvedVersion: version,
        source: ModuleSource.pubCache,
      );
    }

    // Need to fetch
    return fetch(import_);
  }

  @override
  Future<ResolvedModule?> fetch(ModuleImport import_) async {
    final packageName = import_.path.substring(4);
    final version = import_.version ?? 'latest';

    // Use dart pub to get the package
    try {
      // Create a temporary pubspec to fetch the package
      final tempDir = fs.systemTempDirectory.createTempSync('gengen_mod_');

      try {
        final pubspec = '''
name: gengen_module_fetch
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  $packageName: ${version == 'latest' ? 'any' : version}
''';

        fs.file(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync(pubspec);

        final result = await io.Process.run(
          'dart',
          ['pub', 'get'],
          workingDirectory: tempDir.path,
        );

        if (result.exitCode != 0) {
          return null;
        }

        // Find the resolved version in pub cache
        final pubCachePath = _getPubCachePath(packageName, null);
        if (pubCachePath != null) {
          // Get actual resolved version from pubspec.lock
          final actualVersion = _getResolvedVersion(tempDir.path, packageName);

          return ResolvedModule(
            import_: import_,
            resolvedPath: pubCachePath,
            resolvedVersion: actualVersion ?? version,
            source: ModuleSource.pubCache,
          );
        }

        return null;
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<String>> listVersions(ModuleImport import_) async {
    // Would need to query pub.dev API
    // For now, return empty - user should specify version
    return [];
  }

  String? _getPubCachePath(String packageName, String? version) {
    // Check common pub cache locations
    final home = io.Platform.environment['HOME'] ??
        io.Platform.environment['USERPROFILE'] ??
        '';

    final pubCacheLocations = [
      p.join(home, '.pub-cache', 'hosted', 'pub.dev', packageName),
      p.join(home, '.pub-cache', 'hosted', 'pub.dartlang.org', packageName),
    ];

    for (final basePath in pubCacheLocations) {
      if (version != null) {
        final versionedPath = '$basePath-$version';
        if (fs.directory(versionedPath).existsSync()) {
          return versionedPath;
        }
      } else {
        // Find any version
        final parent = fs.directory(p.dirname(basePath));
        if (parent.existsSync()) {
          for (final entity in parent.listSync()) {
            if (entity is Directory &&
                p.basename(entity.path).startsWith('$packageName-')) {
              return entity.path;
            }
          }
        }
      }
    }

    return null;
  }

  String? _getResolvedVersion(String tempDir, String packageName) {
    final lockFile = fs.file(p.join(tempDir, 'pubspec.lock'));
    if (!lockFile.existsSync()) return null;

    final content = lockFile.readAsStringSync();
    final match = RegExp('$packageName:\\s+.*?version:\\s+"([^"]+)"', dotAll: true)
        .firstMatch(content);

    return match?.group(1);
  }
}
