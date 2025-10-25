import 'package:args/command_runner.dart';
import 'package:gengen/bundle/bundle_data.dart';
import 'package:gengen/commands/abstract_command.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart';
import 'package:path/path.dart';

class New extends Command<void> {
  New() {
    addSubcommand(NewSite());
    addSubcommand(NewTheme());
    addSubcommand(NewPost());
    addSubcommand(NewDocs());
  }

  @override
  String get description => "Create site, theme or post from template";

  @override
  String get name => "new";

  @override
  String get usage => "new <subcommand> [options]";

  @override
  void run() {
    print('You must specify a subcommand: post, site, theme, or docs');
  }
}

class NewDocs extends Command<void> {
  NewDocs() {
    argParser.addOption(
      'dir',
      help: 'Output directory',
      defaultsTo: null,
      abbr: 'd',
    );
  }

  @override
  String get description =>
      'Create a new documentation site using the docs platform theme';

  @override
  String get name => 'docs';

  @override
  void run() {
    final String? directory = argResults?["dir"] as String?;

    if (directory == null) {
      log.severe('Directory must be specified for new docs site');
      return;
    }

    if (!fs.directory(directory).existsSync()) {
      fs.directory(directory).create(recursive: true);
    }

    log.info('Creating new docs site in $directory');
    createFromBundle(directory, 'docs_template');
    log.info('Created new docs site in $directory');
  }
}

class NewSite extends Command<void> {
  NewSite() {
    argParser.addOption(
      "dir",
      help: "Output directory",
      defaultsTo: null,
      abbr: 'd',
    );

    argParser.addOption(
      'theme',
      abbr: 't',
      allowed: _availableThemes,
      defaultsTo: 'default',
      help: 'Apply the named theme to the new site',
    );

    argParser.addOption('basic');
  }

  @override
  String get description => "Create a new site";

  @override
  String get name => "site";

  @override
  void run() {
    final String? directory = argResults?["dir"] as String?;

    if (directory == null) {
      log.severe("Directory must be specified for new site");
      return;
    }
    if (!fs.directory(directory).existsSync()) {
      fs.directory(directory).create(recursive: true);
    }

    log.info("Creating new site in $directory");
    createFromBundle(directory, "site_template");
    final theme = (argResults?['theme'] as String? ?? 'default').trim();
    _applyTheme(directory, theme);
    log.info("Created new site in $directory");
  }
}

class NewTheme extends Command<void> {
  NewTheme() {
    argParser.addOption(
      "directory",
      abbr: 'd',
      help: "Output directory",
      defaultsTo: null,
    );
  }

  @override
  String get description => "Create a new theme";

  @override
  String get name => "theme";

  @override
  void run() {
    final String? directory = argResults?["directory"] as String?;
    createTheme(directory!);
  }

  void createTheme(String directory) {
    createFromBundle(directory, "theme_template");
  }
}

class NewPost extends AbstractCommand {
  NewPost() {
    argParser.addOption(
      "title",
      help: "Title of the new post",
      defaultsTo: null,
    );
    argParser.addFlag(
      'force',
      help: 'allow gengen to overwrite existing files',
      defaultsTo: false,
    );
  }

  @override
  String get description => "Create a new post";

  @override
  String get name => "post";

  bool get allowForce => argResults?['force'] as bool;

  @override
  void start() {
    (String, String) name = processName();
    String postPathWExt = setExtension(
      joinAll([site.postPath, name.$1]),
      ".md",
    );
    final postFile = fs.file(postPathWExt);

    if (postFile.existsSync() && !allowForce) {
      log.severe(
        'file with name already exists. Use the --force flag to overwrite',
      );
      return;
    }

    String frontMatter = generateFrontMatter(name.$2);
    writePostFile(postFile, frontMatter);
  }

  (String, String) processName() {
    String name =
        argResults?["title"] as String? ??
        argResults?.rest.join('') ??
        'My GenGen Post';
    String nameWithoutPath = name;

    if (name.contains(separator)) {
      var parts = split(name);
      nameWithoutPath = parts[parts.length - 1];
      parts[parts.length - 1] = slugify(parts[parts.length - 1]);
      name = joinAll(parts);
    }

    return (name, nameWithoutPath);
  }

  String generateFrontMatter(String name) {
    final now = DateTime.now();
    return '''
---
layout: post
title: $name
date: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}
---

## The start of something cool

A sentence is how it all begins
''';
  }

  void writePostFile(File postFile, String content) {
    try {
      postFile.writeAsStringSync(content);
      log.info("Post written to: ${postFile.path}");
    } on FileSystemException catch (e, s) {
      log.severe("Failed to create posts: ${e.message}", e, s);
    }
  }
}

void createFromBundle(String directory, String bundleName) {
  if (!bundleData.containsKey(bundleName)) {
    throw Exception("Bundle not found: $bundleName");
  }

  final Map<String, List<int>> bundle = bundleData[bundleName]!;

  bundle.forEach((filePath, fileData) {
    final file = fs.file("$directory/$filePath");
    file.createSync(recursive: true);
    file.writeAsBytesSync(fileData);
  });
}

const _availableThemes = ['default', 'aurora'];

void _applyTheme(String siteDirectory, String themeName) {
  final normalized = themeName.toLowerCase();
  final bundleKey = 'theme_$normalized';

  if (!bundleData.containsKey(bundleKey)) {
    log.warning(
      "Theme '$themeName' not found. Skipping theme scaffolding.",
    );
    return;
  }

  final themesDir = join(siteDirectory, '_themes', themeName);
  createFromBundle(themesDir, bundleKey);
  _setThemeInConfig(siteDirectory, normalized);
}

void _setThemeInConfig(String siteDirectory, String themeName) {
  final configFile = fs.file(join(siteDirectory, 'config.yaml'));
  if (!configFile.existsSync()) {
    log.warning('config.yaml not found in $siteDirectory; cannot set theme');
    return;
  }

  final lines = configFile.readAsLinesSync();
  bool updated = false;
  final updatedLines = lines.map((line) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('theme:')) {
      final indentLength = line.length - trimmed.length;
      final indent = indentLength > 0 ? line.substring(0, indentLength) : '';
      updated = true;
      return '${indent}theme: "$themeName"';
    }
    return line;
  }).toList();

  if (!updated) {
    updatedLines.insert(0, 'theme: "$themeName"');
  }

  configFile.writeAsStringSync(updatedLines.join('\n'));
}
