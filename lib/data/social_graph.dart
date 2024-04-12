import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';

Future<Map<String, String>> fetchPageAndExtractSocialGraph(String url) async {
  try {
    String chromeUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';
    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': chromeUserAgent},
    );
    if (response.statusCode == 200) {
      var document = parser.parse(response.body);
      return extractSocialGraphTags(document);
    } else {

      throw Exception('Failed to load page ${response.body}');
    }
  } catch (e) {
    throw Exception('Error fetching data: $e $url');
  }
}

Map<String, String> extractSocialGraphTags(Document document) {
  Map<String, String> socialGraph = {};
  var metaTags = document.getElementsByTagName('meta');

  for (var tag in metaTags) {
    if (tag.attributes['property'] != null) {
      if (tag.attributes['property']!.startsWith('og:')) {
        socialGraph[tag.attributes['property']!.replaceAll("og:", "")] = tag.attributes['content']!;
      }
    }
  }

  return socialGraph;
}
