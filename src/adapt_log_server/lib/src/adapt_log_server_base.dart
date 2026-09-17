import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;

import 'application/ingest_logs.dart';
import 'application/log_stream.dart';
import 'domain/log_repository.dart';
import 'infrastructure/sqlite_log_repository.dart';
import 'presentation/api_router.dart';

/// Servidor que recebe os lotes do adapt_log_real_time_remote_log_output_adapter,
/// persiste em SQLite e serve a API e o painel web.
///
/// ```dart
/// final server = AdaptLogServer(
///   port: 8080,
///   dbPath: '/var/data/logs.sqlite',
///   apiKeys: {'chave-do-app': 'meu-app'},
/// );
/// await server.start();
/// ```
///
/// Rotas: `GET /` painel, `GET /health`, `POST /v1/logs`, `GET /v1/logs`,
/// `GET /v1/logs/<id>`, `GET /v1/sessions`, `WS /v1/stream`.
///
/// CLOSED SOURCE — disponível via assinatura.
class AdaptLogServer {
  final int port;
  final Object address;
  final String dbPath;

  /// Chave de API → nome do projeto. Cada chave enxerga só o seu projeto.
  final Map<String, String> apiKeys;

  /// Repositório alternativo; se informado, [dbPath] é ignorado.
  final LogRepository? repository;

  HttpServer? _httpServer;
  LogRepository? _repository;
  LogStream? _stream;

  AdaptLogServer({
    this.port = 8080,
    this.address = 'localhost',
    required this.dbPath,
    required this.apiKeys,
    this.repository,
  }) : assert(apiKeys.isNotEmpty, 'informe ao menos uma chave de API');

  /// Porta efetivamente em uso; útil com `port: 0`.
  int? get boundPort => _httpServer?.port;

  Uri? get url {
    final server = _httpServer;
    if (server == null) return null;
    final host = server.address.isLoopback ? 'localhost' : server.address.host;
    return Uri(scheme: 'http', host: host, port: server.port);
  }

  bool get isRunning => _httpServer != null;

  Future<void> start() async {
    if (_httpServer != null) return;
    final repository = _repository = this.repository ?? SqliteLogRepository.open(dbPath);
    final stream = _stream = LogStream();
    final router = ApiRouter(
      authenticator: ApiKeyAuthenticator(apiKeys),
      ingest: IngestLogs(repository: repository, stream: stream),
      repository: repository,
      stream: stream,
    );
    _httpServer = await shelf_io.serve(router.handler, address, port);
  }

  Future<void> stop() async {
    final server = _httpServer;
    _httpServer = null;
    await server?.close(force: true);
    await _stream?.close();
    _stream = null;
    if (repository == null) await _repository?.close();
    _repository = null;
  }
}
