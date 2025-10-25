import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:gengen/site.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Docs platform integration', () {
    io.Directory? tempDir;

    setUp(() {
      final getIt = GetIt.instance;
      if (!getIt.isRegistered<FileSystem>()) {
        getIt.registerSingleton<FileSystem>(const LocalFileSystem());
      }

      tempDir = io.Directory.systemTemp.createTempSync('gengen-docs-test');
    });

    tearDown(() {
      Site.resetInstance();

      if (tempDir != null && tempDir!.existsSync()) {
        tempDir!.deleteSync(recursive: true);
      }
    });

    test('example docs site builds and renders navigation', () async {
      final fixtureRoot = io.Directory('test/fixtures/docs_example');
      expect(fixtureRoot.existsSync(), isTrue,
          reason: 'docs example fixture missing');
      for (final entity in fixtureRoot.listSync(recursive: true)) {
        if (entity is! io.File) continue;
        final relative = p.relative(entity.path, from: fixtureRoot.path);
        if (relative == 'public' ||
            relative.startsWith('public${p.separator}')) {
          continue;
        }
        final target = io.File(p.join(tempDir!.path, relative));
        target.createSync(recursive: true);
        target.writeAsBytesSync(entity.readAsBytesSync());
      }

      final configFile = io.File(p.join(tempDir!.path, 'config.yaml'));
      if (configFile.existsSync()) {
        final configContents = configFile.readAsStringSync();
        if (configContents.contains('source: "examples/docs"')) {
          final filteredLines = configContents
              .split('\n')
              .where(
                (line) => !line.trim().startsWith('source: "examples/docs"'),
              )
              .toList();
          configFile.writeAsStringSync(filteredLines.join('\n'));
        }
      }

      Site.resetInstance();
      Site.init(overrides: {
        'source': tempDir!.path,
        'parallel': false,
        'config': ['config.yaml'],
      });

      await site.process();

      final outputDir = site.destination.path;

      final indexFile = io.File(p.join(outputDir, 'index.html'));
      expect(indexFile.existsSync(), isTrue);
      final indexHtml = indexFile.readAsStringSync();
      expect(indexHtml, contains('Docs Starter'));

      final quickStartFile = io.File(
        p.join(outputDir, 'guides', 'quick-start', 'index.html'),
      );
      expect(quickStartFile.existsSync(), isTrue,
          reason: 'quick start guide should be generated');
      final quickStartHtml = quickStartFile.readAsStringSync();

      final configGuideFile = io.File(
        p.join(outputDir, 'reference', 'configuration', 'index.html'),
      );
      expect(configGuideFile.existsSync(), isTrue,
          reason: 'configuration reference should be generated');
      final configGuideHtml = configGuideFile.readAsStringSync();

      expect(quickStartHtml, contains('class="docs-sidebar"'));
      expect(configGuideHtml, contains('class="docs-sidebar"'));

      final cssBundle = io.File(p.join(outputDir, 'assets', 'css', 'main.css'));
      expect(cssBundle.existsSync(), isTrue,
          reason: 'docs CSS bundle should be emitted');
    });

    test('core docs navigation data matches source pages', () {
      final navDataFile = io.File('docs/_data/docs/navigation.yml');
      expect(navDataFile.existsSync(), isTrue,
          reason: 'navigation data file missing');

      final navData = loadYaml(navDataFile.readAsStringSync()) as YamlMap;
      final sections = navData['sidebar']['sections'] as YamlList;
      final permalinkIndex = _collectPermalinkIndex();

      for (final sectionEntry in sections.cast<YamlMap>()) {
        final sectionTitle = sectionEntry['title']?.toString() ?? '';
        final pages = sectionEntry['pages'] as YamlList;

        for (final pageEntry in pages.cast<YamlMap>()) {
          if (pageEntry['external'] == true) {
            continue;
          }

          final url = pageEntry['url']?.toString() ?? '';
          final expectedPath = _resolveDocPath(url, permalinkIndex);

          expect(io.File(expectedPath).existsSync(), isTrue,
              reason: 'Missing source for $url at $expectedPath');

          final frontMatter = _readFrontMatter(expectedPath);
          expect(frontMatter['nav_section'], equals(sectionTitle),
              reason: 'Front matter nav_section mismatch for $expectedPath');

          if (pageEntry.containsKey('order')) {
            expect(frontMatter['nav_order'], equals(pageEntry['order']),
                reason: 'Front matter nav_order mismatch for $expectedPath');
          }
        }
      }
    });
  });
}

