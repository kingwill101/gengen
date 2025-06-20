import 'dart:async';

import 'package:gengen/fs.dart';
import 'package:gengen/hook.dart';
import 'package:gengen/layout.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/path.dart';
import 'package:gengen/plugin/builtin/liquid.dart';
import 'package:gengen/plugin/builtin/markdown.dart';
import 'package:gengen/plugin/builtin/sass.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/reader.dart';
import 'package:gengen/theme.dart';
import 'package:path/path.dart';
import 'package:rxdart/rxdart.dart';
// import 'package:sentry/sentry.dart';

Site get site => Site.instance;

class Site with PathMixin {
  late Reader _reader;
  late Set<String> include;
  late Set<String> exclude;
  late Map<String, Layout> layouts;
  final List<Base> _posts = [];
  final List<Base> _pages = [];
  final List<Base> _static = [];
  final List<BasePlugin> _plugins = [
    MarkdownPlugin(),
    LiquidPlugin(),
    SassPlugin()
  ];

  static Site? _instance;

  Site.__internal({Map<String, dynamic> overrides = const {}}) {
    config.read(overrides);
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
  }

  final StreamController<String> _fileChangeController =
      StreamController.broadcast();

  Stream<String> get fileChangeStream =>
      _fileChangeController.stream.debounceTime(
        Duration(
          milliseconds: 500,
        ),
      );

  void dispose() {
    _fileChangeController.close();
  }

  void notifyFileChange(String filePath) {
    _fileChangeController.sink.add(filePath);
  }

  late Theme theme;

  List<Base> get pages => _pages;

  List<Base> get posts => _posts;

  List<Base> get staticFiles => _static;

  List<BasePlugin> get plugins => _plugins;

  set posts(List<Base> posts) {
    _posts.clear();
    _posts.addAll(posts);
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
    if (config.get<bool>('clean', defaultValue: false)!) {
      if (await destination.exists()) {
        await destination.delete(recursive: true);
      }
    }

    // Reset collections for idempotency
    layouts = {};
    _posts.clear();
    _pages.clear();
    _static.clear();

    await runHook(HookEvent.afterInit);
    await runHook(HookEvent.beforeRead);
    await read();
    await runHook(HookEvent.afterRead);
    await runHook(HookEvent.beforeGenerate);
    await runGenerators();
    await runHook(HookEvent.afterGenerate);
    await runHook(HookEvent.beforeRender);
    await render();
    await runHook(HookEvent.afterRender);
    await runHook(HookEvent.beforeWrite);
    await write();
    await runHook(HookEvent.afterWrite);
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
      ...posts,
      ...pages,
    ];

    log.info('writing ${items.length} items');
    await Future.wait(items.map((page) async {
      await page.write();
    }));
    log.info('write done');
  }

  Future<void> render() async {
    await Future.wait([
      ...staticFiles,
      ...posts,
      ...pages,
    ].map((page) async {
      await page.render();
    }));
  }

  Future<void> watch() async {
    for (var value in [
      ...staticFiles,
      ...posts,
      ...pages,
    ]) {
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

    return {
      ...config.all,
      'feed_meta': '',
      'pages': pages.map((e) => e.to_liquid).toList(),
      'posts':
          posts.where((post) => !post.isIndex).map((e) => e.to_liquid).toList(),
      'theme': {
        'root': theme.root,
      },
    };
  }

  Future<void> runHook(HookEvent event) async {
    for (var plugin in _plugins) {
      switch (event) {
        case HookEvent.afterInit:
          plugin.afterInit();
          break;
        case HookEvent.beforeRead:
          plugin.beforeRead();
          break;
        case HookEvent.afterRead:
          plugin.afterRead();
          break;
        case HookEvent.beforeConvert:
          plugin.beforeConvert();
          break;
        case HookEvent.afterConvert:
          plugin.afterConvert();
          break;
        case HookEvent.beforeGenerate:
          plugin.beforeGenerate();
          break;
        case HookEvent.afterGenerate:
          plugin.afterGenerate();
          break;
        case HookEvent.beforeRender:
          plugin.beforeRender();
          break;
        case HookEvent.afterRender:
          plugin.afterRender();
          break;
        case HookEvent.beforeWrite:
          plugin.beforeWrite();
          break;
        case HookEvent.afterWrite:
          plugin.afterWrite();
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
