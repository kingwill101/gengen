import 'dart:async';
import 'package:collection/collection.dart';

import 'package:gengen/configuration.dart';
import 'package:gengen/drops/collection_drop.dart';
import 'package:gengen/drops/static_file_drop.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/hook.dart';
import 'package:gengen/layout.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/models/collection.dart';
import 'package:gengen/performance/benchmark.dart';
import 'package:gengen/plugin/builtin/pagination.dart';
import 'package:gengen/path.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_manager.dart';
import 'package:gengen/reader.dart';
import 'package:gengen/theme.dart';
import 'package:path/path.dart';
import 'package:rxdart/rxdart.dart';

Site get site => Site.instance;

class Site with PathMixin {
  late Reader _reader;
  late Set<String> include;
  late Set<String> exclude;
  late Map<String, Layout> layouts;
  final List<Base> _posts = [];
  final List<Base> _pages = [];
  final List<Base> _static = [];
  final Map<String, ContentCollection> _collections = {};
  List<BasePlugin> _plugins = [];

  static Site? _instance;

  Site.__internal({Map<String, dynamic> overrides = const {}}) {
    config.read(overrides);

    // Initialize plugins based on configuration
    _plugins = PluginManager.getEnabledPlugins(config.all);

    theme = Theme.load(
      config.get<String>("theme")!,
      themePath: themesDir,
      config: config,
    );

    _reader = Reader();
    include = Set.from(config.get("include") as List? ?? []);
    exclude = Set.from(config.get("exclude") as List? ?? []);
  }

  static void init({
    Map<String, dynamic> overrides = const <String, dynamic>{},
  }) {
    _instance = Site.__internal(overrides: overrides);
  }

  static Site get instance {
    _instance ??= Site.__internal();
    return _instance!;
  }

  static void resetInstance() {
    _instance = null;
    Configuration.resetConfig();
  }

  final StreamController<String> _fileChangeController =
      StreamController.broadcast();

  Stream<String> get fileChangeStream =>
      _fileChangeController.stream.debounceTime(Duration(milliseconds: 500));

  void dispose() {
    _fileChangeController.close();
  }

  void notifyFileChange(String filePath) {
    _fileChangeController.sink.add(filePath);
  }

  late Theme theme;

  List<Base> get pages => _pages;

  List<Base> get posts {
    // Sort posts by date (newest first) whenever accessed
    _posts.sort((a, b) => b.date.compareTo(a.date));
    return _posts;
  }

  List<Base> get staticFiles => _static;

  Map<String, ContentCollection> get collections => _collections;

  Iterable<Base> get collectionDocuments =>
      _collections.values.expand((collection) => collection.docs);

  Iterable<Base> get collectionFiles =>
      _collections.values.expand((collection) => collection.files);

  Iterable<Base> get collectionItems =>
      collectionDocuments.followedBy(collectionFiles);

  Iterable<Base> get collectionOutputItems => _collections.values
      .where((collection) => collection.output)
      .expand((collection) => collection.itemsToWrite);

  List<BasePlugin> get plugins => _plugins;

  set posts(List<Base> posts) {
    _posts.clear();
    _posts.addAll(posts);
  }

  void setCollections(Map<String, ContentCollection> collections) {
    _collections
      ..clear()
      ..addAll(collections);
  }

  Reader get reader => _reader;

  Future<void> reset() async {
    if (destination.existsSync()) {
      await destination.delete(recursive: true);
    }
  }

  Future<void> read() async {
    await _reader.read();
  }

  Future<void> process() async {
    // Clean destination if configured to do so
    if (config.get<bool>('clean', defaultValue: true)!) {
      await Benchmark.timeAsync('clean', () async {
        if (await destination.exists()) {
          await destination.delete(recursive: true);
        }
      });
    }

    // Reset collections for idempotency
    layouts = {};
    _posts.clear();
    _pages.clear();
    _static.clear();
    _collections.clear();

    await Benchmark.timeAsync(
      'hook_after_init',
      () => runHook(HookEvent.afterInit),
    );
    await Benchmark.timeAsync(
      'hook_before_read',
      () => runHook(HookEvent.beforeRead),
    );
    await Benchmark.timeAsync('read', () => read());
    await Benchmark.timeAsync(
      'hook_after_read',
      () => runHook(HookEvent.afterRead),
    );
    await Benchmark.timeAsync(
      'hook_before_generate',
      () => runHook(HookEvent.beforeGenerate),
    );
    await Benchmark.timeAsync('generators', () => runGenerators());
    await Benchmark.timeAsync(
      'hook_after_generate',
      () => runHook(HookEvent.afterGenerate),
    );
    await Benchmark.timeAsync(
      'hook_before_render',
      () => runHook(HookEvent.beforeRender),
    );
    await Benchmark.timeAsync('render', () => render());
    await Benchmark.timeAsync(
      'hook_after_render',
      () => runHook(HookEvent.afterRender),
    );
    await Benchmark.timeAsync(
      'hook_before_write',
      () => runHook(HookEvent.beforeWrite),
    );
    await Benchmark.timeAsync('write', () => write());
    await Benchmark.timeAsync(
      'hook_after_write',
      () => runHook(HookEvent.afterWrite),
    );
  }

