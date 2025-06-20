import 'package:file/memory.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:gengen/utilities.dart';

void main() {
  late MemoryFileSystem memoryFileSystem;
  final String realProjectRoot = p.current;

  setUp(() {
    memoryFileSystem = MemoryFileSystem();
    gengen_fs.fs = memoryFileSystem;
    memoryFileSystem.currentDirectory =
        memoryFileSystem.directory(realProjectRoot)..createSync(recursive: true);
  });

  group('Utilities Tests', () {
    // Tests for slugify function
    group('slugify', () {
      test('should convert spaces to hyphens', () {
        expect(slugify('hello world'), 'hello-world');
      });

      test('should remove special characters', () {
        expect(slugify('hello!@#\$%^&*()_+-=[]{}\\|;:\'",.<>/?`~ world'),
            'hello-world');
      });

      test('should handle multiple spaces and hyphens', () {
        expect(slugify('hello   world'), 'hello-world');
        expect(slugify('hello---world'), 'hello-world');
      });

      test('should remove leading/trailing hyphens', () {
        expect(slugify('-hello-world-'), 'hello-world');
      });

      test('should convert to lowercase', () {
        expect(slugify('Hello World'), 'hello-world');
      });
    });

    // Tests for normalize function
    group('normalize', () {
      test('should be an alias for slugify', () {
        expect(normalize('Hello World'), slugify('Hello World'));
      });
    });

    group('getFrontMatter', () {
      test('should parse valid YAML front matter', () {
        final frontMatter = getFrontMatter('''
title: My Post
tags: [dart, gengen]
''');
        expect(frontMatter['title'], 'My Post');
        expect(frontMatter['tags'], ['dart', 'gengen']);
      });

      test('should return empty map for empty front matter', () {
        final frontMatter = getFrontMatter('');
        expect(frontMatter, isEmpty);
      });

      test('should return empty map for invalid YAML', () {
        final frontMatter = getFrontMatter('title: My Post\n- tag');
        expect(frontMatter, isEmpty);
      });
    });

    group('hasYamlHeader', () {
      test('should return true for file with YAML header', () {
        final filePath = p.join(realProjectRoot, 'file_with_header.md');
        memoryFileSystem.file(filePath).writeAsStringSync('''
---
title: I have a header
---
Content
''');
        expect(hasYamlHeader(filePath), isTrue);
      });

      test('should return false for file without YAML header', () {
        final filePath = p.join(realProjectRoot, 'file_without_header.md');
        memoryFileSystem
            .file(filePath)
            .writeAsStringSync('Just content, no header.');
        expect(hasYamlHeader(filePath), isFalse);
      });
    });

    group('isBinaryFile', () {
      test('should return true for a file containing null byte', () {
        final filePath = p.join(realProjectRoot, 'binary.dat');
        memoryFileSystem.file(filePath).writeAsBytesSync([0x48, 0x65, 0x00, 0x6F]); // He\0o
        expect(isBinaryFile(filePath), isTrue);
      });
      test('should return false for a text file', () {
        final filePath = p.join(realProjectRoot, 'text.txt');
        memoryFileSystem.file(filePath).writeAsStringSync('This is a text file.');
        expect(isBinaryFile(filePath), isFalse);
      });
    });

    // Tests for parseDate function
    group('parseDate', () {
      test('should parse date with default format', () {
        final date = parseDate('2024-01-01 12:30:00');
        expect(date.year, 2024);
        expect(date.month, 1);
        expect(date.day, 1);
      });

      test('should parse date with custom format', () {
        final date = parseDate('01/01/2024', format: 'MM/dd/yyyy');
        expect(date.year, 2024);
        expect(date.month, 1);
        expect(date.day, 1);
      });

      test('should fall back to DateTime.parse', () {
        final date = parseDate('2024-01-01T12:30:00Z');
        expect(date.year, 2024);
        expect(date.isUtc, isTrue);
      });

      test('should return current date for invalid format', () {
        final now = DateTime.now();
        final date = parseDate('invalid date');
        // Check if the parsed date is very close to the current time
        expect(date.difference(now).inSeconds, lessThan(1));
      });
    });
  });
} 