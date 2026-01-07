import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gengen/fs.dart';
import 'package:gengen/logging.dart';
import 'package:gengen/site.dart';
import 'package:gengen/web_socket.dart';
import 'package:path/path.dart' as p;
import 'package:routed/routed.dart';

final _reloadWebSocketHandler = _ReloadWebSocketHandler();
Engine? _engine;

Future<void> route() async {
  log.fine('About to serve content');

  if (_engine != null) {
    log.info('server: Serving at http://localhost:8080 (already running)');
    return;
  }

  final engine = Engine();
  final router = Router();

  router.ws('/debug/ws', _reloadWebSocketHandler);
  router.fallback(_serveStatic);

  engine.use(router);
  _engine = engine;

  unawaited(
    engine.serve(host: '127.0.0.1', port: 8080, echo: false).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      log.severe('Failed to start dev server: $error');
      log.fine('$stackTrace');
    }),
  );

  log.info('server: Serving at http://localhost:8080');
}

Future<Response> _serveStatic(EngineContext ctx) async {
  final destinationRoot = p.normalize(p.absolute(site.destination.path));
  final requestPath = ctx.request.uri.path;

  final trimmed = requestPath.isEmpty || requestPath == '/'
      ? ''
      : requestPath.substring(1);
  final candidatePath = p.normalize(p.join(destinationRoot, trimmed));

  if (!_isWithin(destinationRoot, candidatePath)) {
    ctx.status(HttpStatus.forbidden);
    return ctx.string('Forbidden', statusCode: HttpStatus.forbidden);
  }

  var filePath = candidatePath;
  if (await fs.directory(filePath).exists()) {
    filePath = p.join(filePath, 'index.html');
  }

  final file = fs.file(filePath);
  if (!await file.exists()) {
    ctx.status(HttpStatus.notFound);
    return ctx.string('File not found', statusCode: HttpStatus.notFound);
  }

  final extension = p.extension(filePath).toLowerCase();
  if (extension == '.html' || extension == '.htm') {
    final original = await file.readAsString();
    final requested = ctx.request.requestedUri;
    final wsScheme = requested.scheme == 'https' ? 'wss' : 'ws';
    final wsUri = Uri(
      scheme: wsScheme,
      host: requested.host,
      port: requested.port,
      path: '/debug/ws',
    );

    final injection = webSocketInjection(wsUri);
    final body = original.contains('</body>')
        ? original.replaceFirst('</body>', '$injection</body>')
        : '$original$injection';

    _applyNoCacheHeaders(ctx);
    return ctx.data(
      'text/html; charset=utf-8',
      utf8.encode(body),
      statusCode: HttpStatus.ok,
    );
  }

  return await ctx.file(filePath);
}

bool _isWithin(String root, String path) {
  if (root == path) {
    return true;
  }
  return p.isWithin(root, path);
}

void _applyNoCacheHeaders(EngineContext ctx) {
  ctx.setHeader('Cache-Control', 'no-store, max-age=0');
  ctx.setHeader('Pragma', 'no-cache');
  ctx.setHeader('Expires', '0');
}

class _ReloadWebSocketHandler extends WebSocketHandler {
  final Map<WebSocket, StreamSubscription<String>> _subscriptions = {};

  @override
  Future<void> onOpen(WebSocketContext context) async {
    final subscription = site.fileChangeStream.listen((_) {
      context.send('reload');
    });
    _subscriptions[context.webSocket] = subscription;
  }

  @override
  Future<void> onMessage(WebSocketContext context, dynamic message) async {}

  @override
  Future<void> onClose(WebSocketContext context) async {
    await _closeSubscription(context.webSocket);
  }

  @override
  Future<void> onError(WebSocketContext context, dynamic error) async {
    log.warning('WebSocket error: $error');
    await _closeSubscription(context.webSocket);
  }

  Future<void> _closeSubscription(WebSocket socket) async {
    final subscription = _subscriptions.remove(socket);
    await subscription?.cancel();
  }
}
