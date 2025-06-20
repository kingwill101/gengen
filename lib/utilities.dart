import 'dart:convert';

import 'package:gengen/content/tokenizer.dart';
import 'package:gengen/fs.dart';
import 'package:gengen/logging.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
// import 'package:toml/toml.dart';
import 'package:yaml/yaml.dart';

String? readFile(String path) {
  var file = fs.file(path);
  if (!file.existsSync()) {
    return null;
  }

  return file.readAsStringSync();
}

String slugify(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

String slugifyList(List<String> items) {
  return items.map((item) => slugify(item)).join('/');
}

Map<String, dynamic> getDirectoryFrontMatter(String path) {
  var index = fs.file(join(path, "_index.md"));
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

dynamic parseYaml(String front) {
  return loadYaml(front);
}

Map<String, dynamic> getFrontMatter(String matter) {
  Map<String, dynamic> frontMatter = <String, dynamic>{};

  if (matter.startsWith("\n")) {
    matter = matter.replaceFirst("\n", "");
  }

  if (matter.isEmpty) return frontMatter;

  try {
    final parsed = parseYaml(matter);
    if (parsed == null) return {};
    frontMatter = jsonDecode(jsonEncode(parsed)) as Map<String, dynamic>;
  } on YamlException {
    return {};
  }

  // if (frontMatter.isEmpty) {
  //   try {
  //     frontMatter = TomlDocument.parse(matter).toMap();
  //   } catch (e) {
  //     return {};
  //   }
  // }

  return frontMatter;
}

String readFileSafe(String fullPath, {String contextMsg = ""}) {
  if (isBinaryFile(fullPath)) {
    return '';
  }

  try {
    return readFile(fullPath) ?? '';
  } catch (e, s) {
    log.severe('Error reading file: $contextMsg', e, s);
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
  final file = fs.file(filePath);
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
  } catch (e, s) {
    // Handle file I/O errors here.
    log.severe('Error reading file: $e', e, s);

    return true; // Assume it's binary if there was an error reading it.
  }
}

bool containsLiquid(String content) {
  final RegExp liquidSyntax = RegExp(r'{[{%][\s\S]*?[%}]}');
  return liquidSyntax.hasMatch(content);
}

bool containsMarkdown(String content) {
  RegExp markdownSyntax = RegExp(r'\[.*\]\(.*\)|#+ .+');

  return markdownSyntax.hasMatch(content);
}

String normalize(String title) {
  return slugify(title);
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

DateTime parseDate(String dateString,
    {String? format = "yyyy-MM-dd HH:mm:ss"}) {
  DateFormat dateFormat = DateFormat(format);

  try {
    return dateFormat.parseLoose(dateString);
  } catch (e) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }
}

Map<String, dynamic> deepMerge(
    Map<String, dynamic> m1, Map<String, dynamic> m2) {
  var result = {...m1};
  for (var key in m2.keys) {
    var v2 = m2[key];
    var v1 = result[key];
    if (v1 is Map<String, dynamic> && v2 is Map<String, dynamic>) {
      result[key] = deepMerge(v1, v2);
    } else {
      result[key] = v2;
    }
  }
  return result;
}
