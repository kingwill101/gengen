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
  }

  @override
  String get description => "Create site, theme or post from template";

  @override
  String get name => "new";

  @override
  String get usage => "new <subcommand> [options]";

  @override
  void run() {
    print('You must specify a subcommand: post, site, or theme');
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
    log.info("Created new site in $directory");
  }
}

class NewTheme extends Command<void> {
  NewTheme() {
    argParser.addOption(
      "directory",
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
    argParser.addOption("title",
        help: "Title of the new post", defaultsTo: null);
    argParser.addFlag('force',
        help: 'allow gengen to overwrite existing files', defaultsTo: false);
  }

  @override
  String get description => "Create a new post";

  @override
  String get name => "post";

  bool get allowForce => argResults?['force'] as bool;

  @override
  void start() {
    (String, String) name = processName();
    String postPathWExt =
        setExtension(joinAll([Site.instance.postPath, name.$1]), ".md");
    final postFile = fs.file(postPathWExt);

    if (postFile.existsSync() && !allowForce) {
      log.severe(
          'file with name already exists. Use the --force flag to overwrite');
      return;
    }

    String frontMatter = generateFrontMatter(name.$2);
    writePostFile(postFile, frontMatter);
  }

  (String, String) processName() {
    String name = argResults?["title"] as String? ??
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
    } on FileSystemException catch (e) {
      log.severe("Failed to create posts: ${e.message}");
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
