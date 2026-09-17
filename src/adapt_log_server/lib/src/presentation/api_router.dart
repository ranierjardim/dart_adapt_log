import 'dart:async';
import 'dart:convert';

import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_remote_protocol/adapt_log_remote_protocol.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../application/ingest_logs.dart';
import '../application/log_stream.dart';
import '../domain/log_query.dart';
import '../domain/log_repository.dart';
import 'panel_page.dart';

/// Resolve a chave de API de uma requisição para o nome do projeto.
class ApiKeyAuthenticator {
  final Map<String, String> _projectsByKey;

  ApiKeyAuthenticator(Map<String, String> projectsByKey)
      : _projectsByKey = Map.unmodifiable(projectsByKey);

  /// Projeto da chave, ou `null` se a chave for desconhecida.
  String? projectFor(String key) => _projectsByKey[key];

  /// Extrai a chave do cabeçalho `Authorization: Bearer` ou do parâmetro
  /// `?key=` (para o WebSocket do painel).
  static String? keyOf(Request request) {
    final header = request.headers[AdaptLogProtocol.authorizationHeader];
    if (header != null && header.toLowerCase().startsWith('bearer ')) {
      return header.substring(7).trim();
    }
    return request.url.queryParameters[AdaptLogProtocol.apiKeyQueryParameter];
  }
}

/// Rotas HTTP e WebSocket do servidor.
class ApiRouter {
  static const int maxBodyBytes = 5 * 1024 * 1024;
  static const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};
  static const _corsHeaders = {
    'access-control-allow-origin': '*',
    'access-control-allow-headers': 'authorization, content-type, ${AdaptLogProtocol.versionHeader}',
    'access-control-allow-methods': 'GET, POST, OPTIONS',
  };

  final ApiKeyAuthenticator authenticator;
  final IngestLogs ingest;
  final LogRepository repository;
  final LogStream stream;

  ApiRouter({
    required this.authenticator,
    required this.ingest,
    required this.repository,
    required this.stream,
  });

  Handler get handler {
    final router = Router()
      ..get(AdaptLogProtocol.healthPath, _health)
      ..get('/', _panel)
      ..options('/<path|.*>', (Request request) => Response.ok('', headers: _corsHeaders))
      ..post(AdaptLogProtocol.logsPath, _authenticated(_postLogs))
      ..get(AdaptLogProtocol.logsPath, _authenticated(_getLogs))
      ..get('${AdaptLogProtocol.logsPath}/<id>', (Request request, String id) {
        return _authenticated((request) => _getLog(request, id))(request);
      })
      ..get('${AdaptLogProtocol.logsPath}/<id>/screenshot', (Request request, String id) {
        return _authenticated((request) => _getScreenshot(request, id))(request);
      })
      ..get(AdaptLogProtocol.sessionsPath, _authenticated(_getSessions))
      ..get(AdaptLogProtocol.streamPath, _authenticated(_stream));
    return const Pipeline().addMiddleware(_cors()).addHandler(router.call);
  }

  Middleware _cors() {
    return (inner) => (request) async {
          final response = await inner(request);
          return response.change(headers: _corsHeaders);
        };
  }

  /// Envolve um handler exigindo chave válida; o projeto vai no contexto.
  Handler _authenticated(Handler inner) {
    return (Request request) {
      final key = ApiKeyAuthenticator.keyOf(request);
      if (key == null || key.isEmpty) {
        return _error(401, 'informe a chave em "Authorization: Bearer <chave>"');
      }
      final project = authenticator.projectFor(key);
      if (project == null) return _error(403, 'chave desconhecida');
      return inner(request.change(context: {'adapt_log.project': project}));
    };
  }

  static String _projectOf(Request request) => request.context['adapt_log.project'] as String;

  Response _health(Request request) {
    return _json({'status': 'ok', 'protocolVersion': AdaptLogProtocol.version});
  }

  Response _panel(Request request) {
    return Response.ok(panelHtml, headers: {'content-type': 'text/html; charset=utf-8'});
  }

  Future<Response> _postLogs(Request request) async {
    final length = request.contentLength;
    if (length != null && length > maxBodyBytes) return _error(413, 'lote acima de $maxBodyBytes bytes');
    final LogBatch batch;
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) throw const FormatException('corpo precisa ser um objeto JSON');
      batch = LogBatch.fromJson(json);
    } on FormatException catch (e) {
      return _error(400, 'lote inválido: ${e.message}');
    } on TypeError catch (e) {
      return _error(400, 'lote inválido: $e');
    }
    final result = await ingest(project: _projectOf(request), batch: batch);
    return _json(result.toJson(), status: 202);
  }

  Future<Response> _getLogs(Request request) async {
    final params = request.url.queryParameters;
    final levelName = params['level'];
    AdaptLogLevel? level;
    if (levelName != null && levelName.isNotEmpty) {
      level = AdaptLogLevel.values.asNameMap()[levelName];
      if (level == null) return _error(400, 'level desconhecido: $levelName');
    }
    final query = LogQuery(
      project: _projectOf(request),
      level: level,
      sessionId: _nonEmpty(params['session']),
      search: _nonEmpty(params['search']),
      beforeSeq: int.tryParse(params['before'] ?? ''),
      limit: int.tryParse(params['limit'] ?? '') ?? LogQuery.defaultLimit,
    );
    final records = await repository.query(query);
    return _json({
      'entries': [for (final record in records) record.toJson()],
      'nextBefore': records.isEmpty ? null : records.last.seq,
    });
  }

  Future<Response> _getLog(Request request, String id) async {
    final record = await repository.findByEntryId(_projectOf(request), id);
    if (record == null) return _error(404, 'entry não encontrada');
    return _json(record.toJson());
  }

  Future<Response> _getScreenshot(Request request, String id) async {
    final screenshot = await repository.findScreenshot(_projectOf(request), id);
    if (screenshot == null) return _error(404, 'screenshot não encontrada');
    return Response.ok(
      screenshot.bytes,
      headers: {'content-type': screenshot.contentType, 'cache-control': 'private, max-age=3600'},
    );
  }

  Future<Response> _getSessions(Request request) async {
    final limit = int.tryParse(request.url.queryParameters['limit'] ?? '') ?? 100;
    final sessions = await repository.sessions(_projectOf(request), limit: limit);
    return _json({'sessions': [for (final session in sessions) session.toJson()]});
  }

  FutureOr<Response> _stream(Request request) {
    final project = _projectOf(request);
    return webSocketHandler((WebSocketChannel channel) {
      channel.sink.add(jsonEncode({'type': 'hello', 'project': project, 'protocolVersion': AdaptLogProtocol.version}));
      final subscription = stream.forProject(project).listen(
        (event) => channel.sink.add(jsonEncode(event.toJson())),
        onDone: () => channel.sink.close(),
      );
      channel.stream.listen(
        (_) {},
        onDone: () => subscription.cancel(),
        onError: (_) => subscription.cancel(),
        cancelOnError: true,
      );
    })(request);
  }

  static String? _nonEmpty(String? value) => value == null || value.isEmpty ? null : value;

  static Response _json(Object body, {int status = 200}) {
    return Response(status, body: jsonEncode(body), headers: _jsonHeaders);
  }

  static Response _error(int status, String message) {
    return Response(status, body: jsonEncode({'error': message}), headers: _jsonHeaders);
  }
}
