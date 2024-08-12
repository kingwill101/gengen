
import 'package:gengen/fs.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/site.dart';
import 'package:gengen/web_socket.dart';
import 'package:path/path.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart'
    show WebSocketChannel;

Future<void> route() async {
  log.fine("About to serve content");
  var handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(router);

  final server = await shelf_io.serve(handler, 'localhost', 8080);
  log.info('server: Serving at http://${server.address.host}:${server.port}');
}

Handler get router {
  final router = Router();

  router.get('/debug/ws', (Request request) {
    var handler = webSocketHandler(
      (WebSocketChannel webSocket) {
        log.info("watcher: reloading");
        Site.instance.fileChangeStream.listen((event) {
          webSocket.sink.add('reload');
        });
      },
    );

    return handler(request);
  });
  router.get('/<file|.*>', (Request request, String file) {
    var filePath = '${Site.instance.destination.path}/$file';
    final stat = FileStat.statSync(filePath);

    if (stat.type == FileSystemEntityType.notFound) {
      return Response.notFound('File not found');
    }

    if (stat.type == FileSystemEntityType.directory) {
      File index = fs.file(join(filePath, "index.html"));
      if (!index.existsSync()) {
        return Response.notFound('Nothing to be seen here');
      }

      filePath = index.path;
    }

    final fileEntity = fs.file(filePath);

    final noCacheHeaders = {
      "Cache-Control": "no-store, max-age=0",
      "Pragma": "no-cache",
      "Expires": "0"
    };

    if (filePath.endsWith("html")) {
      final websocketUri =
          request.requestedUri.replace(scheme: 'ws', path: "/debug/ws");
      final body = fileEntity.readAsStringSync().replaceFirst(
            '</body>',
            '${webSocketInjection(websocketUri)}</body>',
          );

      return Response(200, body: body, headers: {
        "content-type": "text/html",
        ...noCacheHeaders,
      });
    } else {

      return createStaticHandler(
        Site.instance.destination.path,
        serveFilesOutsidePath: true,

      )(request);
    }
  });

  return router.call;
}
