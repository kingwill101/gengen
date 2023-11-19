import 'dart:io';

import 'package:console/console.dart';
import 'package:path/path.dart';
import 'package:toml/toml.dart';
import 'package:yaml/yaml.dart';

import 'package:gengen/generator/generator.dart';
import 'package:gengen/content/content.dart';

Future<bool> isDir(String path) {
  return Directory(path).exists();
}

Future<String?> readFile(String path) async {
  var file = File(path);
  if (!await file.exists()) {
    return null;
  }

  return file.readAsString();
}

String slugify(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'[^\w-]'), '');
}

String slugifyList(List<String> items) {
  return items.map((item) => slugify(item)).join('/');
}

Map<String, dynamic>? getDirectoryFrontMatter(String path) {
  var dir = dirname(path);

  if (Generator.directoryDefaults.containsKey(dir)) {
    return Generator.directoryDefaults[dir];
  }

  Generator.directoryDefaults[dir] = {};

  var index = File(joinAll([dir, "_index.md"]));

  if (!index.existsSync()) {
    return {};
  }

  var content = index.readAsStringSync();

  var markdown = toContent(content);
  if (markdown == null) {
    return {};
  }

  var matter = markdown.frontMatter;
  Generator.directoryDefaults[dir] = matter;

  return matter;
}

YamlMap parseFrontMatter(String front) {
  return loadYaml(front);
}

getFrontMatter(String matter) {
  Map<String, dynamic> frontMatter = <String, dynamic>{};
  try {
    frontMatter = parseFrontMatter(matter).cast<String, dynamic>();
  } catch (exc) {
    try {
      frontMatter = TomlDocument.parse(matter).toMap();
    } catch (e) {
      Console.setTextColor(Color.RED.id, bright: true);
      print("[TOML] Unable to read front matter, giving up");
      Console.setTextColor(Color.WHITE.id, bright: true);
      return {};
    }
  }

  return frontMatter;
}
