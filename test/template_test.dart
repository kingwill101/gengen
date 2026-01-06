import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:gengen/configuration.dart';
import 'package:gengen/di.dart';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/liquid/template.dart';
import 'package:gengen/md/md.dart';
import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart';
import 'package:liquify/liquify.dart' as liquid;
import 'package:test/test.dart';

Future<HttpServer> _startServer() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    if (request.uri.path == '/json') {
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'id': 1}));
      await request.response.close();
      return;
    }
    request.response.statusCode = 404;
    await request.response.close();
  });
  return server;
}

void main() {
  setUpAll(() {
    if (!getIt.isRegistered<FileSystem>()) {
      getIt.registerSingleton<FileSystem>(const LocalFileSystem());
    }
    gengen_fs.fs = const LocalFileSystem();
    Configuration.resetConfig();
    Site.resetInstance();
  });

  group("Templates", () {
    test('template include tag', () async {
      final root = liquid.MapRoot({
        'header.html': 'header',
        'bottom/footer.html': 'footer',
      });

      var template = GenGenTempate.r(
        "{% include 'header.html' %}",
        contentRoot: root,
      );
      var result = await template.render();
      expect(result, "header");
    });

    // test('template include without quotes', () {
    //   final root = liquid.MapRoot({
    //     'bottom/footer.html': 'footer',
    //   });

    //   final template = GenGenTempate.r("{% include bottom/footer.html %}",
    //       contentRoot: root);
    //   final result = template.render();
    //   expect(result, "footer");
    // });

    test('template render tag', () async {
      final root = liquid.MapRoot({
        'header.html': 'header',
        'header_with.html': 'header {{ age }}',
      });

      var tests = [
        (
          '''{% assign my_age = 1 %} {%- render 'header_with.html', age: my_age -%}''',
          'header 1',
        ),
      ];
      for (var t in tests) {
        var result = await GenGenTempate.r(t.$1, contentRoot: root).render();
        expect(result, t.$2);
      }
    });
  });

  group("filters", () {
    test('append', () async {
      var result = await GenGenTempate.r(
        '{{"1+" | append: "1" }}',
        contentRoot: liquid.MapRoot({}),
      ).render();
      expect(result, '1+1');
    });

    test('date', () async {
      final root = liquid.MapRoot({});
      var test = '''{{ site.time | date: 'y' }}''';
      var result = await GenGenTempate.r(
        test,
        contentRoot: root,
        data: {
          'site': {'time': DateTime.now()},
        },
      ).render();
      expect(result, DateTime.now().year.toString());
    });

    test("getJson", () async {
      final server = await _startServer();
      final url = 'http://${server.address.host}:${server.port}/json';
      var json =
          '''
      {%- assign product_data = '$url' | get_json -%}
      {{- product_data.id -}}
      ''';

      var result = await GenGenTempate.r(
        json,
        contentRoot: liquid.MapRoot({}),
      ).render();
      expect(result, '1');
      await server.close(force: true);
    });
  });

  group('markdown', () {
    test('correct shortcode', () {
      var result = renderMd(
        "[ shortcode 'partials/media/twitter' url='https://twitter.com/duttyberryshow/status/1616150633077145615' width='560' height='315' ]",
      );
      assert(result.isNotEmpty);
    });
  });

  test('contains Liquid', () {
    assert(containsLiquid('{{ site.time | date: "%Y-%m-%d" }}'));
  });
}
