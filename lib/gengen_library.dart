/// # GenGen Static Site Generator Library
///
/// The main GenGen class that provides a clean, simple API for using GenGen
/// as a library rather than a CLI tool.
library;

import 'dart:async';
import 'package:file/local.dart';
import 'package:gengen/configuration.dart';
import 'package:gengen/exceptions.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/site.dart';
import 'package:get_it/get_it.dart';

/// A simple, fluent API for generating static sites with GenGen.
///
/// Inspired by StaticShock and Jaspr, GenGen provides a clean, chainable API
/// for building static websites programmatically.
///
/// ## Basic Usage
///
/// ```dart
/// import 'package:gengen/gengen.dart';
///
/// void main() async {
///   final generator = GenGen()
///     ..source('./content')
///     ..destination('./build')
///     ..title('My Site');
///
///   await generator.build();
/// }
/// ```
///
/// ## With Plugins
///
/// ```dart
/// final generator = GenGen()
///   ..source('./content')
///   ..destination('./build')
///   ..title('My Blog')
///   ..plugin(MarkdownPlugin())
///   ..plugin(SassPlugin())
///   ..plugin(PaginationPlugin());
///
/// await generator.build();
/// ```
///
/// ## Development Server
///
/// ```dart
/// await generator.serve(port: 4000, watch: true);
/// ```
///
/// ## Configuration
///
/// All Jekyll-compatible configuration options are supported:
///
/// ```dart
/// final generator = GenGen()
///   ..source('./content')
///   ..destination('./build')
///   ..title('My Blog')
///   ..description('A blog about Dart')
///   ..url('https://myblog.com')
///   ..baseurl('/blog')
///   ..config({
///     'pagination': {
///       'enabled': true,
///       'items_per_page': 10,
///     },
///     'markdown': {
///       'auto_ids': true,
///     }
///   });
/// ```
class GenGen {
  final Map<String, dynamic> _configOverrides = <String, dynamic>{};
  final List<BasePlugin> _plugins = [];
  Configuration? _configuration;
  Site? _site;
  bool _isDisposed = false;

  /// Creates a new GenGen instance with sensible defaults.
  GenGen() {
    // Initialize dependencies if not already registered
    _initializeDependencies();

    // Set library-specific defaults that differ from Configuration defaults
    _configOverrides.addAll({'destination': './build'});
  }

  /// Initialize required dependencies in the DI container.
  void _initializeDependencies() {
    // Register FileSystem if not already registered
    if (!GetIt.instance.isRegistered<FileSystem>()) {
      GetIt.instance.registerLazySingleton<FileSystem>(() => LocalFileSystem());
    }

    // Initialize logging
    initLog();
  }

  /// Sets the source directory containing your site content.
  ///
  /// Example:
  /// ```dart
  /// generator.source('./content');
  /// ```
  GenGen source(String sourcePath) {
    _configOverrides['source'] = sourcePath;
    return this;
  }

  /// Sets the destination directory for the generated site.
  ///
  /// Example:
  /// ```dart
  /// generator.destination('./build');
  /// ```
  GenGen destination(String destPath) {
    _configOverrides['destination'] = destPath;
    return this;
  }

  /// Sets the site title.
  GenGen title(String title) {
    _configOverrides['title'] = title;
    return this;
  }

  /// Sets the site description.
  GenGen description(String description) {
    _configOverrides['description'] = description;
    return this;
  }

  /// Sets the site URL.
  GenGen url(String url) {
    _configOverrides['url'] = url;
    return this;
  }

  /// Sets the base URL for the site.
  GenGen baseurl(String baseurl) {
    _configOverrides['baseurl'] = baseurl;
    return this;
  }

  /// Sets the permalink structure for posts.
  ///
  /// Example:
  /// ```dart
  /// generator.permalink('/blog/:year/:month/:day/:title/');
  /// ```
  GenGen permalink(String permalink) {
    _configOverrides['permalink'] = permalink;
    return this;
  }

  /// Adds custom configuration options.
  ///
  /// Example:
  /// ```dart
  /// generator.config({
  ///   'pagination': {
  ///     'enabled': true,
  ///     'items_per_page': 10,
  ///   },
  /// });
  /// ```
  GenGen config(Map<String, dynamic> config) {
    _configOverrides.addAll(config);
    return this;
  }

  /// Adds a plugin to extend GenGen's functionality.
  ///
  /// Example:
  /// ```dart
  /// generator
  ///   ..plugin(MarkdownPlugin())
  ///   ..plugin(SassPlugin())
  ///   ..plugin(PaginationPlugin());
  /// ```
  GenGen plugin(BasePlugin plugin) {
    _plugins.add(plugin);
    return this;
  }

  /// Adds multiple plugins at once.
  GenGen plugins(List<BasePlugin> plugins) {
    _plugins.addAll(plugins);
    return this;
  }

  /// Excludes files and directories from processing.
  ///
  /// Example:
  /// ```dart
  /// generator.exclude(['README.md', 'node_modules', '.git']);
  /// ```
  GenGen exclude(List<String> patterns) {
    final currentExcludes = _configOverrides['exclude'] as List<String>? ?? [];
    _configOverrides['exclude'] = [...currentExcludes, ...patterns];
    return this;
  }

