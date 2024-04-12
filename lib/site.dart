import 'dart:io';

import 'package:gengen/layout.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/path.dart';
import 'package:gengen/reader.dart';
import 'package:gengen/theme.dart';
import 'package:path/path.dart';

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
      config: configuration,
    );

    while (!theme.loaded) {
      sleep(const Duration(milliseconds: 10));
    }
    _reader = Reader(this);
    include = Set.from(config.get<List<String>>("include") ?? []);
    exclude = Set.from(config.get<List<String>>("exclude") ?? []);
  }

  Reader get reader => _reader;

  void reset() {
    var dir = Directory(destination);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }

  void process() {
    _reader.read();
    write();
  }

  String get destination => config.destination;

  String workingDir() {
    String wkdir = config.source;

    if (isRelative(wkdir)) {
      wkdir = joinAll([current, wkdir]);
    }

    return wkdir;
  }

  void write() {
    Directory dst = Directory(config.destination);
    var content = List<Base>.from([...posts, ...pages, ...staticFiles]);
    for (var element in content) {
      element.write(dst);
    }
  }

  String inSourceDir(String path) => join(config.source, path);

  String relativeToSource(String path) => relative(path, from: config.source);

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
