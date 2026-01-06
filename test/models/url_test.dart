import 'package:gengen/models/url.dart';
import 'package:test/test.dart';

void main() {
  test('generates and sanitizes URLs with placeholders', () {
    final url = URL.create(
      template: '/:collection/:path',
      placeholders: {'collection': 'posts', 'path': 'hello world'},
    );

    expect(url.toString(), '/posts/hello%20world');
  });

  test('uses permalink when provided', () {
    final url = URL.create(
      template: '/:path',
      placeholders: {'path': 'ignored'},
      permalink: '/custom/:path',
    );

    expect(url.toString(), '/custom/ignored');
  });

  test('sanitizes redundant path segments', () {
    final url = URL.create(template: './foo//bar', placeholders: {});

    expect(url.toString(), '/foo/bar');
  });
}
