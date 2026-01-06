import 'package:gengen/data/social_graph.dart';
import 'package:html/parser.dart' as parser;
import 'package:test/test.dart';

void main() {
  test('extractSocialGraphTags collects og meta tags', () {
    final document = parser.parse('''
<html><head>
<meta property="og:title" content="GenGen" />
<meta property="og:image" content="/img.png" />
<meta name="description" content="ignore" />
</head></html>
''');

    final tags = extractSocialGraphTags(document);

    expect(tags['title'], 'GenGen');
    expect(tags['image'], '/img.png');
    expect(tags.containsKey('description'), isFalse);
  });
}
