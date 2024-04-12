import 'dart:async';
import 'dart:io';

import 'package:gengen/layout.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/path.dart';
import 'package:gengen/reader.dart';
import 'package:gengen/theme.dart';
import 'package:path/path.dart';
import 'package:rxdart/rxdart.dart';

class Site extends Path {
  late Reader _reader;
  late Set<String> include;
  late Set<String> exclude;
  late Map<String, Layout> layouts;

  final List<Base> _posts = [];
  final List<Base> _pages = [];
  final List<Base> _static = [];

  static Site? _instance;

  Site.__internal({Map<String, dynamic> overrides = const {}}) {
    super.configuration.read(overrides);
    reset();
    theme = Theme.load(
      config.get<String>("theme")!,
      themePath: themesDir,
      config: super.configuration,
    );

    while (!theme.loaded) {
      sleep(const Duration(milliseconds: 10));
    }
    _reader = Reader();
    include = Set.from(config.get<List<String>>("include") ?? []);
    exclude = Set.from(config.get<List<String>>("exclude") ?? []);
  }

  static void init({
    Map<String, dynamic> overrides = const <String, dynamic>{},
  }) {
    Site.__internal(overrides: overrides);
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

  set posts(List<Base> posts) {
    _posts.clear();
    _posts.addAll(posts);
  }

  Site(super.configuration) {
    reset();

    theme = Theme.load(
      config.get<String>("theme")!,
      themePath: themesDir,
      config: super.configuration,
    );

    while (!theme.loaded) {
      sleep(const Duration(milliseconds: 10));
    }
    _reader = Reader();
    include = Set.from(config.get<List<String>>("include") ?? []);
    exclude = Set.from(config.get<List<String>>("exclude") ?? []);
  }

  Reader get reader => _reader;

  void reset() {
    if (destination.existsSync()) {
      destination.deleteSync(recursive: true);
    }
  }

  void process() {
    _reader.read();
    write();
  }

  Directory get destination => Directory(config.destination);

  String workingDir() {
    String workDir = config.source;
    if (isRelative(workDir)) return joinAll([current, workDir]);

    return workDir;
  }

  void write() {
    for (var element in [
      ...staticFiles,
      ...posts,
      ...pages,
    ]) {
      element.write();
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

  Map<String, dynamic> get data => {
        'site': {
          ...config.all,
          'pages': pages.map((e) => e.data['page']).toList(),
          'posts': posts.map((e) => e.data['page']).toList(),
        },
        'theme': {
          'root': theme.root,
        },
      };
}
