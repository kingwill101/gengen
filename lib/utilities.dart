import 'dart:io';

import 'package:gengen/content/tokenizer.dart';
import 'package:gengen/logging.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:html_unescape/html_unescape.dart';
import 'package:path/path.dart';
import 'package:toml/toml.dart';
import 'package:yaml_magic/yaml_magic.dart';

String? readFile(String path) {
  var file = File(path);
  if (!file.existsSync()) {
    return null;
  }

  return file.readAsStringSync();
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

Map<String, dynamic> getDirectoryFrontMatter(String path) {
  var index = File(join(path, "_index.md"));
  if (!index.existsSync()) {
    return {};
  }
  var content = index.readAsStringSync();
  var markdown = toContent(content);
  var matter = markdown.frontMatter;

  return matter;
}

Map<String, dynamic> walkDirectoriesAndGetFrontMatters(String basePath) {
  var segments = split(basePath);
  var mergedMatter = <String, dynamic>{};

  for (int i = 0; i < segments.length; i++) {
    var currentPath = joinAll(segments.sublist(0, i + 1));
    var matter = getDirectoryFrontMatter(currentPath);
    mergedMatter = {...mergedMatter, ...matter};
  }

  return mergedMatter;
}

String cleanUpContent(String htmlContent) {
  var unescape = HtmlUnescape();

  return unescape.convert(htmlContent).replaceAll('\u00A0', ' ');
}

Map<String, dynamic> parseYaml(String front) {
  return YamlMagic.fromString(content: front, path: '').map;
}

Map<String, dynamic> getFrontMatter(String matter) {
  Map<String, dynamic> frontMatter = <String, dynamic>{};

  frontMatter = parseYaml(matter);

  if (matter.isNotEmpty && frontMatter.isEmpty) {
    try {
      frontMatter = TomlDocument.parse(matter).toMap();
    } catch (e) {
      return {};
    }
  }

  return frontMatter;
}

String readFileSafe(String fullPath, {String contextMsg = ""}) {
  if (isBinaryFile(fullPath)) {
    return '';
  }

  try {
    return readFile(fullPath) ?? '';
  } catch (e) {
    log.severe('Error reading file', e);
    log.info(contextMsg);

    return '';
  }
}

bool hasYamlHeader(String fullPath) {
  if (isBinaryFile(fullPath)) {
    return false;
  }

  var c = toContent(readFileSafe(fullPath));

  if (c.frontMatter.isEmpty) {
    return false;
  }

  return true;
}

bool isBinaryFile(String filePath) {
  final file = File(filePath);
  final maxSize = 1024; // Maximum number of bytes to read for analysis.

  try {
    final bytes = file.readAsBytesSync();
    final length = bytes.length < maxSize ? bytes.length : maxSize;

    for (var i = 0; i < length; i++) {
      if (bytes[i] == 0x00) {
        return true; // Null byte found, indicating binary content.
      }
    }

    return false; // No null byte found, likely a text file.
  } catch (e) {
    // Handle file I/O errors here.
    log.severe('Error reading file: $e', e);

    return true; // Assume it's binary if there was an error reading it.
  }
}

bool containsLiquid(String content) {
  return content.contains("{%") || content.contains("{{");
}

bool containsMarkdown(String content) {
  RegExp markdownSyntax = RegExp(r'\[.*\]\(.*\)|#+ .+');

  return markdownSyntax.hasMatch(content);
}

String normalize(String title) {
  return slugify(title)
      .toLowerCase()
      .replaceAll(' ', '-')
      .replaceAll(RegExp(r'[^\w-]'), '');
}

String extractExcerpt(
  String htmlContent, {
  int maxLength = 200,
  String? keyword,
}) {
  // Parse the HTML content
  dom.Document document = html_parser.parse(htmlContent);

  // Find relevant elements
  List<dom.Element> relevantElements =
      document.querySelectorAll('p, div, article');

  // Extract and clean text
  List<String> allSentences = relevantElements.expand((element) {
    String text = element.text.trim();
    text = text.replaceAll(
      RegExp(r'\s+'),
      ' ',
    ); // Replace multiple whitespaces with a single space

    // Split the text into sentences
    return text.split(RegExp(r'[.!?]\s'));
  }).toList();

  // Combine sentences and ensure they are within the max length
  String excerpt = '';
  for (var sentence in allSentences) {
    if (excerpt.length + sentence.length > maxLength) {
      break;
    }
    excerpt += '$sentence ';
  }

  // Trim to the maximum length if necessary
  if (excerpt.length > maxLength) {
    excerpt = excerpt.substring(0, maxLength);
    // Optionally, trim at the last full word
    int lastSpace = excerpt.lastIndexOf(' ');
    if (lastSpace > 0) {
      excerpt = excerpt.substring(0, lastSpace);
    }
  }

  // If a keyword is provided, prioritize sentences containing the keyword
  if (keyword != null && keyword.isNotEmpty) {
    String? sentenceWithKeyword = allSentences.firstWhere(
      (sentence) => sentence.contains(keyword),
      orElse: () => '',
    );
    excerpt =
        sentenceWithKeyword.length <= maxLength ? sentenceWithKeyword : excerpt;
  }

  return excerpt.trim();
}
