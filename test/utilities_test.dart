import 'package:test/test.dart';
import 'package:gengen/utilities.dart';

void main() {
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