  /// Includes files that would normally be excluded.
  ///
  /// Example:
  /// ```dart
  /// generator.include(['.htaccess', '.well-known']);
  /// ```
  GenGen include(List<String> patterns) {
    _configOverrides['include'] = patterns;
    return this;
  }

  /// Builds the static site.
  ///
  /// Returns a map with build statistics and information.
  ///
  /// Example:
  /// ```dart
  /// final result = await generator.build();
  /// print('Built ${result['pages_count']} pages');
  /// ```
  Future<Map<String, dynamic>> build() async {
    if (_isDisposed) {
      throw GenGenException('GenGen instance has been disposed');
    }

    try {
      await _ensureInitialized();

      await _site!.process();

      return await _getSiteStats();
    } catch (e, stackTrace) {
      throw SiteBuildException('Failed to build site: $e', e, stackTrace);
    }
  }

  /// Starts a development server with optional file watching.
  ///
  /// Example:
  /// ```dart
  /// await generator.serve(
  ///   port: 4000,
  ///   host: 'localhost',
  ///   watch: true,
  ///   openBrowser: true,
  /// );
  /// ```
  Future<void> serve({
    int port = 4000,
    String host = 'localhost',
    bool watch = false,
    bool openBrowser = false,
  }) async {
    if (_isDisposed) {
      throw GenGenException('GenGen instance has been disposed');
    }

    // For now, just build the site
    // TODO: Implement proper development server
    await build();
    print('Site built. Development server not yet implemented.');
  }

  /// Cleans the destination directory.
  ///
  /// Example:
  /// ```dart
  /// await generator.clean();
  /// ```
  Future<void> clean() async {
    await _ensureInitialized();
    final destPath = _configuration!.destination;
    final destDir = fs.directory(destPath);
    if (await destDir.exists()) {
      await destDir.delete(recursive: true);
    }
  }

  /// Gets site information and statistics.
  ///
  /// Returns a map containing:
  /// - `title`: Site title
  /// - `description`: Site description
  /// - `posts_count`: Number of posts
  /// - `pages_count`: Number of pages
  /// - `source`: Source directory
  /// - `destination`: Destination directory
  ///
  /// Example:
  /// ```dart
  /// final info = await generator.getSiteInfo();
  /// print('Site: ${info['title']}');
  /// print('Posts: ${info['posts_count']}');
  /// ```
  Future<Map<String, dynamic>> getSiteInfo() async {
    await _ensureInitialized();
    return _getSiteStats();
  }

  /// Disposes of resources and cleans up.
  ///
  /// Call this when you're done with the GenGen instance.
  void dispose() {
    if (_isDisposed) return;

    try {
      Site.resetInstance();
      GetIt.instance.reset();
      Configuration.resetConfig();
    } catch (_) {
      // Ignore errors during cleanup
    }

    _configuration = null;
    _site = null;
    _isDisposed = true;
  }

  /// Returns true if the generator has been initialized.
  bool get isInitialized => _site != null && !_isDisposed;

  /// Returns the current configuration as a read-only map.
  Map<String, dynamic> get configuration {
    if (_configuration == null) {
      return Map.unmodifiable(_configOverrides);
    }
    return Map.unmodifiable(_configuration!.all);
  }

  /// Returns the site instance for advanced usage.
  ///
  /// Throws [GenGenException] if not initialized.
  Site get site {
    if (_site == null || _isDisposed) {
      throw GenGenException('GenGen must be initialized before accessing site');
    }
    return _site!;
  }

  /// Internal method to ensure the site is initialized.
  Future<void> _ensureInitialized() async {
    if (_site != null && !_isDisposed) return;

    if (_isDisposed) {
      throw GenGenException('GenGen instance has been disposed');
    }

    try {
      // Initialize configuration using the Configuration class
      _configuration = Configuration();
      _configuration!.read(_configOverrides);

      // Initialize the site with the properly configured Configuration instance
      Site.init(overrides: _configOverrides);
      _site = Site.instance;

      // Add custom plugins
      for (final plugin in _plugins) {
        _site!.plugins.add(plugin);
      }
    } catch (e, stackTrace) {
      throw SiteInitializationException(
        'Failed to initialize GenGen: $e',
        e,
        stackTrace,
      );
    }
  }

  /// Gets site statistics and information.
  Future<Map<String, dynamic>> _getSiteStats() async {
    if (_site == null || _configuration == null) {
      throw GenGenException('Site not initialized');
    }

    return {
      'title': _configuration!.get<String>('title') ?? 'My Site',
      'description':
          _configuration!.get<String>('description') ??
          'A site built with GenGen',
      'url': _configuration!.get<String>('url') ?? '',
      'baseurl': _configuration!.get<String>('baseurl') ?? '',
      'posts_count': _site!.posts.length,
      'pages_count': _site!.pages.length,
      'source': _configuration!.source,
      'destination': _configuration!.destination,
      'plugins_count': _site!.plugins.length,
    };
  }
}

/// Convenience function to create a new GenGen instance.
///
/// Example:
/// ```dart
/// final generator = gengen()
///   ..source('./content')
///   ..destination('./build')
///   ..title('My Site');
/// ```
GenGen gengen() => GenGen();