  Future<Map<String, Object>> dump() async {
    await _reader.read();

    final Map<String, Object> siteDump = {
      "source": config.source,
      "destination": config.destination,
      "workingDir": workingDir(),
      "include": include.toList(),
      "exclude": exclude.toList(),
      "posts": _posts.map((e) => e.toJson()).toList(),
      "pages": _pages.map((e) => e.toJson()).toList(),
      "plugins": _plugins.map((e) => e.metadata.toJson()).toList(),
      "staticFiles": _static,
      "layouts": layouts,
      "config": config.all,
      "site_dir": toJson(),
      "theme_dir": theme.toJson(),
    };

    return siteDump;
  }

  Directory get destination => fs.directory(config.destination);

  String workingDir() {
    String workDir = config.source;
    if (isRelative(workDir)) return joinAll([current, workDir]);

    return workDir;
  }

  Future<void> write() async {
    final items = [
      ...staticFiles,
      ...posts.where((post) => post.shouldWrite),
      ...pages,
      ...collectionOutputItems.where((item) => item.shouldWrite),
    ];

    Benchmark.increment('files_processed', items.length);
    log.info('writing ${items.length} items');

    // Always use simple sequential writing (it's already fast)
    for (final page in items) {
      await page.write();
    }

    log.info('write done');
  }

  Future<void> render() async {
    final items = [
      ...staticFiles,
      ...posts,
      ...collectionDocuments,
      ...pages,
    ];

    for (var item in items) {
      await item.render();
    }
  }

  Future<void> watch() async {
    for (var value in [...staticFiles, ...posts, ...pages, ...collectionItems]) {
      value.watch();
    }

    for (var value in layouts.values) {
      value.watch();
    }
  }

  String inSourceDir(String path) => join(config.source, path);

  String relativeToSource(String path) => relative(path, from: config.source);

  String relativeToDestination(String path) =>
      relative(path, from: destination.path);

  @override
  String get root => workingDir();

  Map<String, dynamic> get data =>
      config.get<Map<String, dynamic>>("data", defaultValue: {})!;

  Map<String, dynamic> get map {
    posts.sort((a, b) => b.date.compareTo(a.date));
    final includeUnpublished =
        config.get<bool>('unpublished', defaultValue: false) ?? false;
    final filteredPosts = posts
        .where((post) =>
            !post.isIndex && (includeUnpublished || post.isPublished))
        .toList();

    // Get pagination data from PaginationPlugin
    final paginationPlugin = _plugins.whereType<PaginationPlugin>().firstOrNull;
    final paginationDrop = paginationPlugin?.paginationData;
    final paginationData = paginationDrop != null
        ? Map<String, dynamic>.from(paginationDrop.attrs)
        : const <String, dynamic>{};

    final collectionAliases = <String, List<dynamic>>{};
    final collectionList = _collections.values
        .map((collection) => CollectionDrop(collection))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    for (final entry in _collections.entries) {
      final items = entry.value.docs.map((e) => e.to_liquid).toList();
      collectionAliases[entry.key] = items;
    }

    final documents = [
      ...filteredPosts.map((e) => e.to_liquid),
      ..._collections.values.expand((c) => c.docs).map((e) => e.to_liquid),
      ..._collections.values
          .expand((c) => c.files)
          .map((e) => StaticFileDrop(e)),
    ];

    return {
      ...config.all,
      ...collectionAliases,
      'feed_meta': '',
      'pages': pages.map((e) => e.to_liquid).toList(),
      'posts': filteredPosts.map((e) => e.to_liquid).toList(),
      'collections': collectionList,
      'documents': documents,
      'paginate': paginationData,
      'pagination': paginationData,
      'time': DateTime.now(),
      'theme': {'root': theme.root},
    };
  }

  Future<void> runHook(HookEvent event) async {
    for (var plugin in _plugins) {
      switch (event) {
        case HookEvent.afterInit:
          await plugin.afterInit();
          break;
        case HookEvent.beforeRead:
          await plugin.beforeRead();
          break;
        case HookEvent.afterRead:
          await plugin.afterRead();
          break;
        case HookEvent.beforeConvert:
          await plugin.beforeConvert();
          break;
        case HookEvent.afterConvert:
          await plugin.afterConvert();
          break;
        case HookEvent.beforeGenerate:
          await plugin.beforeGenerate();
          break;
        case HookEvent.afterGenerate:
          await plugin.afterGenerate();
          break;
        case HookEvent.beforeRender:
          await plugin.beforeRender();
          break;
        case HookEvent.afterRender:
          await plugin.afterRender();
          break;
        case HookEvent.beforeWrite:
          await plugin.beforeWrite();
          break;
        case HookEvent.afterWrite:
          await plugin.afterWrite();
          break;
        case HookEvent.afterReset:
        case HookEvent.convert:
          // TODO: Handle this case.
          throw UnimplementedError();
      }
    }
  }

  Future<void> runGenerators() async {
    for (var plugin in _plugins) {
      await plugin.generate();
    }
  }
}