Map<String, String> _collectPermalinkIndex() {
  final docsDir = io.Directory('docs');
  final result = <String, String>{};
  if (!docsDir.existsSync()) {
    return result;
  }

  for (final entity in docsDir.listSync(recursive: true)) {
    if (entity is! io.File) continue;
    if (!entity.path.endsWith('.md')) continue;

    final frontMatter = _readFrontMatter(entity.path);
    final permalinkValue = frontMatter['permalink']?.toString();
    final normalizedUrl = (permalinkValue != null && permalinkValue.isNotEmpty)
        ? _normalizeUrl(permalinkValue)
        : _deriveUrlFromPath(entity.path);

    result[normalizedUrl] = entity.path;
  }

  return result;
}

String _resolveDocPath(String url, Map<String, String> permalinkIndex) {
  final normalized = _normalizeUrl(url);
  final resolved = permalinkIndex[normalized];
  if (resolved != null) {
    return resolved;
  }

  return _fallbackDocPath(normalized);
}

String _normalizeUrl(String url) {
  var normalized = url.trim();
  if (normalized.isEmpty) {
    return '/';
  }

  if (!normalized.startsWith('/')) {
    normalized = '/$normalized';
  }

  if (normalized != '/' &&
      !normalized.endsWith('/') &&
      !normalized.contains('.')) {
    normalized = '$normalized/';
  }

  return normalized;
}

String _deriveUrlFromPath(String path) {
  final relative = p.relative(path, from: 'docs');
  final withoutExt = p.withoutExtension(relative);
  final parts = withoutExt.split(p.separator).toList();

  if (parts.isNotEmpty && parts.last == 'index') {
    parts.removeLast();
  }

  final joined = parts.join('/');
  if (joined.isEmpty) {
    return '/';
  }

  return _normalizeUrl('/$joined');
}

String _fallbackDocPath(String normalizedUrl) {
  if (normalizedUrl == '/' || normalizedUrl.isEmpty) {
    return p.join('docs', 'index.md');
  }

  var trimmed = normalizedUrl;
  if (trimmed.startsWith('/')) {
    trimmed = trimmed.substring(1);
  }
  if (trimmed.endsWith('/')) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }

  final segments = trimmed.split('/');
  final candidate = p.joinAll(['docs', ...segments]);
  final markdownPath = '$candidate.md';
  if (io.File(markdownPath).existsSync()) {
    return markdownPath;
  }

  return p.join(candidate, 'index.md');
}

Map<String, dynamic> _readFrontMatter(String path) {
  final file = io.File(path);
  final content = file.readAsStringSync();
  if (!content.startsWith('---')) {
    return {};
  }

  final closingIndex = content.indexOf('\n---', 3);
  if (closingIndex == -1) {
    return {};
  }

  final frontMatterRaw = content.substring(3, closingIndex).trim();
  if (frontMatterRaw.isEmpty) {
    return {};
  }

  final yaml = loadYaml(frontMatterRaw);
  if (yaml is YamlMap) {
    return _convertYamlMap(yaml);
  }

  return {};
}

Map<String, dynamic> _convertYamlMap(YamlMap map) {
  return map.map((key, value) => MapEntry(key.toString(), _convertYamlValue(value)));
}

dynamic _convertYamlValue(dynamic value) {
  if (value is YamlMap) {
    return _convertYamlMap(value);
  }
  if (value is YamlList) {
    return value.map(_convertYamlValue).toList();
  }
  return value;
}
