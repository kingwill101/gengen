import 'package:file/memory.dart';
import 'package:gengen/entry_filter.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:glob/glob.dart';

void main() {
  group('EntryFilter', () {
    late MemoryFileSystem memoryFileSystem;
    late String projectRoot;
    late String sourcePath;

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      gengen_fs.fs = memoryFileSystem;
      projectRoot = memoryFileSystem.currentDirectory.path;
      sourcePath = p.join(projectRoot, 'source');
      memoryFileSystem.directory(sourcePath).createSync(recursive: true);

      Site.init(
        overrides: {
          'source': sourcePath,
          'destination': p.join(projectRoot, 'public'),
          'exclude': [
            'excluded_dir/**',
            'excluded_file.md',
            '*.txt',
            'notes/**',
            '_drafts/**',
            '*_notes.md',
          ],
          'include': ['notes/important_notes.md'],
        },
      );
    });

    test('glob package should handle basic patterns correctly', () {
      expect(Glob('*.txt').matches('secret.txt'), isTrue);
      expect(Glob('*.txt').matches('secret.md'), isFalse);
      expect(Glob('*_notes.md').matches('meeting_notes.md'), isTrue);
      expect(Glob('*_notes.md').matches('important_notes.md'), isTrue);
    });

    test('glob package should handle directory patterns', () {
      expect(Glob('notes/**').matches('notes/test.md'), isTrue);
      expect(Glob('notes/**').matches('notes/subdir/test.md'), isTrue);
      expect(Glob('notes/**').matches('docs/test.md'), isFalse);
      expect(Glob('notes/**').matches('notes'), isFalse);
    });

    test('globInclude should match patterns correctly', () {
      final filter = EntryFilter();

      expect(filter.globInclude({'*.txt'}, 'secret.txt'), isTrue);
      expect(filter.globInclude({'*.txt'}, 'secret.md'), isFalse);
      expect(filter.globInclude({'*_notes.md'}, 'meeting_notes.md'), isTrue);
      expect(filter.globInclude({'*_notes.md'}, 'important_notes.md'), isTrue);
      expect(filter.globInclude({'notes/**'}, 'notes/test.md'), isTrue);
      expect(filter.globInclude({'notes/**'}, 'docs/test.md'), isFalse);
      expect(
        filter.globInclude({'excluded_dir/**'}, 'excluded_dir/excluded.md'),
        isTrue,
      );
      expect(
        filter.globInclude({'excluded_dir/**'}, 'other_dir/file.md'),
        isFalse,
      );
    });

    test('isExcluded should work with various patterns', () {
      final filter = EntryFilter();

      expect(filter.isExcluded('secret.txt'), isTrue);
      expect(filter.isExcluded('excluded_file.md'), isTrue);
      expect(filter.isExcluded('meeting_notes.md'), isTrue);
      expect(filter.isExcluded('notes/meeting_notes.md'), isTrue);
      expect(filter.isExcluded('excluded_dir/excluded.md'), isTrue);
      expect(filter.isExcluded('normal.md'), isFalse);
    });

    test('isIncluded should work with include patterns', () {
      final filter = EntryFilter();

      expect(filter.isIncluded('notes/important_notes.md'), isTrue);
      expect(filter.isIncluded('notes/meeting_notes.md'), isFalse);
      expect(filter.isIncluded('normal.md'), isFalse);
    });

    test('filter should respect exclude and include rules', () {
      final filter = EntryFilter();

      final entries = [
        p.join(sourcePath, 'index.md'),
        p.join(sourcePath, 'secret.txt'),
        p.join(sourcePath, 'excluded_file.md'),
        p.join(sourcePath, 'notes', 'meeting_notes.md'),
        p.join(sourcePath, 'notes', 'important_notes.md'),
        p.join(sourcePath, 'excluded_dir', 'excluded.md'),
      ];

      final filtered = filter.filter(entries);

      print('Input entries:');
      for (var entry in entries) {
        print('  - $entry');
      }
      print('Filtered entries:');
      for (var entry in filtered) {
        print('  - $entry');
      }

      // Should include index.md and important_notes.md
      expect(filtered.length, equals(2));
      expect(filtered.any((e) => e.endsWith('index.md')), isTrue);
      expect(
        filtered.any((e) => e.endsWith('notes/important_notes.md')),
        isTrue,
      );
    });
  });
}
