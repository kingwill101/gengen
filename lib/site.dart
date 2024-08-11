import 'dart:async';
import 'dart:io';

import 'package:gengen/layout.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/path.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:gengen/reader.dart';
import 'package:gengen/theme.dart';
import 'package:path/path.dart';
import 'package:rxdart/rxdart.dart';

final site = Site.instance;

class Site with PathMixin {
  late Reader _reader;
  late Set<String> include;
  late Set<String> exclude;
  late Map<String, Layout> layouts;
  final List<Base> _posts = [];
  final List<Base> _pages = [];
  final List<Base> _static = [];
  final List<PluginMetadata> _plugins = [];

  static Site? _instance;

  Site.__internal({Map<String, dynamic> overrides = const {}}) {
    config.read(overrides);
    reset();
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

// Create a broadcast StreamController
  final StreamController<String> _fileChangeController =
      StreamController.broadcast();

// Getter for the stream
  Stream<String> get fileChangeStream =>
      _fileChangeController.stream.debounceTime(
        Duration(
          milliseconds: 500,
        ),
      );

  void dispose() {
    _fileChangeController.close();
  }

// Method to add a file change event
  void notifyFileChange(String filePath) {
    _fileChangeController.sink.add(filePath);
  }

  late Theme theme;

  List<Base> get pages => _pages;

  List<Base> get posts => _posts;

  List<Base> get staticFiles => _static;

  List<PluginMetadata> get plugins => _plugins;

  set posts(List<Base> posts) {
    _posts.clear();
    _posts.addAll(posts);
  }

  Reader get reader => _reader;

  void reset() {
    if (destination.existsSync()) {
      destination.deleteSync(recursive: true);
    }
  }

  Future<void> process() async {
    _reader.read();
    await write();
  }

  Future<Map<String, Object>> dump() async {
    _reader.read();

    final Map<String, Object> siteDump = {
      "source": config.source,
      "destination": config.destination,
      "workingDir": workingDir(),
      "include": include.toList(),
      "exclude": exclude.toList(),
      "posts": _posts.map((e) => e.toJson()).toList(),
      "pages": _pages.map((e) => e.toJson()).toList(),
      "plugins": _plugins.map((e) => e.toJson()).toList(),
      "staticFiles": _static,
      "layouts": layouts,
      "config": config.all,
      "site_dir": toJson(),
      "theme_dir": theme.toJson(),
    };

    return siteDump;
  }

  Directory get destination => Directory(config.destination);

  String workingDir() {
    String workDir = config.source;
    if (isRelative(workDir)) return joinAll([current, workDir]);

    return workDir;
  }

  Future<void> write() async {
    for (var element in [
      ...staticFiles,
      ...posts,
      ...pages,
    ]) {
      await element.write();
    }
  }

  void watch() {
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

  Map<String, dynamic> get data {
    posts.sort((a, b) => b.date.compareTo(a.date));

    return {
      'site': {
        ...config.all,
        'pages': pages.map((e) => e.to_liquid).toList(),
        'posts': posts.map((e) => e.to_liquid).toList(),
        'theme': {
          'root': theme.root,
        },
      },
    };
  }
}
