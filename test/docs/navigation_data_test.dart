import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Docs navigation data schema', () {
    late YamlMap data;

    setUpAll(() {
      final file = File('docs/_data/docs/navigation.yml');
      expect(file.existsSync(), isTrue, reason: 'navigation.yml must exist');
      data = loadYaml(file.readAsStringSync()) as YamlMap;
    });

    test('sidebar sections contain required fields', () {
      final sidebar = data['sidebar'] as YamlMap?;
      expect(sidebar, isNotNull, reason: 'sidebar key is required');

      final sections = sidebar!['sections'] as YamlList?;
      expect(
        sections,
        isNotNull,
        reason: 'sidebar.sections must be a list of section definitions',
      );
      expect(
        sections,
        isNotEmpty,
        reason: 'sidebar.sections must contain at least one section',
      );

      for (final section in sections!) {
        expect(section, isA<YamlMap>(), reason: 'section must be a map');
        final sectionMap = section as YamlMap;
        expect(
          sectionMap.containsKey('title'),
          isTrue,
          reason: 'each section requires a title',
        );
        expect(
          sectionMap['pages'],
          isA<YamlList>(),
          reason: 'each section must define pages',
        );

        final pages = sectionMap['pages'] as YamlList;
        expect(
          pages,
          isNotEmpty,
          reason: 'section "${sectionMap['title']}" must have pages',
        );

        for (final page in pages) {
          expect(page, isA<YamlMap>(), reason: 'page must be a map');
          final pageMap = page as YamlMap;
          expect(
            pageMap.containsKey('title'),
            isTrue,
            reason: 'each page requires a title',
          );
          expect(
            pageMap.containsKey('url'),
            isTrue,
            reason: 'each page requires a url',
          );
        }
      }
    });

    test('quick nav entries contain title and url', () {
      final quickNav = data['quick_nav'] as YamlList?;
      expect(quickNav, isNotNull, reason: 'quick_nav key must exist');

      for (final entry in quickNav!) {
        expect(entry, isA<YamlMap>(), reason: 'quick nav entries must be maps');
        final entryMap = entry as YamlMap;
        expect(
          entryMap.containsKey('title'),
          isTrue,
          reason: 'quick nav entry requires title',
        );
        expect(
          entryMap.containsKey('url'),
          isTrue,
          reason: 'quick nav entry requires url',
        );
      }
    });

    test('footer nav entries contain title and url', () {
      final footerNav = data['footer_nav'] as YamlList?;
      expect(footerNav, isNotNull, reason: 'footer_nav key must exist');

      for (final entry in footerNav!) {
        expect(
          entry,
          isA<YamlMap>(),
          reason: 'footer nav entries must be maps',
        );
        final entryMap = entry as YamlMap;
        expect(
          entryMap.containsKey('title'),
          isTrue,
          reason: 'footer nav entry requires title',
        );
        expect(
          entryMap.containsKey('url'),
          isTrue,
          reason: 'footer nav entry requires url',
        );
      }
    });
  });
}
