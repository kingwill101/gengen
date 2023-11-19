import 'package:gengen/models.dart';
import 'package:test/test.dart';

void main() {
  group('Permalink Generation Tests', () {
    late Post post;

    setUp(() {
      Map<String, dynamic> frontMatter = {
        'author': 'John Doe',
        'title': 'Test Post',
        'date': '2023-01-15',
        'tags': ['dart', 'programming']
      };

      post = Post.fromYaml(frontMatter, 'source', 'content');
    });

    test('Date Permalink Structure', () {
      String permalink = post.buildPermalink(PermalinkStructure.date);
      expect(permalink, '/dart/programming/2023/01/15/test-post.html');
    });

    test('Pretty Permalink Structure', () {
      String permalink = post.buildPermalink(PermalinkStructure.pretty);
      expect(permalink, '/dart/programming/2023/01/15/test-post/');
    });

    test('Ordinal Permalink Structure', () {
      String permalink = post.buildPermalink(PermalinkStructure.ordinal);
      expect(permalink, '/dart/programming/2023/015/test-post.html');
    });

    test('Weekdate Permalink Structure', () {
      String permalink = post.buildPermalink(PermalinkStructure.weekdate);
      expect(permalink, '/dart/programming/2023/W02/Sun/test-post.html');
    });

    test('None Permalink Structure', () {
      String permalink = post.buildPermalink(PermalinkStructure.none);
      expect(permalink, '/dart/programming/test-post.html');
    });
  });
}
