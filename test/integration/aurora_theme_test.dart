import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:gengen/site.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Aurora theme integration', () {
    setUpAll(() {
      final getIt = GetIt.instance;
      if (!getIt.isRegistered<FileSystem>()) {
        getIt.registerSingleton<FileSystem>(const LocalFileSystem());
      }
    });

    tearDown(() async {
      Site.resetInstance();
    });

    test('build renders hero, navigation, and media embeds', () async {
      Site.init(overrides: {'source': 'examples/base', 'parallel': false});

      await site.process();

      final outputDir = site.destination.path;

      final indexFile = io.File(p.join(outputDir, 'index.html'));
      expect(
        indexFile.existsSync(),
        isTrue,
        reason: 'index.html should be generated',
      );
      final indexHtml = await indexFile.readAsString();
      expect(indexHtml, contains('class="aurora-header"'));
      expect(indexHtml, contains('/assets/css/aurora.css'));
      expect(indexHtml, contains('class="aurora-pagination"'));
      expect(indexHtml, contains('data-nav-url="/"'));
      expect(
        indexHtml,
        contains('document.querySelector(\'.aurora-nav__toggle\')'),
      );

      final heroMatch = RegExp(
        r'class="aurora-hero__excerpt">([^<]+)</p>',
      ).firstMatch(indexHtml);
      expect(heroMatch, isNotNull, reason: 'hero excerpt should render text');
      expect(heroMatch![1]!.trim(), isNotEmpty);

      final cardMatch = RegExp(
        r'class="aurora-card__excerpt">([^<]+)</p>',
      ).firstMatch(indexHtml);
      expect(
        cardMatch,
        isNotNull,
        reason: 'article cards should render excerpts',
      );
      expect(cardMatch![1]!.trim(), isNotEmpty);

      expect(indexHtml, isNot(contains('{%- render')));
      expect(indexHtml, isNot(contains('{{ content')));

      final archiveFile = io.File(p.join(outputDir, 'posts', 'index.html'));
      expect(
        archiveFile.existsSync(),
        isTrue,
        reason: 'posts index should build',
      );
      final archiveHtml = await archiveFile.readAsString();
      expect(archiveHtml, contains('aurora-card'));

      final storyFile = io.File(
        p.join(
          outputDir,
          'posts',
          '2023',
          '11',
          '09',
          'society-and-dancehall.html',
        ),
      );
      expect(
        storyFile.existsSync(),
        isTrue,
        reason: 'media-heavy story should build',
      );
      final storyHtml = await storyFile.readAsString();
      expect(storyHtml, contains('aurora-media--youtube'));
      expect(storyHtml, contains('aurora-media--twitter'));
      expect(storyHtml, contains('aurora-media--link'));
      expect(storyHtml, contains('<iframe'));

      final cssFile = io.File(p.join(outputDir, 'assets', 'css', 'aurora.css'));
      expect(
        cssFile.existsSync(),
        isTrue,
        reason: 'Aurora CSS bundle should be emitted',
      );

      final pageTwoFile = io.File(p.join(outputDir, 'page', '2', 'index.html'));
      expect(
        pageTwoFile.existsSync(),
        isTrue,
        reason: 'pagination page 2 should exist',
      );
      final pageTwoHtml = await pageTwoFile.readAsString();
      expect(pageTwoHtml, contains('class="aurora-pagination"'));
      expect(pageTwoHtml, contains('aria-label="Pagination"'));
      expect(
        pageTwoHtml,
        contains('class="aurora-pagination__link is-current">2'),
      );
      expect(pageTwoHtml, contains('/page/3/'));
      expect(pageTwoHtml, isNot(contains('aurora-hero__excerpt')));
    });
  });
}
