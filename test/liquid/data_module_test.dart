import 'dart:convert';
import 'dart:io';

import 'package:gengen/liquid/modules/data_module.dart';
import 'package:test/test.dart';

Future<HttpServer> _startServer() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    if (request.uri.path == '/json') {
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'name': 'GenGen'}));
      await request.response.close();
      return;
    }
    if (request.uri.path == '/html') {
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.html;
      request.response.write(
        '<html><head><meta property="og:title" content="GenGen" /></head></html>',
      );
      await request.response.close();
      return;
    }
    request.response.statusCode = 404;
    await request.response.close();
  });
  return server;
}

void main() {
  group('DataModule filters', () {
    late DataModule module;

    setUp(() {
      module = DataModule()..register();
    });

    test('get_json fetches and decodes JSON', () async {
      final server = await _startServer();
      final url = 'http://${server.address.host}:${server.port}/json';

      final filter = module.filters['get_json'] as dynamic;
      final result = await filter(url, [], <String, dynamic>{});

      expect(result, isA<Map<String, dynamic>>());
      expect(result['name'], 'GenGen');

      await server.close(force: true);
    });

    test('social_graph extracts og tags', () async {
      final server = await _startServer();
      final url = 'http://${server.address.host}:${server.port}/html';

      final filter = module.filters['social_graph'] as dynamic;
      final result = await filter(url, [], <String, dynamic>{});

      expect(result['title'], 'GenGen');

      await server.close(force: true);
    });

    test('markdownify converts markdown to HTML', () {
      final filter = module.filters['markdownify'] as dynamic;
      final result = filter('# Hello', [], <String, dynamic>{});
      expect(result, contains('<h1'));
    });
  });
}
